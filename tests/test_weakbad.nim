type
  Foo = ref object
    v: int

var bad: Foo

proc resurrect(f: Foo) =
  echo "resurrect"
  bad = f

proc hello() =
  var f: Foo
  new(f, resurrect)

hello()
GC_fastCollect()
