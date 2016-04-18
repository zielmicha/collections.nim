
proc byteArray*(data: string, size: static[int]): array[size, byte] =
  if data.len != size:
    raise newException(ValueError, "bad length")
  copyMem(addr result, data.cstring, size)

proc toBinaryString*[T: array](s: T): string =
  const size = s.high - s.low + 1
  result = newString(size)
  copyMem(result.cstring, unsafeAddr(s), size)

proc setAt*(s: var string, at: int, data: string) =
  doAssert(s.len >= data.len + at)
  copyMem(cast[pointer](cast[int](addr s[0]) + at), data.cstring, data.len)
