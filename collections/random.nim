import collections/bytes

proc urandom*(len: int): string =
  var f = open("/dev/urandom")
  defer: f.close
  result = ""
  result.setLen(len)
  let actualRead = f.readBuffer(result.cstring, len)
  if actualRead != len:
    raise newException(IOError, "cannot read random bytes")

proc hexUrandom*(len: int): string =
  urandom(len).encodeHex
