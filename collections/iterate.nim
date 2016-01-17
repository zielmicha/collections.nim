import collections/base
import macros, options, algorithm

macro multifuncIterator*(b): stmt =
  ## Iterator that is closure and inline at the same time, depending on the context.
  ##
  ## Example:
  ## ```
  ## iterator foo(): int {.multifuncIterator.} =
  ##   yield 5
  ## ```
  result = newStmtList()
  # FIXME: if we enable this compiler fails on "var s = result.sons[namePos].sym" in semstmts.nim
  #result.add(b.copy)

  let params = b[3].copy

  params[0] = newNimNode(nnkIteratorTy).add(newNimNode(nnkFormalParams).add(params[0]), newEmptyNode())
  params[0] = newNimNode(nnkPar).add(params[0])

  let procN = newNimNode(nnkProcDef).add(
    b[0].copy,
    newEmptyNode(),
    b[2].copy,
    params,
    newEmptyNode(),
    newEmptyNode(),
    newEmptyNode())

  let body = parseStmt("return iterator(): T {.closure.} = nil")
  body[0][0][3] = newNimNode(nnkFormalParams).add(b[3][0].copy)
  body[0][0][6] = b[6].copy
  procN[6] = body

  result.add(procN.copy)

type
  Iterator*[T] = (iterator(): T)

  # this should be a concept in future, but they are too buggy now
  Iterable*[T] = Iterator[T] | seq[T]

template wrapIterable*(typ): stmt =
  ## Creates closure version of `items` for type that already has `inline` version.
  converter items*[T](s: typ[T]): Iterator[T] =
    return iterator(): T =
      for i in s:
        yield i

iterator items*[T](i: Iterator[T]): T =
  ## Iterate over closure iterator.
  let it: (iterator(): T) = i # workaround for #3174
  while true:
    let v = it()
    if finished(it):
      break
    yield v

proc items*[T](s: Iterator[T]): Iterator[T] =
  return s

staticAssert((iterator(): int) is Iterable[int], "closure iterator is not iterable")

wrapIterable(seq)

staticAssert(seq[int] is Iterable[int], "seq is not iterable")
staticAssert(seq[int] is Iterable, "seq is not iterable (generic)")
staticAssert(not (seq[int] is Iterable[string]), "seq[int] is string iterable!")

proc next*[T](i: Iterator[T]): Option[T] =
  ## Advances the iterator and return next item or `none[T]` if there are no more items.
  let it = (iterator(): T)(i)
  let v = it()
  if finished(it):
    return none(T)
  else:
    return some(v)

iterator flatten*[T](coll: Iterator[seq[T]]): T {.multifuncIterator.} =
  ## Flattens iterator e.g. [[1, 2], [3, 4], [5, 6]] == [1, 2, 3, 4, 5, 6]
  for subcoll in coll:
    for x in subcoll:
      yield x

iterator grouping*[T](it: Iterator[T], n: int, discardLast=false): seq[T] {.multifuncIterator.} =
  ## Partitions the iterator into iterator that returns n-item sequences of consecutive items.
  ## Last sequence may contain less items if `discardLast` is true else they will be discarded.
  var s: seq[T] = @[]
  for item in it:
    s.add item
    if s.len == n:
      yield s
      s = @[]
  if s.len != 0 and not discardLast:
    yield s

iterator map*[T; R](coll: Iterable[T], f: (proc(item: T): R)): R {.multifuncIterator.} =
  for item in coll:
    yield f(item)

iterator flatMap*[T; R](coll: seq[T], f: (proc(item: T): seq[R])): R {.multifuncIterator.} =
  for item in coll:
    let rets = f(item)
    for ret in rets:
      yield ret

iterator range*(start: int, `end`: int, step: int=1): int {.multifuncIterator.} =
  var curr = start
  while curr < `end`:
    yield start
    curr += step

iterator range*(`end`: int): int {.multifuncIterator.} =
  for i in range(0, `end`):
    yield i

iterator zip*[A, B](a: Iterable[A], b: Iterable[B]): tuple[a: A, b: B] {.multifuncIterator.} =
  ## Returns (a[0], b[0]), (a[1], b[1]), ...
  let ait = items(a)
  let bit = items(b)
  while true:
    let va = next(ait)
    let vb = next(bit)
    if va.isNone or vb.isNone:
      break
    yield (va.get, vb.get)

proc unzip*[A, B](i: Iterator[tuple[a: A, b: B]]): tuple[a: seq[A], b: seq[B]] =
  ## Returns (i[0].a, i[1].a, ...), (i[0].b, i[1].b, ...)
  result.a = @[]
  result.b = @[]
  for item in i:
    result.a.add item[0]
    result.b.add item[1]

proc dropWhile*[T](i: Iterable[T], f: proc(t: T): bool): T {.multifuncIterator.} =
  ## Skips longest sequence of elements of this iterator for which f returns true.
  var skipping = true
  for item in i:
    if skipping and not f(item):
      skipping = false
    if not skipping:
      yield item

proc takeWhile*[T](i: Iterable[T], f: proc(t: T): bool): T {.multifuncIterator.} =
  ## Returns longest sequence of elements for which f returns true.
  for item in i:
    if not f(item):
      break
    yield item

proc filter*[T](i: Iterable[T], f: proc(t: T): bool): T {.multifuncIterator.} =
  ## Returns items for which f returns true.
  for item in i:
    if f(item):
      yield item

proc reversed*[T](s: seq[T]): seq[T] =
  result = s
  for i in 0..<(result.len div 2):
    swap(result[i], result[result.len - i - 1])

proc all*(i: Iterable[bool]): bool =
  ## Returns true iff all items in i are true.
  result = true
  for item in i:
    result = result and item

# this should be called any, but the name is already used
proc someTrue*(i: Iterable[bool]): bool =
  ## Returns true iff some item in i is true.
  result = false
  for item in i:
    result = result or item

proc sorted*[T](i: Iterable[T]): seq[T] =
  result = i.toSeq
  sort(result, cmp[T])

converter toSeq*[T](s: Iterable[T]): seq[T] =
  result = @[]
  for item in s:
    result.add item

when isMainModule:
  iterator foo(foo: int): int {.multifuncIterator.} =
     yield foo

  for i in foo(5):
    assert i == 5

  let f = foo(5)
  for i in f:
    assert i == 5

  iterator foo1[T](foo: T): int {.multifuncIterator.} =
     yield foo

  assert flatten(@[@[1], @[2, 3]]).toSeq == @[1, 2, 3]
  assert grouping(@[1, 2, 3, 4, 5], 2).toSeq == @[@[1, 2], @[3, 4], @[5]]
  assert grouping(@[1, 2, 3, 4, 5], 2, discardLast=true).toSeq == @[@[1, 2], @[3, 4]]
  assert flatMap(@[1, 2], (x => @[x, x])).toSeq == @[1, 1, 2, 2]
  assert zip(@[1, 2, 3], @[-1, -2, -3]).toSeq == @[(1, -1), (2, -2), (3, -3)]
  assert zip(@[1, 2, 3], @[-1, -2]).toSeq == @[(1, -1), (2, -2)]
  assert unzip[int, int](@[(1, -1), (2, -2)]) == (@[1, 2], @[-1, -2])
  assert dropWhile(@[1, 2, 3, 4, 5, 6], x => (x != 3)).toSeq == @[3, 4, 5, 6]
  assert reversed(@[1, 2, 3]).toSeq == @[3, 2, 1]
  assert reversed(@[1, 2, 3, 4]).toSeq == @[4, 3, 2, 1]
