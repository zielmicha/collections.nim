## Implementation of slice type from Go
import collections/gcptrs, typetraits

type
  GoSlice*[T] = object
    data: gcptr[T]
    length: int
    capacity: int

  SeqWrapper[T] = object of RootObj
    s: seq[T]

  GoArray*[T; n: static[int]] = object of RootObj
    arr: array[n, T]

proc slice*[T](s: GoSlice[T], low: int64=0, high: int64, max: int64): GoSlice[T] =
  if low >= s.capacity:
    raise newException(ValueError, "low too big")
  if low > high:
    raise newException(ValueError, "low > high")
  if high > s.capacity:
    raise newException(ValueError, "low too high")
  if max + low > s.capacity:
    raise newException(ValueError, "max too high")

  let newBase = s.data.ptrAdd(low.int)
  return GoSlice[T](data: newBase, length: int(high - low), capacity: int(max - low))

proc slice*[T](s: GoSlice[T], low: int64=0): GoSlice[T] =
  if low >= s.capacity:
    raise newException(ValueError, "low too big")
  return slice(s, low, high=s.length, max=s.capacity - low)

proc slice*[T](s: GoSlice[T], low: int64=0, high: int64): GoSlice[T] =
  if low >= s.capacity:
    raise newException(ValueError, "low too big")
  return slice(s, low, high=high, max=s.capacity - low)

proc slice*(s: string, low: int64=0): string =
  return s[low.int..^1]

proc slice*(s: string, low: int64=0, high: int64): string =
  return s[low.int..<high.int]

proc `[]`*[T](s: GoSlice[T], i: int): var T =
  if i < 0 or i >= s.length:
    raise newException(ValueError, "bad index")

  let d: gcptr[T] = s.data
  return d.ptrAdd(i)[]

proc `[]`*(s: GoArray, i: SomeInteger): auto =
  return s.arr[i.int]

proc `[]`*[T; ss: static[int]](s: var GoArray[T, ss], i: int): var T =
  return s.arr[i.int]

proc `[]`*[T; ss: static[int]](s: GoArray[T, ss], i: int): T =
  return s.arr[i.int]

proc `[]=`*[T](s: var GoArray, i: int, val: T) =
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

proc cap*(s: GoSlice): int =
  return s.capacity

proc len*(s: GoArray): int =
  return s.arr.len

proc make*[T](t: typedesc[GoSlice[T]], len: int, cap: int): GoSlice[T] =
  let wrapper = new(SeqWrapper[T])
  newSeq(wrapper.s, len)
  result.data = makeGcptr(addr wrapper.s[0], wrapper)
  result.length = len
  result.capacity = cap

proc make*[T](t: typedesc[GoSlice[T]], len: int): GoSlice[T] =
  return make(GoSlice[T], len, len)

converter toSlice*(s: string): GoSlice[byte] =
  let slice: GoSlice[byte] = make(GoSlice[byte], s.len)
  for i in 0..<s.len:
    slice[i] = s[i].byte
  return slice

converter toString*(slice: GoSlice[byte]): string =
  result = newString(slice.len)
  for i in 0..<slice.len:
    result[i] = slice[i].char

proc gosliceFromArr[T; ss: static[int]](arr: GoArray[T, ss], data: gcptr[T], len: int): GoSlice[T] =
  return GoSlice[T](data: data, length: len, capacity: len)

proc gosliceFromArr[T; ss: static[int]](arr: GoArray[T, ss], data: NullType, len: int): GoSlice[T] =
  return GoSlice[T](data: makeGcptr[T](nil, nil), length: len, capacity: len)

template arrToSlice*(input): expr =
  if input.len == 0:
    gosliceFromArr(input, null, 0)
  else:
    let p = gcaddr input
    gosliceFromArr(input, p.replaceAddr(addr input[0]), input.len)

template slice*(arr: var GoArray, low: int64=0): expr =
  slice(arrToSlice(arr), low)

template slice*(arr: var GoArray, low: int64=0, high: int64): expr =
  slice(arrToSlice(arr), low, high)

template slice*(arr: var GoArray, low: int64=0, high: int64, cap: int64): expr =
  slice(arrToSlice(arr), low, high, cap)

template slice*(arr: var GoArray, low: int64=0, cap: int64): expr =
  slice(arrToSlice(arr), low, cap=cap)

iterator pairs*[T](s: GoSlice[T]): (int, T) =
  for i in 0..<s.len:
    yield (i, s[i])

iterator items*[T](s: GoSlice[T]): T =
  for i in 0..<s.len:
    yield s[i]

iterator items*[T; ss: static[int]](s: GoArray[T, ss]): T =
  for i in 0..<s.len:
    yield s[i]

iterator pairs*[T; ss: static[int]](s: GoArray[T, ss]): (int, T) =
  for i in 0..<s.len:
    yield (i, s[i])

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

  converter fromNil*(t: NullType): GoSlice[gcptr[T]] =
    return GoSlice[gcptr[T]](data: null, length: 0, capacity: 0)

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
