import collections/iface

when isMainModule:
  defiface Duck:
    quack(foo: string, bar: int): int
    bar(): float

  type DuckImpl = ref object

  proc quack(d: DuckImpl, foo: string, bar: int): int = 5
  proc bar(d: DuckImpl): float = 5.0

  defiface SuperDuck:
    #extends Duck
    superQuack(): void

  static:
    echo DuckImpl is Duck
    echo DuckImpl is SuperDuck

  DuckImpl.implements Duck

  let myDuck = new(DuckImpl)
  let iduck = myDuck.asIDuck
  iduck.repr.echo
  echo iduck.quack("foo", 5)
