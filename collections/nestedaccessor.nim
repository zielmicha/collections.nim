import macros

macro makeNestedAccessors*(innerType: typed, outerType: typed): stmt =
  result = newNimNode(nnkStmtList)

  let ty = innerType.getType[1].getType
  if ty.kind != nnkObjectTy:
    return

  #echo "nested accessor for ", outerType.treeRepr, "\nand: ", innerType.treeRepr
  #echo "EXPANDED: ", ty.treeRepr
  let fields = ty[2]
  for field in fields:
    let name = $field.symbol
    let fieldTy = field.getTypeInst

    let nameAssignNode = newIdentNode(name & "=")
    let nameNode = newIdentNode(name)

    var retType: NimNode
    if fieldTy.kind == nnkSym:
      retType = newNimNode(nnkVarTy).add(fieldTy)
    else:
      retType = newIdentNode("auto")

    result.add quote do:
      # TODO: visibility

      # TODO: check if this whole trickery with `var` is needed
      # TODO: not ideal, but it's not always possible to insert getType into AST
      # TOOD: `var auto` should work, but doesn't
      proc `nameNode`*(a: `outerType`): `retType` =
        return a[].`nameNode`

      proc `nameAssignNode`*(a: `outerType`, val: auto) =
        a[].`nameNode` = val
