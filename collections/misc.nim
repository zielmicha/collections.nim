import collections/iterate
import tables

proc toCounter*[T](values: Iterable[T]): CountTable[T] =
  result = initCountTable[T]()
  for v in values:
    result.inc(v)
  return result

proc keys*[A, B](s: Table[A, B]): Iterator[A] =
  return iterator(): A =
    for i in s.keys:
      yield i
