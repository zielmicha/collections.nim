import collections/gcptr

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
