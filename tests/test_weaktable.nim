import collections/weaktable, collections/weakref

type
  FooObj = object
    v: int

  Foo = WeakRefable[FooObj]

var t: WeakValueTable[int, FooObj]
newWeakValueTable(t)

proc `$`*(f: ref FooObj): string =
  return "Foo " & ($f.v)

proc `$`*(f: Foo): string =
  return $(f[])

var freeCount = 0

proc freeThing(a: ref FooObj) {.procvar, cdecl.} =
  freeCount += 1

proc addKey(i: int) =
  let v = (ref FooObj)(v: i)
  discard t.addKey(i, v, freeThing)

addKey(10)
GC_fullCollect()
assert t.len == 0

addKey(1)
let v2 = t.addKey(2, (ref FooObj)(v: 2))
assert t.len in {1, 2}
discard $t
GC_fullCollect()
assert t.len == 1
discard $t
assert freeCount == 2
