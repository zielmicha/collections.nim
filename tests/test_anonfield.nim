import collections/anonfield

type
  Bar = object
    k: int
    p: int

  F = struct((i: int, j: float, Bar))
  F1 = struct((i: int, j: float, Bar))

var f: struct((i: int, j: float, Bar))
f.i = 4
var f1: struct((i: int, j: float, Bar))
f1 = f
