import typetraits, macros

type
  WeakRef*[T] = ref object of RootObj
    ## Weak reference pointing to object of type T.
    target: pointer

  FreeCallback = proc(r: pointer)

  WeakRefable* = object of RootObj
    ## Inherit from this object to enable taking weak references from it. You also need to use
    ## newWeakRefable, instead of new to allocate it.
    weakRef: RootRef
    freeCallback: FreeCallback

proc freeWeakRefable[T](v: ref T) =
  let wref = WeakRef[T](v.weakRef)
  if wref != nil:
    wref.target = nil
    v.weakRef = nil
  if v.freeCallback != nil:
    v.freeCallback(addr v[])

proc newWeakRefable*[T](typ: typedesc[ref T], freeCallback: FreeCallback=nil): ref T =
  static:
    if not (T is WeakRefable):
      error(name(T) & " has to inherit from WeakRefable")
  var val: ref T
  new(val, freeWeakRefable[T])
  var wref = WeakRef[T](target: addr val[])
  val.weakRef = wref
  val.freeCallback = freeCallback
  return val

proc weakRef*[T: ref WeakRefable](t: T): WeakRef[T] =
  return cast[WeakRef[T]](t.weakRef)

proc rawPointer*[T](r: WeakRef[ref T]): pointer =
  return r.target

proc isAlive*[T](r: WeakRef[ref T]): bool =
  return r.target != nil

proc lock*[T](r: WeakRef[ref T]): ref T =
  if r.target == nil:
    raise newException(Exception, "weakref has already died")
  return cast[ref T](r.target) # guaranteed to be safe
