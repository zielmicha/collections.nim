import macros
import collections/interfaces, collections/anonfield, collections/macrotool, collections/gcptrs

proc processType(metaTypeName: string; name, arg: NimNode): tuple[typedefs, others: NimNode] =
  if metaTypeName == "iface":
    return makeInterface(name, arg)
  if metaTypeName == "struct":
    return makeStruct(name, arg)
  else:
    error("unknown meta type name")

macro exttypes*(body: untyped): stmt =
  if body.len != 1 or body[0].kind != nnkTypeSection:
    error("expected exactly one type section")

  let typeSection = newNimNode(nnkTypeSection)
  let mainStmts = newNimNode(nnkStmtList).add(typeSection)

  for def in body[0]:
    if def.kind != nnkTypeDef:
      error("expected only type definitions")
    if def[2].kind == nnkCall:
      var name = def[0]
      if name.kind == nnkPostfix: # TODO: treat public and non public differently
        name = name[1]
      let arg = def[2][1]
      let metaTypeName = $(def[2][0].ident)
      let (typedefs, stmts) = processType(metaTypeName, name, arg)

      for retSection in flattenNode(typedefs, nnkStmtList):
        if retSection.kind != nnkTypeSection:
          error("unexpected item in 'typedefs' returned")

        for retType in retSection:
          if retType.kind != nnkTypeDef:
            error("unexpected item in type section in 'typedefs' returned")
          typeSection.add(retType)

      mainStmts.add(stmts)
    else:
      typeSection.add(def)

  mainStmts.repr.echo

  return mainStmts

exttypes:
  type
    EmptyInterface = iface(())

when isMainModule:
  exttypes:
    type
      B = object
        bar: int

      C = iface((
        getName(lang: string): string
      ))
