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
