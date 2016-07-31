import collections/nestedaccessor

type
  F1 = object
    f1: int

  F0 = object
    f0: int

  F2 = object
    anon: F0
    f2: int
    f3: int

  A = object
    field1: F1
    field2: F2

makeNestedAccessors(F0, F2, anon, sepVar=true)
makeNestedAccessors(F1, A, field1, sepVar=true)
makeNestedAccessors(F2, A, field2, sepVar=true)

var a: A
echo a.f2
a.f2 = 5
echo a.f2
a.f0 = 10
echo a.f0
echo a.field2.f0
echo a.anon.f0
echo a.field2.anon.f0
