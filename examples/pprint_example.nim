import collections/pprint

type
  T1 = object
    a: int
    b: int

    case d: bool:
      of true:
        c: string
      of false:
        c1: string

    case e: bool:
      of true:
        discard
      of false:
        discard

let t1 = T1(a: 5, b: 1, d: true, c: "foobar")
echo pprint(t1)

echo pprint(new(T1))

echo pprint(@[t1, t1])
