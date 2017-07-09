import collections/weakref

type
  Foo = ref object
    v: int

proc hello(): WeakRef[Foo] =
  var foo = newWeakRefable(Foo())
  return foo.weakRef

let weak = hello()
GC_fullCollect()
assert(not weak.isAlive())

var foo1 = newWeakRefable(Foo())
GC_fullCollect()
var foo2 = foo1.weakRef.lock
assert foo1 == foo2
