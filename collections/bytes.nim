import endians, strutils, base64, collections/views

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

#converter toBinaryStringConv*[size: static[int]](s: array[size, byte]): string =
#  return toBinaryString(s)

proc setAt*(s: var string, at: int, data: string) =
  ## Put ``data`` at position ``at`` of string ``s``.
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

proc pack*[T](v: T, endian: Endianness=littleEndian): string {.inline.} =
  ## Converts scalar `v` into a binary string with a specific endianness.
  result = newString(sizeof(v))
  convertEndian(sizeof(T), addr result[0], unsafeAddr v, endian=endian)

proc unpack*[T](v: string|Buffer, t: typedesc[T], endian: Endianness=littleEndian): T {.inline.} =
  ## Converts binary string to scalar type `t` with a specific endianness.
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

# HEX

const hexLetters = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

proc encodeHex*(s: string): string =
  result = ""
  result.setLen(s.len * 2)
  for i in 0..s.len-1:
    var a = ord(s[i]) shr 4
    var b = ord(s[i]) and ord(0x0f)
    result[i * 2] = hexLetters[a]
    result[i * 2 + 1] = hexLetters[b]

proc decodeHex*(s: string): string =
  if s.len mod 2 == 1: raise newException(ValueError, "odd-length string")
  let s = s.toLowerAscii

  result = newString(int(s.len / 2))
  for i in 0..<int(s.len/2):
    let a = find(hexLetters, s[i * 2])
    let b = find(hexLetters, s[i * 2 + 1])
    if a == -1 or b == -1:
      raise newException(ValueError, "invalid hex digit")
    result[i] = char((a shl 4) or b)

# Base64

proc urlsafeBase64Encode*(s: string): string =
  return base64.encode(s, newline="").replace('+', '-').replace('/', '_').strip(chars={'='})

proc urlsafeBase64Decode*(s: string): string =
  var d = s.replace('-', '+').replace('_', '/')
  while len(d) mod 4 != 0:
    d.add('=')
  return base64.decode(d)
