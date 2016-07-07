import collections/gcptr
import collections/iface

when isMainModule:
  defiface Duck:
    quack(foo: string, bar: int): int

  type DuckImpl = object of RootObj
    bar1: int

  proc quack(d: gcptr[DuckImpl], foo: string, bar: int): int =
    assert bar == 13 and foo == "hello"
    assert d.bar1 == 67
    5

  let myDuck = new(DuckImpl)
  myDuck.bar1 = 66
  let myDuckGc: gcptr[DuckImpl] = myDuck
  myDuckGc.bar1 = 67
  let iduck = myDuck.asIDuck

  assert iduck.quack("hello", 13) == 5
