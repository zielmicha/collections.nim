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

proc slice*(s: string, low: int64=0): string =
  return s[low.int..^1]

proc slice*(s: string, low: int64=0, high: int64=0): string =
  return s[low.int..<high.int]

proc `[]`*[T](s: GoSlice[T], i: int): T =
  if i < 0 or i >= s.length:
    raise newException(ValueError, "bad index")

  let d: gcptr[T] = s.data
  return d.ptrAdd(i)[]

proc `[]`*(s: GoArray, i: int | uint8): auto =
  return s.arr[i.int]

proc `[]=`*[T](s: GoArray, i: int, val: T) =
  s.arr[i] = val

proc `[]=`*[T](s: GoSlice[T], i: int, val: T) =
  if i < 0 or i >= s.length:
    raise newException(ValueError, "bad index")

  let item = s.data.ptrAdd(i)
  item[] = val

proc `gcaddr[]`*[T](s: GoSlice[T], i: int): gcptr[T] =
  if i < 0 or i >= s.length:
    raise newException(ValueError, "bad index")

  return s.data.ptrAdd(i)

proc len*(s: GoSlice): int =
  return s.length

proc len*(s: GoArray): int =
  return s.arr.high

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

iterator pairs*[T](s: GoSlice[T]): (int, T) =
  for i in 0..<s.len:
    yield (i, s[i])

iterator items*[T](s: GoSlice[T]): T =
  for i in 0..<s.len:
    yield s[i]

converter toSeq*[T](s: GoSlice[T]): seq[T] =
  result = newSeq[T](s.len)
  for i, item in s:
    result[i] = item

proc `==`*[T](a: GoSlice[T], b: GoSlice[T]): bool =
  return a.data == b.data and a.len == b.len

proc copy*[T](dst: GoSlice[T], src: GoSlice[T]): int {.discardable.} =
  result = min(dst.len, src.len)
  if cast[uint](addr dst.data[]) > cast[uint](addr src.data[]):
    for i in 0..<result:
      dst[result - i - 1] = src[result - i - 1]
  else:
    for i in 0..<result:
      dst[i] = src[i]

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
