# A set of recommended compile options.

when not defined(nimscript):
  error("this module should only be used from nimscript")

when defined(sanitizer):
  switch("passC", "-fsanitize=undefined -fsanitize=address")
  switch("passL", "-fsanitize=undefined -fsanitize=address")
  switch("cc", "clang")

switch("threads", "on")
switch("passC", "-g")
switch("passL", "-g")

switch("verbosity", "1")
switch("hint.ConvFromXtoItselfNotNeeded", "off")
switch("hint.XDeclaredButNotUsed", "off")

switch("obj_checks", "on")
switch("field_checks", "on")
switch("bound_checks", "on")

switch("debugger", "native")
