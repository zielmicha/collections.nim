import typetraits, macros

type
  WeakRef*[T] = ref object of RootObj
    ## Weak reference pointing to object of type T.
    target: pointer

  FreeCallback* = proc(r: pointer)

  WeakRefable* = object of RootObj
    ## Inherit from this object to enable taking weak references from it. You also need to use
    ## newWeakRefable, instead of new to allocate it.
    weakRef: RootRef
    freeCallback: FreeCallback

proc freeWeakRefable[T](v: ref T) =
  assert v != nil
  let wref = WeakRef[T](v.weakRef)
  if wref != nil:
    wref.target = nil
    v.weakRef = nil
  if v.freeCallback != nil:
    v.freeCallback(addr v[])

proc newWeakRefable*[T](typ: typedesc[ref T], freeCallback: FreeCallback=nil): ref T =
  ## Create a new object of type T. Invoke ``freeCallback`` when the object is freed.
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
  ## Convert a strong reference to a weak reference.
  return cast[WeakRef[T]](t.weakRef)

proc rawPointer*[T](r: WeakRef[ref T]): pointer =
  ## Get object pointer to by this weak reference as a raw pointer.
  return r.target

proc isAlive*[T](r: WeakRef[ref T]): bool =
  ## Check if this weak reference points to an object that is alive.
  return r.target != nil

proc lock*[T](r: WeakRef[ref T]): ref T =
  ## Convert a weak reference to a strong reference.
  ##
  ## Raises exception if object is not alive.
  if r.target == nil:
    raise newException(Exception, "weakref has already died")
  return cast[ref T](r.target) # guaranteed to be safe
