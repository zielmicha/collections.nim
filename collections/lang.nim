
proc identity*[T](v: T): T {.procvar.} = return v

proc nothing*() {.procvar.} = return

proc nothing1*[T](t: T) {.procvar.} = return

template returnMaybeVoid*(e: expr): stmt =
  if type(e) is void:
    e
    return
  else:
    return e

proc newCopy*[T](t: T): ref T =
  new(result)
  result[] = t

proc `&=`*[T](a: var seq[T], b: seq[T]) =
  for i in b:
    a.add(i)

proc flatten*[T](a: seq[seq[T]]): seq[T] =
  result = @[]
  for subseq in a:
    result &= subseq
