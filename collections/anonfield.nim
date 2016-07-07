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

macro struct*(args): expr {.immediate.} =
  if args.kind != nnkPar:
    error("expected struct((...))")

  let name = generateName(args)
  let nameNode = newIdentNode(name)
  let nameCheckNode = newIdentNode("check_" & name)
  let fields = newNimNode(nnkEmpty)

  let r = quote do:
    when not declared(`nameCheckNode`):
      type `nameNode` {.inject.} = object of RootObj
        discard

      proc `nameCheckNode` (): `nameNode` =
        discard # this exists, because we can't check if type is already defined

    `nameNode`

  let declBody = r[0][0][1]
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

  return `r`
