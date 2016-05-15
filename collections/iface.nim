import collections/misc
import macros, strutils, typetraits

macro defiface*(name: untyped, body: untyped): stmt {.immediate.} =
  let nameStr = $name.ident
  let iname = newIdentNode("I" & nameStr)
  let vtableName = newIdentNode(nameStr & "VTable")
  let genericBody = newNimNode(nnkStmtList)
  genericBody.add(newNimNode(nnkInfix).add(newIdentNode("is"),
                                           newIdentNode("x"),
                                           newNimNode(nnkRefTy)))
  let vtableBody = quote do:
    type `vtableName`* = ref object
      discard
  let vtableInner = vtableBody[0][0][2][0][2]
  vtableInner.del(0)
  let vtableInitBody = newNimNode(nnkStmtList)
  vtableInitBody.add(newNimNode(nnkLetSection).add(
    newNimNode(nnkIdentDefs).add(newIdentNode("res"), newEmptyNode(),
                                 newCall(bindSym"new", vtableName))))
  let callWrappers = newNimNode(nnkStmtList)

  for arg in body:
    if arg.kind == nnkCall:
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
      else:
        error("invalid declaration")

      funcName = newIdentNode($funcName.ident)

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
      vtableArgs.add(newNimNode(nnkIdentDefs).add(newIdentNode(!"self"), newIdentNode(!"RootRef"), newEmptyNode()))
      for arg in args:
        vtableArgs.add(newNimNode(nnkIdentDefs).add(arg[0], arg[1], newEmptyNode()))

      let vtableProcType = newNimNode(nnkProcTy).add(
        vtableArgs,
        newNimNode(nnkPragma).add(newIdentNode("cdecl")))
      vtableInner.add(newNimNode(nnkIdentDefs).add(funcName.copyNimTree, vtableProcType, newEmptyNode()))

      # Generate vtable body
      let vtableFunc = quote do:
        res.`funcName` = proc(self: RootRef): void {.cdecl.} =
                                mixin funcName
                                funcName(cast[T](self))

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
        proc `funcName`*(self: `iname`): `ret` {.inline.} =
          self.vtable.`funcName`(self.obj)

      for arg in args:
        wrapper[0][3].add(newNimNode(nnkIdentDefs).add(arg[0], arg[1], newEmptyNode()))

      for arg in args:
        wrapper[0][6][0].add(arg[0])

      callWrappers.add wrapper
    elif arg.kind == nnkCommand:
      discard
    else:
      error("invalid statement in interface specification")

  let converterName = newIdentNode("asI" & nameStr)
  vtableInitBody.add(newNimNode(nnkReturnStmt).add(newIdentNode("res")))

  result = quote do:
    type
      `name`* = concept x
        `genericBody`

    `vtableBody`

    type
      `iname`* = object
        obj: RootRef
        vtable: `vtableName`

    proc initVtableFor[T](impl: typedesc[T], iface: typedesc[`iname`]): `vtableName` =
      `vtableInitBody`

    proc getVtableFor*[T](impl: typedesc[T], t: typedesc[`iname`]): `vtableName` {.inline.} =
      var vtable {.global.} = initVtableFor(T, `iname`)
      return vtable

    proc `converterName`*(a: any): `iname` =
      var res: `iname`
      res.vtable = getVtableFor(type(a), `iname`)
      res.obj = cast[RootRef](a)
      return res

    `callWrappers`

  result = result.copyNimTree

proc implements*(ty: typedesc, superty: typedesc) =
  static:
    if not (ty is superty):
      error(name(ty) & " doesn't implement " & name(superty))

