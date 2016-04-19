
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
