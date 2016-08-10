import macros

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
