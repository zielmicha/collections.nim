import endians

proc byteArray*(data: string, size: static[int]): array[size, byte] =
  ## Converts a string to a bytearray.
  if data.len != size:
    raise newException(ValueError, "bad length")
  copyMem(addr result, data.cstring, size)

proc toBinaryString*[T: array](s: T): string =
  ## Converts an array of bytes to a string.
  const size = s.high - s.low + 1
  result = newString(size)
  copyMem(result.cstring, unsafeAddr(s), size)

proc setAt*(s: var string, at: int, data: string) =
  doAssert(s.len >= data.len + at)
  copyMem(cast[pointer](cast[int](addr s[0]) + at), data.cstring, data.len)

proc convertEndian(size: static[int], dst: pointer, src: pointer, endian=bigEndian) {.inline.} =
  when size == 1:
    copyMem(dst, src, 1)
  else:
    case endian:
    of bigEndian:
      when size == 2:
        bigEndian16(dst, src)
      elif size == 4:
        bigEndian32(dst, src)
      elif size == 8:
        bigEndian64(dst, src)
      else:
        {.error: "Unsupported size".}
    of littleEndian:
      when size == 2:
        littleEndian16(dst, src)
      elif size == 4:
        littleEndian32(dst, src)
      elif size == 8:
        littleEndian64(dst, src)
      else:
        {.error: "Unsupported size".}

proc pack*[T](v: T, endian=bigEndian): string {.inline.} =
  ## Converts scalar `v` into a binary string with specific endianness.
  result = newString(sizeof(v))
  convertEndian(sizeof(T), addr result[0], unsafeAddr v, endian=endian)

proc unpack*[T](v: string, t: typedesc[T], endian=bigEndian): T {.inline.} =
  ## Converts binary string to scalar type `t` with specific endianness.
  if v.len < sizeof(T):
    raise newException(ValueError, "buffer too small")
  convertEndian(sizeof(T), addr result, unsafeAddr v[0], endian)

proc packStruct*[T](t: T): string {.inline.} =
  ## Dumps `t` to a string (in a same format as it is stores in memory)
  result = newString(sizeof(t))
  copyMem(addr result[0], unsafeAddr t, sizeof(T))

proc unpackStruct*[T](v: string, t: typedesc[T]): T {.inline.} =
  ## Loads `t` from a string (simple by copying as casting `v` to it). Unsafe.
  if v.len < sizeof(T):
    raise newException(ValueError, "buffer too small")
  copyMem(addr result, unsafeAddr v[0], sizeof(T))
