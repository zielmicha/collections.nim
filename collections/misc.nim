import collections/iterate, tables, options, strutils

proc toCounter*[T](values: Iterable[T]): CountTable[T] =
  result = initCountTable[T]()
  for v in values:
    result.inc(v)
  return result

proc keys*[A, B](s: Table[A, B]): Iterator[A] =
  return iterator(): A =
    for i in s.keys:
      yield i

proc default*[T](t: typedesc[T]): T =
  discard

proc initTable*[K, V](t: var Table[K, V]) =
  t = initTable[K, V]()

proc newTable*[K, V](t: var ref Table[K, V]) =
  t = newTable[K, V]()

# monadic operation for Option[T]

proc flatMap*[T](o: Option[T], f: proc(t: T): Option[T]): Option[T] =
  if o.isSome:
    return f(o.get)
  else:
    return o

proc map*[T](o: Option[T], f: proc(t: T): T): Option[T] =
  if o.isSome:
    return some[T](f(o.get))
  else:
    return o

proc split2*(s: string, sep: string): tuple[k: string, v: string] =
  let spl = s.split(sep, 1)
  if spl.len < 2:
    raise newException(ValueError, sep & " not in string")
  return (spl[0], spl[1])
