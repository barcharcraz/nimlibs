import parseopt, macros
import fowltek/macro_dsl
 
macro parseOptions*(body: stmt): stmt {.immediate.}=
  body.expectKind nnkStmtList
  
  var opts = newSeq[tuple[flags:seq[string], body:PNimrodNode]](0)
  for i in 0 .. <len(body):
    let n = body[i]
    if n.kind == nnkCommand and $n[0] == "on":
      assert n.len > 2, "`on` line needs at least one string parameter"
      var flags = newSeq[string](0)
      for i in 1 .. n.len-2: 
        if n[i].kind == nnkExprEqExpr: 
          ##use these later, accept help="..." and default=VALUE
          continue 
        n[i].expectKInd nnkStrLit
        flags.add n[i].strval
      opts.add((flags, n[n.len-1].body)) #n[n.len-1].body is the stmtlist of the `do` attached
      # to the command
      
  var resCase = newNimNode(nnkCaseStmt).und(!!"key")
  for o in opts:
    var c = newNimNode(nnkOfBranch)
    for f in o.flags: c.add newStrLitNode(f)
    c.add o.body
    resCase.add c
  resCase.add(newNimNode(nnkElse).und(quote do:
    echo "Unrecognized option: ", key))
  
  when false:
    result = quote do:
      for kind, key, value in getOpt():
        case kind
        of cmdLongOption, cmdShortOption:
          `resCase`
        else: nil
  else:
    result = newNimNode(nnkForStmt).und(
      !!"kind",
      !!"key",
      !!"value",
      newCall("getOpt"),
      newStmtList(
        newNimNode(nnkCaseStmt).und(
          !!"kind",
          newNimNode(nnkOfBranch).und(
            !!"cmdLongOption", !!"cmdShortOption",
            newStmtList(resCase)),
          newNimNode(nnkElse).und(newNimNode(nnkNilLit)))))
  
  when defined(Debug):
    echo(repr(result))
 
 
when isMainModule:
  var file : string
  parseOptions:
    on "f", "file":
      file = value
    on "q", "x":
      echo "test"
 
  echo "File is: ", (if file.isNil: "NOT SET!" else: file)
