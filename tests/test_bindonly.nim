import collections/lang

proc main() =
  let hello = "hello"
  let world = "world"
  let helloworld = hello & world

  let myFunc = bindOnlyVars([hello, world], proc(): int = helloworld.len)
  echo myFunc()

main()

proc forceNoClosure[T](p: T): T {.inline.} =
  echo sizeof(p)
  return p

proc foo() =
  let a = 5
  let f = (proc() = discard (proc() = echo a))
  echo sizeof(f)

foo()
