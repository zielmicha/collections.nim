import typetraits, macros

type
  WeakRef*[T] = ref object of RootObj
    ## Weak reference pointing to object of type T.
    target: pointer

  CallbackWrapper[T] = ref object
    callback: proc(v: ref T)

  WeakRefable*[T] = ref object of RootObj
    obj*: ref T
    freeCallback: CallbackWrapper[T]
    weakRef: WeakRef[T]

proc freeWeakRefable[T](v: WeakRefable[T]) {.procvar.} =
  v.weakRef.target = nil
  if v.freeCallback.callback != nil:
    v.freeCallback.callback(v.obj)

  GC_unref(v.obj)
  GC_unref(v.freeCallback)
  GC_unref(v.weakRef)
  v.obj = nil
  v.freeCallback = nil
  v.weakRef = nil

proc newWeakRefable*[T](val: ref T, freeCallback: proc(v: ref T)=nil): WeakRefable[T] =
  ## Create a new object of type T. Invoke ``freeCallback`` when the object is freed.
  let callback = CallbackWrapper[T](callback: freeCallback)
  GC_ref(callback)
  GC_ref(val)

  new(result, freeWeakRefable[T])
  result.obj = val
  result.freeCallback = callback
  result.weakRef = WeakRef[T](target: cast[pointer](result))
  GC_ref(result.weakRef)

proc weakRef*[T](t: WeakRefable[T]): WeakRef[T] =
  ## Convert a strong reference to a weak reference.
  assert t != nil
  return t.weakRef

proc rawPointer*[T](r: WeakRef[T]): pointer =
  ## Get object pointer to by this weak reference as a raw pointer.
  assert r != nil
  return r.target

proc isAlive*[T](r: WeakRef[T]): bool =
  ## Check if this weak reference points to an object that is alive.
  assert r != nil
  return r.target != nil

proc lock*[T](r: WeakRef[T]): WeakRefable[T] =
  ## Convert a weak reference to a strong reference.
  ##
  ## Raises exception if object is not alive.
  assert r != nil
  if r.target == nil:
    raise newException(Exception, "weakref has already died")
  return cast[WeakRefable[T]](r.target) # guaranteed to be safe
