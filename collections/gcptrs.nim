import macros, collections/nestedaccessor

export makeNestedAccessors

const useGcRef = not (compileOption("gc", "boehm") or compileOption("gc", "none"))

type
  gcptr*[T] = object
    p: ptr T
    when useGcRef:
      gcref: RootRef

  SomeGcPtr* = gcptr[pointer]

  NullType* = object # type(nil) is not first class :(

const null* = NullType()

proc makeGcptr*[T](p: ptr T, gcref: RootRef): gcptr[T] =
  when useGcRef:
    return gcptr[T](p: p, gcref: gcref)
  else:
    return gcptr[T](p: p)

proc makeGcptr*[T, R](p: ptr T, gcref: gcptr[R]): gcptr[T] =
  return makeGcptr(p, gcref.gcref)

proc gcnew*[T](t: typedesc[T]): gcptr[T] =
  let p = new(T)
  return makeGcptr(addr p[], p)

proc ptrAdd*[T](a: gcptr[T], b: int): gcptr[T] =
  return makeGcptr(cast[ptr T](cast[uint](a.p) + uint(sizeof(T) * b)),
                   when useGcRef: a.gcref else: nil)

converter fromRef*[T](t: ref T): gcptr[T] =
  return makeGcptr(cast[ptr T](t), t.RootRef)

#converter toVar*[T](t: gcptr[T]): var T =
#  return t[]

proc `==`*[T](a, b: gcptr[T]): bool =
  return a.p == b.p

include collections/somegcptr

proc `[]`*[T](v: gcptr[T]): var T =
  return v.p[]

proc `[]=`*[T](v: gcptr[T], val: T) =
  v.p[] = val

type
  FuncWrapper[T] = ref object of RootObj
    fun: (proc(): T)

template gclocaladdr*(v): expr =
  let getAddr = (proc(): ptr type(v) = unsafeAddr(v))
  makeGcptr(getAddr(), FuncWrapper[ptr type(v)](fun: getAddr))

macro gcaddr*(v: untyped): expr =
  # TODO: members of ref and gcptr types e.g:
  # TODO: gcaddr getFoo().bar where getFoo returns gcptr type
  if v.kind == nnkBracketExpr:
    return newCall(newIdentNode("gcaddr[]"), v[0], v[1])
  else:
    return newCall(newIdentNode("gclocaladdr"), v)

template specializeGcPtr*(T) =
  # Nim doesn't have return type inference for converters :(
  converter fromNil*(t: NullType): gcptr[T] =
    return makeGcptr[T](nil, nil)

  converter fromNil*(t: NullType): gcptr[gcptr[T]] =
    return makeGcptr[gcptr[T]](nil, nil)

  makeNestedAccessors(T, gcptr[T], `[]`)

specializeGcPtr(int)
specializeGcPtr(int8)
specializeGcPtr(int16)
specializeGcPtr(int32)
specializeGcPtr(int64)
specializeGcPtr(uint)
specializeGcPtr(uint8) # same as byte
specializeGcPtr(uint16)
specializeGcPtr(uint32)
specializeGcPtr(uint64)
specializeGcPtr(string)
