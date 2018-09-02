## This module provides `pprint` function that handles pretty printing of objects.
import typetraits, future, strutils, macros, tables
import collections/iterate, collections/macrotool

template compilesOr(obj, otherwise): untyped =
  when compiles(obj):
    obj
  else:
    otherwise

proc privateGuard(obj: NimNode): NimNode {.compiletime.} =
  return newCall(bindSym"compilesOr", obj, newStrLitNode("(private)"))

proc addField(obj: NimNode, k: string): NimNode {.compiletime.} =
  let pair = newNimNode(nnkPar).add(
    newStrLitNode(k),
    newCall(newIdentNode("pprint"), privateGuard(newDotExpr(obj, newIdentNode(k)))))
  return newCall(newIdentNode("add"), newIdentNode("result"), pair)

proc addFieldsBranch(obj: NimNode, typ: NimNode): NimNode {.compiletime.} =
  let body = newNimNode(nnkStmtList)
  for node in typ:
    if node.kind == nnkSym:
      let nameStr = $node
      body.add addField(obj, nameStr)
    elif node.kind == nnkRecCase:
      let recName = $node[0]
      body.add addField(obj, recName)
      for branch in node[1..<node.len]:
        let value = branch[0]
        let cond = newCall(newIdentNode("=="),
                           newDotExpr(obj, newIdentNode(recName)), value)
        let subbody = addFieldsBranch(obj, branch[1])
        let branchExpr = newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(cond, subbody))
        body.add(branchExpr)
  return body

macro objFieldsAdd(obj: typed): typed =
  var t = getType(obj)

  if t.kind == nnkSym:
    t = t.getType

  if t.kind == nnkBracketExpr:
    let typePrefix = $(t[0])
    if typePrefix != "ref" or t.len != 2:
      error("unknown type definition")
    t = t[1].getType

  if t.kind != nnkObjectTy or t[2].kind != nnkRecList:
    error("unknown type definition")

  let body = newNimNode(nnkStmtList)
  body.add(addFieldsBranch(obj, t[2]))

  return body

proc objFields[T](obj: T): seq[(string, string)] =
  result = @[]
  objFieldsAdd(obj)

proc pprintPairs(prefix: string, s: seq[(string, string)]): string =
  let inner = s.map(x => x[0] & ": " & x[1]).toSeq.join(", ")
  return prefix & "(" & inner & ")"

proc pprintObject[T](prefix: string, obj: T): string =
  return pprintPairs(prefix & name(T), objFields(obj))

proc pprint*(obj: string): string =
  result = "\""
  for ch in obj:
    # TODO
    if ch == '\L':
      result &= "\n"
    else:
      result.add ch
  result &= "\""

proc pprint*[T](obj: seq[T]): string =
  mixin pprint
  if obj.isNil: return "nil"
  let inner = obj.map(x => pprint(x)).toSeq.join(", ")
  return "@[" & inner & "]"

proc pprint*[T](obj: T): string =
  ## Generic pprint implementation
  when T is object and compiles(pprintObject(obj)):
    return pprintObject("", obj)
  elif compiles($obj):
    when compiles(obj == nil):
      if obj == nil:
        return "nil"

    return $obj
  elif T is ref object:
    if obj == nil: return "nil"
    return pprintObject("", obj)
  elif T is (proc):
    return name(T)
  else:
    return obj.repr

proc pprint*[K, V](t: Table[K, V]): string =
  var values: seq[string] = @[]
  for k, v in t:
    values.add(pprint(k) & ": " & pprint(v))
  return "{" & values.join(", ") & "}"

proc pprint*[K, V](t: ref Table[K, V]): string =
  return pprint(t[])
