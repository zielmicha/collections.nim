
proc unwrap*[T](p: SomeGcPtr, t: typedesc[ref T]): ref T {.inline.} =
  return cast[ref T](p.p)

proc unwrap*[T](p: SomeGcPtr, t: typedesc[gcptr[T]]): gcptr[T] {.inline.} =
  return cast[gcptr[T]](p)

proc unwrap*(p: SomeGcPtr, t: typedesc[NullType]): NullType {.inline.} =
  return null

proc toSomeGcPtr*[T](p: ref T): SomeGcPtr =
  return cast[SomeGcPtr](p.fromRef)

proc toSomeGcPtr*[T](p: gcptr[T]): SomeGcPtr =
  return cast[SomeGcPtr](p)

# Value types

type
  ValueWrapper[T] = ref object of RootObj
    value: T

  ValueType = string | int

proc toSomeGcPtr*(p: ValueType): SomeGcPtr =
  return toSomeGcPtr(ValueWrapper[ValueType](value: p))

proc unwrap*(p: SomeGcPtr, t: typedesc[ValueType]): ValueType {.inline.} =
  return unwrap(p, ValueWrapper[ValueType]).value
