## Implementation of slice type from Go
import collections/gcptrs

type
  GoSlice*[T] = object
    data: gcptr[T]
    length: int
    capacity: int

  SeqWrapper[T] = object of RootObj
    s: seq[T]

  GoArray*[T; n: static[int]] = ref object of RootObj
    arr: array[n, T]

proc slice*[T](s: GoSlice[T], low: int64=0, high: int64, max: int64): GoSlice[T] =
  if low >= s.capacity:
    raise newException(ValueError, "low to big")
  if low > high:
    raise newException(ValueError, "low > high")
  if high > s.capacity:
    raise newException(ValueError, "low to high")
  if max + low > s.capacity:
    raise newException(ValueError, "max to high")

  let newBase = s.data.ptrAdd(low.int)
  return GoSlice[T](data: newBase, length: int(high - low), capacity: int(max - low))

proc slice*[T](s: GoSlice[T], low: int64=0): GoSlice[T] =
  return slice(s, low, high=s.length, max=s.capacity)

proc slice*[T](s: GoSlice[T], low: int64=0, high: int64): GoSlice[T] =
  return slice(s, low, high=high, max=s.capacity)

proc `[]`*[T](s: GoSlice[T], i: int): T =
  if i < 0 or i >= s.length:
    raise newException(ValueError, "bad index")

  let d: gcptr[T] = s.data
  return d.ptrAdd(i)[]

proc `[]=`*[T](s: GoSlice[T], i: int, val: T) =
  if i < 0 or i >= s.length:
    raise newException(ValueError, "bad index")

  let item = s.data.ptrAdd(i)
  item[] = val

proc len*(s: GoSlice): int =
  return s.length

proc make*[T](t: typedesc[GoSlice[T]], len: int): GoSlice[T] =
  let wrapper = new(SeqWrapper[T])
  newSeq(wrapper.s, len)
  result.data = makeGcptr(addr wrapper.s[0], wrapper)
  result.length = len
  result.capacity = len

converter toSlice*(s: string): GoSlice[byte] =
  let slice: GoSlice[byte] = make(GoSlice[byte], s.len)
  for i in 0..<s.len:
    slice[i] = s[i].byte
  return slice

converter toSlice*[T; n: static[int]](arr: GoArray[T, n]): GoSlice[T] =
  when n == 0:
    return GoSlice[T](data: null, length: 0, capacity: 0)
  else:
    return GoSlice[T](data: makeGcPtr(addr arr.arr[0], arr), length: n, capacity: n)

proc `==`*[T](a: GoSlice[T], b: GoSlice[T]): bool =
  return a.data == b.data and a.len == b.len

proc copy*[T](dst: GoSlice[T], src: GoSlice[T]): int {.discardable.} =
  # TODO
  result = min(dst.len, src.len)
  for i in 0..<result:
    dst[i] = src[i]

iterator pairs*[T](s: GoSlice[T]): (int, T) =
  for i in 0..<s.len:
    yield (i, s[i])

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
