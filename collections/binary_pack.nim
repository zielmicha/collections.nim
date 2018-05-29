import collections/bytes, collections/views, typetraits

type SizedInt = byte|char|int8|int16|int32|int64|uint8|uint16|uint32|uint64

proc binaryPack*[T: SizedInt](r: var string, o: T) =
  r &= pack(o, endian=littleEndian)

proc binaryUnpack*[T: SizedInt](r: var Buffer, res: var T) =
  res = unpack(r, T, endian=littleEndian)
  r = r.slice(sizeof(T))

proc binaryPack*[T: array](r: var string, o: T) =
  when o[0] is byte:
    r &= o.toBinaryString
  else:
    for i in o:
      r.binaryPack(i)

proc binaryUnpack*[T: array](r: var Buffer, res: var T) =
  when res[0] is byte:
    if r.len < sizeof(res):
      raise newException(EOFError, "")

    r.slice(0, sizeof(res)).copyTo(unsafeInitView(addr res[0], sizeof(res)))
    r = r.slice(sizeof(res))
  else:
    for i in res.low..res.high:
      r.binaryUnpack(res[i])

proc binaryUnpack*[T: object](r: var Buffer, res: var T) =
  for key, val in res.fieldPairs:
    r.binaryUnpack(val)

proc binaryPack*[T: object](r: var string, o: T) =
  for key, val in o.fieldPairs:
    r.binaryPack(val)

proc binaryUnpack*[T](r: Buffer, t: typedesc[T]): T =
  var r = r
  binaryUnpack(r, result)

proc binaryPack*[T](o: T): Buffer =
  var r = new(string)
  r[] = ""
  binaryPack(r[], o)
  return initView(r)
