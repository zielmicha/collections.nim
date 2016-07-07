## Implementation of slice type from Go
import collections/gcptr

type
  GoSlice*[T] = object
    data: gcptr[T]
    length: int
    capacity: int

proc slice*[T](s: GoSlice[T], low: int=0): GoSlice[T] =
  return slice(s, low, high=s.length, max=s.capacity)

proc slice*[T](s: GoSlice[T], low: int=0, high: int): GoSlice[T] =
  return slice(s, low, high=high, max=s.capacity)

proc slice*[T](s: GoSlice[T], low: int=0, high: int, max: int): GoSlice[T] =
  if low >= s.capacity:
    raise newException(ValueError, "low to big")
  if low > high:
    raise newException(ValueError, "low > high")
  if high > s.capacity:
    raise newException(ValueError, "low to high")
  if max + low > s.capacity:
    raise newException(ValueError, "max to high")

  return GoSlice[T](data: s.data + low, high - low, max - low)

proc len*(s: GoSlice): int =
  return s.length
