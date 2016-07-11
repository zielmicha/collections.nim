import collections/interfaces, collections/exttype, collections/gcptrs

when isMainModule:
  exttypes:
    type
      Duck = iface((
        quack(foo: string, bar: int): int
      ))

  let iemptyduck: Duck = null
  echo iemptyduck.repr

  type DuckImpl = object of RootObj
    bar1: int

  proc quack(d: gcptr[DuckImpl], foo: string, bar: int): int =
    assert bar == 13 and foo == "hello"
    assert d.bar1 == 67
    5

  let myDuck = new(DuckImpl)
  myDuck.bar1 = 66
  let myDuckGc = myDuck
  myDuckGc.bar1 = 67
  let iduck = myDuck.asIDuck

  assert iduck.quack("hello", 13) == 5
