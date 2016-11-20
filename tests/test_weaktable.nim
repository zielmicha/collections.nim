import collections/weaktable, collections/weakref

type
  Foo = ref object of WeakRefable
    v: int

proc `$`*(f: Foo): string = return "Foo " & ($f.v)

var t: WeakValueTable[int, Foo]
newWeakValueTable(t)

proc addKey(i: int) =
  t.addKey(i).v = i

addKey(1)
let v2 = t.addKey(2)
v2.v = 2
assert t.len in {1, 2}
discard $t
GC_fullCollect()
assert t.len == 1
discard $t
