
var currentTypeIndex {.compiletime.}: int = 1

proc nextTypeIndex*(): int {.compiletime.} =
  currentTypeIndex += 1
  return currentTypeIndex

proc getTypeIndex*[T](t: typedesc[T]): int =
  result = nextTypeIndex()
