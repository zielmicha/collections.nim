type TypeId* = distinct int

proc `==`*(a: TypeId, b: TypeId): bool {.borrow.}

var currentTypeIndex {.compiletime.} = 0

proc nextTypeIndex(): int {.compiletime.} =
  currentTypeIndex += 1
  return currentTypeIndex

proc getTypeIndex[T](t: typedesc[T]): int =
  return nextTypeIndex()

proc typeId*[T](t: typedesc[T]): TypeId =
  return TypeId(getTypeIndex(T))
