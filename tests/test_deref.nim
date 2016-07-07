import macros

type
  B = object of RootObj
    field1: int

type
  A[T] = object
    inner: T

macro `.`*(obj: A, v): untyped =
  newDotExpr(newDotExpr(obj, newIdentNode("inner")), newIdentNode(v.strVal))

proc t1*() =
  var f: A[B]
  let field1 = 777 # <- if you comment this, the code works
  echo f.field1

t1()
