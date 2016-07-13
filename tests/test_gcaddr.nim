import collections/gcptrs, collections/goslice, collections/exttype

exttypes:
  type
    T2 = struct((
      f1: int
    ))

    T1 = struct((
      f1: int,
      f2: int,
      f3: gcptr[T2]
    ))

let a = make(GoSlice[int], 1)
let p = gcaddr a[0]
p[] = 9
echo a[0]
