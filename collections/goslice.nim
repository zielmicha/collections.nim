## Implementation of slice type from Go
import collections/gcptrs

type
  GoSlice*[T] = object
    data: gcptr[T]
    length: int
    capacity: int

  GoArray*[T; n: static[int]] = ref array[n, T]

proc slice*[T](s: GoSlice[T], low: int64=0, high: int64, max: int64): GoSlice[T] =
  if low >= s.capacity:
    raise newException(ValueError, "low to big")
  if low > high:
    raise newException(ValueError, "low > high")
  if high > s.capacity:
    raise newException(ValueError, "low to high")
  if max + low > s.capacity:
    raise newException(ValueError, "max to high")

  #let newBase = s.data. +% low
  echo s.data.p.repr
  let newBase = null
  return GoSlice[T](data: newBase, length: int(high - low), capacity: int(max - low))

proc slice*[T](s: GoSlice[T], low: int64=0): GoSlice[T] =
  return slice(s, low, high=s.length, max=s.capacity)

proc slice*[T](s: GoSlice[T], low: int64=0, high: int64): GoSlice[T] =
  return slice(s, low, high=high, max=s.capacity)

proc len*(s: GoSlice): int =
  return s.length

type
  SeqWrapper[T] = object of RootObj
    s: seq[T]

proc make*[T](t: typedesc[GoSlice[T]], len: int): GoSlice[T] =
  let wrapper = new(SeqWrapper[T])
  newSeq(wrapper.s, len)
  result.data = makeGcptr(addr wrapper.s[0], wrapper)
  result.length = len
  result.capacity = len

converter toSlice*(s: string): GoSlice[byte] =
  let slice = make(GoSlice[byte], s.len)
  # TODO
  return slice

proc `==`*[T](a: GoSlice[T], b: GoSlice[T]): bool =
  return a.data == b.data and a.len == b.len

template specializeGoSlice*(T) =
  # Nim doesn't have return type inference for converters :(
  converter fromNil*(t: NullType): GoSlice[T] =
    return GoSlice[T](data: null, length: 0, capacity: 0)

specializeGoSlice(int)
specializeGoSlice(int8)
specializeGoSlice(int16)
specializeGoSlice(int32)
specializeGoSlice(int64)
specializeGoSlice(uint)
specializeGoSlice(uint8) # same as byte
specializeGoSlice(uint16)
specializeGoSlice(uint32)
specializeGoSlice(uint64)
specializeGoSlice(string)
