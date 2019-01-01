import future, macros

export `->`, `=>`

template staticAssert*(v, msg) =
  when not v:
    {.error: msg.}

proc declVal*[T](): T =
  doAssert(false)

proc declVal*[T](d: typedesc[T]): T =
  doAssert(false)

proc identity*[T](v: T): T {.procvar.} = return v

proc nothing*() {.procvar.} = return

proc nothing1*[T](t: T) {.procvar.} = return

proc defaultVal*[T](t: typedesc[T]): T = discard

template returnMaybeVoid*(e: typed): untyped =
  if type(e) is void:
    e
    return
  else:
    return e

proc toArray*[T](a: seq[T], s: static[int]): array[s, T] =
  doAssert a.len == s
  for i in 0..<s:
    result[i] = a[i]

proc newCopy*[T](t: T): ref T =
  new(result)
  result[] = t

proc `&=`*[T](a: var seq[T], b: seq[T]) =
  for i in b:
    a.add(i)

proc flatten*[T](a: seq[seq[T]]): seq[T] =
  result = @[]
  for subseq in a:
    result &= subseq

proc remove*[T](a: var seq[T], item: T): bool {.discardable.} =
  let ind = find(a, item)
  if ind == -1:
    return false
  else:
    a.delete(ind)
    return true

proc reverse*(a: var string) =
  for i in 0..<(a.len div 2):
    swap a[i], a[a.len - i - 1]

proc nilToEmpty*(a: string): string {.deprecated.} =
  return a

template forwardRefImpl*(ty, tyImpl) =
  ## Marks type `tyImpl` as implementation of forward reference type
  ## `ty`. `ty` should be defined as `distinct RootRef` and `tyImpl` should
  ## by `ref object of RootObj`.

  converter `to ty`*(v: `tyImpl`): `ty` =
    return cast[`ty`](v)

  converter `to tyImpl`*(v: `ty`): `tyImpl` =
    return cast[`tyImpl`](v)

proc forceNoClosure[T](p: T): T {.inline.} =
  # Doesn't work due to Nim bug
  # assert sizeof(p) == 8
  return p

macro bindOnlyVars*(vars: untyped, code: untyped): untyped =
  if vars.kind != nnkBracket:
    error("expected bindOnlyVars([varname1, varname2, ...], code)")

  var params: seq[NimNode] = @[]
  params.add(newIdentNode("auto")) # return value
  for arg in vars:
    params.add(newNimNode(nnkIdentDefs).add(arg,
                                            # newIdentNode("auto"),
                                            newCall("type", arg),
                                            newEmptyNode()))

  let p = newProc(newEmptyNode(), params=params, body=code,
                                         procType=nnkLambda)
  p[4] = newNimNode(nnkPragma).add(newIdentNode("nimcall"))
  let call = newNimNode(nnkCall).add(newCall(bindSym"forceNoClosure", p))
  for arg in vars:
    call.add(arg)
  return call

macro partial*(body: untyped): untyped =
  var body = body
  if body.kind != nnkCall:
    error("partial() expects a function call")

  result = newNimNode(nnkLambda)
  let params = newNimNode(nnkFormalParams)

  params.add(newIdentNode("auto"))

  proc walk(item: NimNode): NimNode =
    if item.kind == nnkIdent and $item == "_":
      let s = genSym(nskParam, "x")
      params.add(newNimNode(nnkIdentDefs).add(
        s,
        newIdentNode("auto"),
        newNimNode(nnkEmpty)
      ))
      return s
    else:
      for i in 0..<len(item):
        item[i] = walk(item[i])
      return item

  body = walk(body)

  result.add(
    newNimNode(nnkEmpty),
    newNimNode(nnkEmpty),
    newNimNode(nnkEmpty),
    params,
    newNimNode(nnkEmpty),
    newNimNode(nnkEmpty),
    body,
  )

  result.repr.echo
