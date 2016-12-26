import future

export `->`, `=>`

template staticAssert*(v, msg) =
  when not v:
    {.error: msg.}

proc declVal*[T](): T =
  doAssert(false)

proc declVal*[T](d: typedesc[T]): T =
  doAssert(false)

proc identity*[T](v: T): T {.procvar.} = return v

proc nothing*() {.procvar.} = return

proc nothing1*[T](t: T) {.procvar.} = return

proc defaultVal*[T](t: typedesc[T]): T = discard

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

proc nilToEmpty*(a: string): string =
  if a == nil:
    return ""
  else:
    return a

template forwardRefImpl*(ty, tyImpl) =
  ## Marks type `tyImpl` as implementation of forward reference type
  ## `ty`. `ty` should be defined as `distinct RootRef` and `tyImpl` should
  ## by `ref object of RootObj`.

  converter `to ty`*(v: `tyImpl`): `ty` =
    return cast[`ty`](v)

  converter `to tyImpl`*(v: `ty`): `tyImpl` =
    return cast[`tyImpl`](v)
