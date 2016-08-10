import collections/misc, collections/gcptrs, collections/goslice, collections/reflect, collections/macrotool
import macros, strutils, typetraits, algorithm, tables

export SomeGcPtr

type
  Interface*[VTABLE] = object
    obj*: SomeGcPtr
    vtable*: VTABLE

var interfaceFields {.compileTime.} = initTable[string, seq[NimNode]]() # module namespace collisions

proc `==`*[T](a: Interface[T], b: Interface[T]): bool =
  return a.vtable == b.vtable and a.obj == b.obj

proc unwrapTo*[T](src: T, dest: pointer) =
  cast[ptr T](dest)[] = src

proc makeInterface*(name: NimNode, body: NimNode): tuple[typedefs: NimNode, others: NimNode] {.compiletime.} =
  echo "generating ", name
  let nameStr = $name.ident
  let iname = newIdentNode("I" & nameStr)
  let vtableName = newIdentNode(nameStr & "VTable")
  let genericBody = newNimNode(nnkStmtList)
  genericBody.add(newNimNode(nnkInfix).add(newIdentNode("is"),
                                           newIdentNode("x"),
                                           newNimNode(nnkRefTy)))
  let vtableBody = quote do:
    type `vtableName`* = ref object
      vtypeId: TypeId # there are problems with using symbols that are already procs

  let vtableInner = vtableBody[0][0][2][0][2]
  #vtableInner.del(0)
  let vtableInitBody = newNimNode(nnkStmtList)
  vtableInitBody.add(newNimNode(nnkLetSection).add(
    newNimNode(nnkIdentDefs).add(newIdentNode("res"), newEmptyNode(),
                                 newCall(bindSym"new", vtableName))))

  let callWrappers = newNimNode(nnkStmtList)
  var allFields: seq[NimNode] = @[]

  proc addField(arg: NimNode) =
      let left = arg[0]
      var funcName: NimNode
      var args: NimNode
      let ret = arg[1][0]

      if left.kind == nnkObjConstr:
        funcName = left[0]
        args = newNimNode(nnkStmtList)
        for i in 1..<left.len:
          args.add(left[i])
      elif left.kind == nnkIdent:
        funcName = left
        args = newNimNode(nnkStmtList)
      elif left.kind == nnkCall and left.len == 1:
        funcName = left[0]
        args = newNimNode(nnkStmtList)
      else:
        error("invalid declaration " & $left.kind)

      funcName = newIdentNode($funcName.identToString)

      # Generate check for concept
      let callArgList = newNimNode(nnkCall)
      callArgList.add funcName
      callArgList.add newIdentNode("x")
      for arg in args:
        if arg.kind != nnkExprColonExpr:
          error("invalid argument ($1 expected nnkExprColonExpr)" % [$arg.kind])
        callArgList.add arg[1]

      genericBody.add(newNimNode(nnkInfix).add(newIdentNode("is"),
                                 callArgList, ret))

      # Generate vtable type
      let vtableArgs = newNimNode(nnkFormalParams).add(ret)
      vtableArgs.add(newNimNode(nnkIdentDefs).add(newIdentNode(!"self"), newIdentNode(!"SomeGcPtr"), newEmptyNode()))
      for arg in args:
        vtableArgs.add(newNimNode(nnkIdentDefs).add(arg[0], arg[1], newEmptyNode()))

      let vtableProcType = newNimNode(nnkProcTy).add(
        vtableArgs,
        newNimNode(nnkPragma).add(newIdentNode("cdecl")))
      vtableInner.add(newNimNode(nnkIdentDefs).add(funcName.copyNimTree, vtableProcType, newEmptyNode()))

      # Generate vtable body
      let vtableFunc = quote do:
        res.`funcName` = proc(self: SomeGcPtr): void {.cdecl.} =
                                mixin funcName
                                funcName(self.unwrap(T))

      let vtableFuncBody = vtableFunc[0][1]

      let vtableFuncFormalParams = vtableFuncBody[3]
      vtableFuncFormalParams[0] = ret.copyNimTree
      for arg in args:
        vtableFuncFormalParams.add(newNimNode(nnkIdentDefs).add(arg[0], arg[1], newEmptyNode()))

      # `mixin` is removed by quote, we need to readd it
      vtableFuncBody[6][0] = newNimNode(nnkMixinStmt).add(funcName)

      let vtableFuncCall = vtableFuncBody[6][1]
      vtableFuncCall[0] = funcName
      for arg in args:
        vtableFuncCall.add(arg[0])

      vtableInitBody.add(vtableFunc)

      # Generate call wrappers
      let wrapper = quote do:
        # TODO: disable discardable
        proc `funcName`*(self: `name`): `ret` {.inline, discardable.} =
          self.vtable.`funcName`(self.obj)

      for arg in args:
        wrapper[0][3].add(newNimNode(nnkIdentDefs).add(arg[0], arg[1], newEmptyNode()))

      for arg in args:
        wrapper[0][6][0].add(arg[0])

      callWrappers.add wrapper

  for orgArg in body:
    var arg = orgArg
    if arg.kind == nnkExprColonExpr:
      # Nim produces different node depending if part of expression or statement
      arg = newNimNode(nnkCall).add(arg[0], newNimNode(nnkStmtList).add(arg[1]))

    if arg.kind == nnkCall:
      allFields.add(arg.copyNimTree)
      addField(arg)
    elif arg.kind == nnkCommand:
      if $(arg[0].ident) == "extends":
        let name = $(arg[1].ident)
        for field in interfaceFields[name]:
          allFields.add(field.copyNimTree)
          addField(field)
      else:
        error("invalid command")
    else:
      error("invalid statement in interface specification: " & $arg.kind)

  proc addFieldFromStr(a: string) =
    let arg = parseStmt(a)[0][0]
    addField(newNimNode(nnkCall).add(arg[0], newNimNode(nnkStmtList).add(arg[1])))

  addFieldFromStr("(unwrapTo(dest: pointer): void)")

  interfaceFields[$(name.ident)] = allFields
  let converterName = newIdentNode("asI" & nameStr)
  vtableBody[0][0][2][0][2] = vtableInner

  result.typedefs = quote do:
    `vtableBody`

    type
      `name`* = Interface[`vtableName`]

  result.others = quote do:
    proc initVtableFor[T](impl: typedesc[T], iface: typedesc[`name`]): `vtableName` =
      `vtableInitBody`
      assert res.vtypeId.int == 0
      res.vtypeId = typeid(impl)
      return res

  result.others.add parseStmt("""
    proc getVtableFor*[T](impl: typedesc[T], t: typedesc[$1]): $2 {.inline.} =
      var vtable {.global.} = initVtableFor(impl, $1)
      return vtable""" % [nameStr, $vtableName.ident]) # FIXME: string parsing

  result.others.add quote do:
    proc typeId*(t: `name`): TypeId =
      if t.vtable == nil:
        return InvalidTypeId

      return t.vtable.vtypeId

    converter `converterName`*[T](a: T): `name` =
      when T is void:
        {.error: "nope".}
      elif T is NullType:
        var res: `name`
        return res
      elif T is gcptr or T is ref or T is ValueType:
        var res: `name`
        res.vtable = getVtableFor(type(a), `name`)
        res.obj = toSomeGcPtr(a)
        return res
      else:
        static:
          error("type not supported")

    specializeGcPtr(`name`)
    specializeGoSlice(`name`)

    `callWrappers`

  # result.repr.echo
  result.others = result.others.copyNimTree
  result.typedefs = result.typedefs.copyNimTree

proc implements*(ty: typedesc, superty: typedesc) =
  static:
    if not (ty is superty):
      error(name(ty) & " doesn't implement " & name(superty))

proc myCmp(x, y: string): int =
  if x < y: result = -1
  elif x > y: result = 1
  else: result = 0

proc generateName(rootNode: NimNode): string {.compiletime.} =
  var args: seq[string] = @[]
  for node in rootNode:
    args.add(node.repr)
  args.sort(myCmp)
  return "interface((" & args.join(", ") & "))"
