type TypeId* = distinct int

proc `==`(a: TypeId, b: TypeId): bool {.borrow.}

var currentTypeIndex {.compiletime.} = 0

proc nextTypeIndex(): int {.compiletime.} =
  currentTypeIndex += 1
  return currentTypeIndex

proc getTypeIndex[T](t: typedesc[T]): int =
  return nextTypeIndex()

proc typeid*[T: object](t: typedesc[T]): TypeId =
  return TypeId(getTypeIndex(T))

proc typeid*[T](t: typedesc[ref T]): TypeId =
  return typeid(T)
