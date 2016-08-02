## Implements struct(()) macro, which can be used to declare objects, potentially with anonymous fields.
import macros, algorithm, strutils, collections/macrotool, collections/goslice

proc myCmp(x, y: string): int =
  if x < y: result = -1
  elif x > y: result = 1
  else: result = 0

proc generateName(rootNode: NimNode): string {.compiletime.} =
  var args: seq[string] = @[]
  for node in rootNode:
    args.add(node.repr)
  args.sort(myCmp)
  return "struct((" & args.join(", ") & "))"

proc makeStruct*(name: NimNode, args: NimNode): tuple[typedefs: NimNode, others: NimNode] {.compiletime.} =
  if args.kind != nnkPar:
    error("expected struct((...))")

  let name = $(name.ident)
  let nameNode = newIdentNode(name)
  let nameCheckNode = newIdentNode("check_" & name)
  let fields = newNimNode(nnkEmpty)

  let typespecs = quote do:
    type `nameNode`* {.inject.} = object of RootObj
      discard

  let declBody = typespecs
  let fieldList = declBody[0][0][2][2]

  let others = quote do:
    discard

  for node in args:
    if node.kind == nnkExprColonExpr:
      var inline: bool
      var fieldName: NimNode
      if node[0].kind == nnkCommand and node[0][0] == newIdentNode("inline"):
        inline = true
        fieldName = node[0][1]
      elif node[0].kind in {nnkIdent, nnkAccQuoted}:
        fieldName = node[0]
      else:
        error("unexpected field name " & ($node[0].kind))

      let fieldType = node[1]

      if inline:
        let inlineHandler = quote do:
          makeNestedAccessors(`fieldType`, `nameNode`, `fieldName`, sepVar=true)
        others.add(inlineHandler)

      fieldList.add(newNimNode(nnkIdentDefs).add(publicIdent(fieldName), fieldType, newNimNode(nnkEmpty)))
    else:
      error("unexpected field " & ($node.kind))

  others.add quote do:
    specializeGcPtr(`nameNode`)
    specializeGoSlice(`nameNode`)

  return (typespecs, others)
