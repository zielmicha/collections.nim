import macros, tables
import collections/macrotool

var syntheticFields {.compiletime.} = initTable[string, seq[NimNode]]()

macro makeNestedAccessors*(innerType: typed, outerType: typed, accessor: untyped, sepVar: bool=false): stmt =
  result = newNimNode(nnkStmtList)

  let ty = innerType.getType[1].getType
  if ty.kind != nnkObjectTy:
    return

  let xSepVar = sepVar.repr == "true"

  #echo "nested accessor for ", outerType.treeRepr, "\nand: ", innerType.treeRepr
  #echo "EXPANDED: ", ty.treeRepr
  let fields = ty[2]
  var allFields: seq[NimNode] = @[]

  let outerTypeName = outerType.repr
  if outerTypeName notin syntheticFields:
    syntheticFields[outerTypeName] = @[]

  for field in syntheticFields.getOrDefault(innerType.repr):
    allFields.add(field)

  for field in fields:
    allFields.add(field)
    syntheticFields[outerTypeName].add(field)

  for field in allFields:
    #echo "consider field ", innerType.repr, ".", field.repr
    let name = $field.symbol
    let fieldTy = field.getTypeInst

    let nameAssignNode = newIdentNode(name & "=")
    let nameNode = newIdentNode(name)

    var varRetType: NimNode
    varRetType = symToExpr(fieldTy)
    if varRetType == nil:
      varRetType = newIdentNode("auto")
    else:
      varRetType = newNimNode(nnkVarTy).add(varRetType)
    # TODO: visibility

    # TODO: not ideal, but it's not always possible to insert getType into AST
    # TOOD: `var auto` should work, but doesn't
    if xSepVar:
      result.add quote do:
        proc `nameNode`*(a: `outerType`): auto =
          return a.`accessor`.`nameNode`

        proc `nameNode`*(a: var `outerType`): `varRetType` =
          return a.`accessor`.`nameNode`

        proc `nameAssignNode`*(a: var `outerType`, val: auto) =
          a.`accessor`.`nameNode` = val
    else:
      result.add quote do:
        proc `nameNode`*(a: `outerType`): `varRetType` =
          return a.`accessor`.`nameNode`

        proc `nameAssignNode`*(a: `outerType`, val: auto) =
          a.`accessor`.`nameNode` = val
