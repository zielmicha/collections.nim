import collections/gcptrs

proc foo(): gcptr[int] =
  var i = 15
  return gcaddr(i)

proc fooBad(): ptr int =
  var i = 15
  return addr i

let p = foo()
echo "hello!"
echo "value: ", p[]

let p1 = fooBad()
echo "nope!"
echo "value: ", p1[]

assert(not compiles(gcaddr (5+6)))

var a: gcptr[int] = null
echo a.repr


type Foo = object of RootObj
  foofield: int

specializeGcPtr(Foo)

var a1: gcptr[Foo] = new(Foo)
a1.foofield = 2
