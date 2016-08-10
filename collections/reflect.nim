import tables, typetraits

type TypeId* = distinct int

let InvalidTypeId* = TypeId(0)

proc `==`*(a: TypeId, b: TypeId): bool {.borrow.}

var currentTypeIndex {.compiletime.} = 0

var typeNames = initTable[int, string]()

typeNames[0] = "INVALID"

proc nextTypeIndex(): int {.compiletime.} =
  currentTypeIndex += 1
  return currentTypeIndex

proc getTypeIndex[T](t: typedesc[T]): int =
  result = nextTypeIndex()
  # TODO: threads
  var initialized {.global.} = false
  if not initialized:
    initialized = true
    typeNames[result] = name(T)

proc name*(t: TypeId): string =
  return typeNames[t.int]

proc typename*(t: TypeId): string =
  return t.name

proc typename*[T](t: typedesc[T]): string =
  return name(T)

proc typeId*[T](t: typedesc[T]): TypeId =
  return TypeId(getTypeIndex(T))
