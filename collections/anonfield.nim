## Implements struct(()) macro, which can be used to declare objects, potentially with anonymous fields.
import macros, algorithm, strutils

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

  let r = quote do:
    type `nameNode` {.inject.} = object of RootObj
      discard

  let declBody = r
  let fieldList = declBody[0][0][2][2]

  for node in args:
    if node.kind == nnkExprColonExpr:
      fieldList.add(newNimNode(nnkIdentDefs).add(node[0], node[1], newNimNode(nnkEmpty)))
    elif node.kind == nnkIdent:
      fieldList.add(newNimNode(nnkIdentDefs).add(node, node, newNimNode(nnkEmpty)))
    else:
      error("unexpected field " & ($node.kind))

  # r.treeRepr.echo
  # r.repr.echo

  return (r, newNimNode(nnkStmtList))
