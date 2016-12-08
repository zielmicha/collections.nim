import collections/iface, future, typetraits

when isMainModule:
  type Duck[T] = distinct Interface

  interfaceMethods Duck[T]:
    quack(foo: string, bar: int): int
    bar(): T

  type DuckImpl = ref object of RootObj

  proc quack(d: DuckImpl, foo: string, bar: int): int = 5
  proc bar(d: DuckImpl): float = 5.0

  let duckImpl = new(DuckImpl)
  let duck: Duck[float] = asDuck(duckImpl, float)
  assert duck.quack("1", 2) == 5
  assert duck.bar() == 5.0

  let inlineDuckImpl = DuckInlineImpl[float](
    quack: (proc (foo: string, bar: int): int = 5),
    bar: (() => 6.0)
  )
  let inlineDuck: Duck[float] = asDuck(inlineDuckImpl, float)
  assert inlineDuck.bar() == 6.0
