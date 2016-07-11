import collections/nestedaccessor

type
  F1 = object
    f1: int

  F2 = object
    f2: int
    f3: int

  A = object
    field1: F1
    field2: F2

proc `[]`(a: ref A): var F2 =
  return a.field2

makeNestedAccessors(F2, ref A)

let a = new(A)
echo a.f2
a.f2 = 5
echo a.f2
