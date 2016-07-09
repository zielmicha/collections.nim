import collections/interfaces, collections/exttype

when isMainModule:
  # defiface Duck:
  #   quack(foo: string, bar: int): int
  #   bar(): float
  exttypes:
    type
      Duck = iface((
        quack(foo: string, bar: int): int,
        bar(): float
      ))

      SuperDuck = iface((
        #extends Duck
        superQuack(): void
      ))


  type DuckImpl = ref object of RootObj

  proc quack(d: DuckImpl, foo: string, bar: int): int = 5
  proc bar(d: DuckImpl): float = 5.0

  static:
    echo DuckImpl is Duck
    echo DuckImpl is SuperDuck

  let myDuck = new(DuckImpl)
  let iduck = myDuck.asIDuck
  iduck.repr.echo
  echo iduck.quack("foo", 5)
