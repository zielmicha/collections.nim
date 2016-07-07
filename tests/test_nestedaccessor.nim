import macros

type
  F1 = object
    f1: int

  F2 = object
    f2: int

  A = object
    field1: F1
    field2: F2

macro `.`*(obj: A, v): untyped =
  newDotExpr(newDotExpr(obj, newIdentNode("field1")), newIdentNode(v.strVal))

proc func1() =
  var a: A
  echo a.f1

func1()
