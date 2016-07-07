import macros

macro maketype(ty): expr =
  return quote do:
    type FooId {.inject.} = object
        a: `ty`

    FooId

var a: maketype(int)
var a1: maketype(int)
var b: maketype(float)
a.a = 5
#b = a
#a1 = a
