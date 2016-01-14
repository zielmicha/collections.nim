import future

export `->`, `=>`

template staticAssert*(v, msg) =
  when not v:
    {.error: msg.}

proc declVal*[T](): T =
  doAssert(false)

proc declVal*[T](d: typedesc[T]): T =
  doAssert(false)
