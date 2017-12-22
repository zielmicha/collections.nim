import collections/weakref, tables, macros, typetraits

export weakref

type
  WeakValueTableObj[K, V] = object of RootObj
    t: TableRef[K, WeakRef[V]]

  WeakValueTable*[K, V] = WeakRefable[WeakValueTableObj[K, V]]

proc newWeakValueTable*[K, V](self: var WeakValueTable[K, V]) =
  ## Creates a table, which doesn't prevent its value from being destructed.
  ## (when this happens, the key-value pair is removed from table).
  let table = newTable[K, WeakRef[V]]()
  self = newWeakRefable((ref WeakValueTableObj[K, V])())
  self.obj.t = table

proc newWeakValueTable*[K, V](): WeakValueTable[K, V] =
  newWeakValueTable(result)

proc `$`*[K, V](self: WeakValueTable[K, V]): string =
  var s = "WeakValueTable ("
  for k, v in self.obj.t.pairs:
    s.add(($k) & " = " & ($v.lock) & ", ")
  return s & ")"

proc contains*[K, V](self: WeakValueTable[K, V], k: K): bool =
  return k in self.obj.t

proc `[]`*[K, V](self: WeakValueTable[K, V], k: K): WeakRefable[V] =
  return self.obj.t[k].lock

proc len*[K, V](self: WeakValueTable[K, V]): int =
  return self.obj.t.len

proc del*[K, V](self: WeakValueTable[K, V], k: K) =
  del(self.obj.t, k)

proc makeFreeFunc[A, K, V](weakSelf: A, k: K, freeCallback: proc(v: ref V) {.cdecl.}): auto =
  proc free(arg: ref V) =
    if not weakSelf.isAlive: return
    let self = weakSelf.lock().obj

    if freeCallback != nil:
      freeCallback(arg)

    if k in self.t and (not self.t[k].isAlive):
      del self.t, k

  return free

proc addKey*[K, V](self: WeakValueTable[K, V], k: K, v: ref V, freeCallback: proc(v: ref V) {.cdecl.}=nil): WeakRefable[V] =
  ## Add a new item at key ``k`` to the table. Invoke ``freeCallback`` when there are no
  ## more references to this item.
  let weakSelf = self.weakRef
  assert weakSelf != nil

  let r = newWeakRefable(v, makeFreeFunc(weakSelf, k, freeCallback))
  self.obj.t[k] = r.weakRef
  return r
