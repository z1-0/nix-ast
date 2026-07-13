let
  t = import ./types.nix;
  hasTag = tag: node: builtins.isAttrs node && node ? tag && node.tag == tag;
  mkNode = tag: attrs: attrs // { inherit tag; };
  check = fn: field: type: val:
    if type.check val then val
    else throw "TypeError in ${fn}: Argument '${field}' expected type '${type.name}', got: ${builtins.toJSON val}";
in rec {
  inherit hasTag;
  getExprKind = node:
    if builtins.isAttrs node && node ? tag then node.tag
    else throw "getExprKind: Not an AST node";

  # --- String parts ---
  mkDoubleQuoted = parts: mkNode "DoubleQuoted" { contents = check "mkDoubleQuoted" "parts" (t.listOf t.Antiquoted) parts; };
  mkIndented = indent: parts: mkNode "Indented" { indent = check "mkIndented" "indent" t.intVal indent; parts = check "mkIndented" "parts" (t.listOf t.Antiquoted) parts; };

  # --- Atom nodes ---
  mkIntAtom = val: mkNode "Int" { contents = check "mkIntAtom" "value" t.intVal val; };
  mkFloatAtom = val: mkNode "Float" { contents = check "mkFloatAtom" "value" t.floatVal val; };
  mkBoolAtom = val: mkNode "Bool" { contents = check "mkBoolAtom" "value" t.boolVal val; };
  mkNullAtom = mkNode "Null" { };
  mkUriAtom = val: mkNode "Uri" { contents = check "mkUriAtom" "value" t.textVal val; };

  mkConstant = atom: mkNode "Constant" { contents = check "mkConstant" "atom" t.Atom atom; };
  mkInt = value: mkConstant (mkIntAtom value);
  mkFloat = value: mkConstant (mkFloatAtom value);
  mkBool = value: mkConstant (mkBoolAtom value);
  mkNull = mkConstant mkNullAtom;
  mkUri = value: mkConstant (mkUriAtom value);

  # --- Expressions ---
  mkAbs = params: body: mkNode "Abs" { params = check "mkAbs" "params" t.Params params; body = check "mkAbs" "body" t.Expr body; };
  mkApp = func: arg: mkNode "App" { func = check "mkApp" "func" t.Expr func; arg = check "mkApp" "arg" t.Expr arg; };
  mkAssert = cond: body: mkNode "Assert" { cond = check "mkAssert" "cond" t.Expr cond; body = check "mkAssert" "body" t.Expr body; };
  mkBinary = op: left: right: mkNode "Binary" { op = check "mkBinary" "op" t.textVal op; left = check "mkBinary" "left" t.Expr left; right = check "mkBinary" "right" t.Expr right; };
  mkEnvPath = path: mkNode "EnvPath" { contents = check "mkEnvPath" "path" t.textVal path; };
  mkHasAttr = expr: attrPath: mkNode "HasAttr" { expr = check "mkHasAttr" "expr" t.Expr expr; attrPath = check "mkHasAttr" "attrPath" (t.listOf t.KeyName) attrPath; };
  mkIf = cond: thenExpr: elseExpr: mkNode "If" { cond = check "mkIf" "cond" t.Expr cond; thenExpr = check "mkIf" "thenExpr" t.Expr thenExpr; elseExpr = check "mkIf" "elseExpr" t.Expr elseExpr; };
  mkLet = bindings: body: mkNode "Let" { bindings = check "mkLet" "bindings" (t.listOf t.Binding) bindings; body = check "mkLet" "body" t.Expr body; };
  mkList = items: mkNode "List" { contents = check "mkList" "items" (t.listOf t.Expr) items; };
  mkLiteralPath = path: mkNode "LiteralPath" { contents = check "mkLiteralPath" "path" t.textVal path; };
  mkSelect = defaultValue: expr: selectPath: mkNode "Select" { defaultValue = check "mkSelect" "defaultValue" (t.maybe t.Expr) defaultValue; expr = check "mkSelect" "expr" t.Expr expr; selectPath = check "mkSelect" "selectPath" (t.listOf t.KeyName) selectPath; };
  mkSet = recursive: bindings: mkNode "Set" { recursive = check "mkSet" "recursive" t.boolVal recursive; bindings = check "mkSet" "bindings" (t.listOf t.Binding) bindings; };
  mkSym = name: mkNode "Sym" { contents = check "mkSym" "name" t.textVal name; };
  mkSynHole = name: mkNode "SynHole" { contents = check "mkSynHole" "name" t.textVal name; };
  mkUnary = op: arg: mkNode "Unary" { op = check "mkUnary" "op" t.textVal op; arg = check "mkUnary" "arg" t.Expr arg; };
  mkWith = namespace: body: mkNode "With" { namespace = check "mkWith" "namespace" t.Expr namespace; body = check "mkWith" "body" t.Expr body; };

  # --- Bindings & Keys ---
  mkInherit = scope: names: mkNode "Inherit" { scope = check "mkInherit" "scope" (t.maybe t.Expr) scope; names = check "mkInherit" "names" (t.listOf t.textVal) names; };
  mkNamedVar = attrPath: value: mkNode "NamedVar" { attrPath = check "mkNamedVar" "attrPath" (t.listOf t.KeyName) attrPath; value = check "mkNamedVar" "value" t.Expr value; };
  mkDynamicKey = content: mkNode "DynamicKey" { contents = check "mkDynamicKey" "content" t.Antiquoted content; };
  mkStaticKey = keyName: mkNode "StaticKey" { contents = check "mkStaticKey" "keyName" t.textVal keyName; };

  # --- Params ---
  mkParam = name: mkNode "Param" { contents = check "mkParam" "name" t.textVal name; };
  mkParamSet = paramSetName: variadic: params: mkNode "ParamSet" { paramSetName = check "mkParamSet" "paramSetName" (t.maybe t.textVal) paramSetName; variadic = check "mkParamSet" "variadic" t.boolVal variadic; params = check "mkParamSet" "params" (t.listOf t.anyVal) params; };

  # --- String content nodes ---
  mkStr = strNode: mkNode "Str" { contents = check "mkStr" "strNode" t.String strNode; };
  mkPlain = content: mkNode "Plain" { contents = check "mkPlain" "content" (t.either t.textVal t.String) content; };
  mkAntiquoted = expr: mkNode "Antiquoted" { contents = check "mkAntiquoted" "expr" t.Expr expr; };
  mkEscapedNewline = mkNode "EscapedNewline" { };

  # --- Node predicates ---
  isAbs = hasTag "Abs";
  isApp = hasTag "App";
  isAssert = hasTag "Assert";
  isBinary = hasTag "Binary";
  isConstant = hasTag "Constant";
  isEnvPath = hasTag "EnvPath";
  isHasAttr = hasTag "HasAttr";
  isIf = hasTag "If";
  isLet = hasTag "Let";
  isList = hasTag "List";
  isLiteralPath = hasTag "LiteralPath";
  isSelect = hasTag "Select";
  isSet = hasTag "Set";
  isStr = hasTag "Str";
  isSym = hasTag "Sym";
  isSynHole = hasTag "SynHole";
  isUnary = hasTag "Unary";
  isWith = hasTag "With";
  isInt = hasTag "Int";
  isFloat = hasTag "Float";
  isBool = hasTag "Bool";
  isNull = hasTag "Null";
  isUri = hasTag "Uri";
  isInherit = hasTag "Inherit";
  isNamedVar = hasTag "NamedVar";
  isDynamicKey = hasTag "DynamicKey";
  isStaticKey = hasTag "StaticKey";
  isParam = hasTag "Param";
  isParamSet = hasTag "ParamSet";
  isDoubleQuoted = hasTag "DoubleQuoted";
  isIndented = hasTag "Indented";
  isPlain = hasTag "Plain";
  isAntiquoted = hasTag "Antiquoted";
  isEscapedNewline = hasTag "EscapedNewline";
}
