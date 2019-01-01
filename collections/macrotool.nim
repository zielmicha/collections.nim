import macros

# Small utilities

proc newTypeInstance*(typ: NimNode, args: seq[NimNode]): NimNode =
  # returns typ[args]
  if args.len == 0:
    return typ
  result = newNimNode(nnkBracketExpr).add(typ)
  for arg in args:
    result.add(arg)

proc flattenNode*(v: NimNode, kind: NimNodeKind): seq[NimNode] {.compiletime.} =
  if v.kind == kind:
    var ret: seq[NimNode] = @[]
    for child in v:
      for node in flattenNode(child, kind):
        ret.add node
    return ret
  else:
    return @[v]

proc publicIdent*(node: NimNode): NimNode =
  return newNimNode(nnkPostfix).add(newIdentNode("*"), node)

proc stripPublic*(node: NimNode): NimNode =
  if node.kind == nnkPostfix:
    return node[1]
  else:
    return node

proc identToString*(node: NimNode): string =
  if node.kind == nnkIdent:
    return $node.ident
  elif node.kind == nnkAccQuoted:
    return $node[0].ident
  else:
    error("expected identifier, found " & $node.kind)

proc symToExpr*(val: NimNode, depth=false): NimNode =
  if val.kind == nnkSym:
    if depth:
      return newIdentNode($val)
    else:
      return val
  elif val.kind in {nnkIntLit}:
    return val
  elif val.kind == nnkBracketExpr: # hacky
    result = newNimNode(nnkBracketExpr)
    for item in val:
      result.add symToExpr(item, true)
  else:
    return nil

proc `[]`*(node: NimNode, s: Slice): seq[NimNode] =
  result = @[]
  for i in s:
    result.add(node[i])

#

proc getFieldNames*(t: NimNode): seq[string] =
  var res = t.getType

  if res.kind == nnkBracketExpr and $res[0] == "typeDesc":
    res = res[1]

  if res.kind == nnkBracketExpr and $res[0] == "ref":
    res = res[1].getType

  if res.kind == nnkSym:
    for item in res.getImpl[2][2]:
      result.add $(stripPublic(item[0]))
  else:
    assert res.kind == nnkObjectTy
    for item in res[2]:
      result.add $item

when isMainModule:
  macro printFieldNames(t: typed): untyped =
    for name in getFieldNames(t):
      echo name

  type
    T1 = object
      a: int
      b: string

  var t1: T1
  printFieldNames(t1)
  printFieldNames(T1)
