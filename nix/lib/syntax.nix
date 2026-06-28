let
  t = import ./types.nix;

  hasTag = tag: node: builtins.isAttrs node && node ? tag && node.tag == tag;
  mkNode = tag: attrs: attrs // { inherit tag; };

  # Type assertion helper
  assertType =
    funcName: argName: type: val:
    if type.check val then
      val
    else
      throw "TypeError in ${funcName}: Argument '${argName}' expected type '${type.name}', but got: ${builtins.toJSON val}";

  # --- Internal atom and string node builders ---
  mkIntAtom = val: mkNode "Int" { contents = assertType "mkInt" "value" t.intVal val; };
  mkFloatAtom = val: mkNode "Float" { contents = assertType "mkFloat" "value" t.floatVal val; };
  mkBoolAtom = val: mkNode "Bool" { contents = assertType "mkBool" "value" t.boolVal val; };
  mkNullAtom = mkNode "Null" { };
  mkUriAtom = val: mkNode "Uri" { contents = assertType "mkUri" "value" t.textVal val; };

  mkDoubleQuotedNode =
    parts:
    mkNode "DoubleQuoted" {
      contents = assertType "mkDoubleQuoted" "parts" (t.listOf t.AntiquotedText) parts;
    };
  mkIndentedNode =
    indent: parts:
    mkNode "Indented" {
      indent = assertType "mkIndented" "indent" t.intVal indent;
      parts = assertType "mkIndented" "parts" (t.listOf t.AntiquotedText) parts;
    };
in
rec {
  inherit hasTag;

  getExprKind =
    node:
    if builtins.isAttrs node && node ? tag then node.tag else throw "getExprKind: Not an AST node";

  # --- public wrappers for Constants and Strings ---
  mkConstant = atom: mkNode "Constant" { contents = assertType "mkConstant" "atom" t.Atom atom; };
  mkStr = strNode: mkNode "Str" { contents = assertType "mkStr" "strNode" t.String strNode; };

  # --- builders ---
  mkAbs =
    params: body:
    mkNode "Abs" {
      params = assertType "mkAbs" "params" t.Params params;
      body = assertType "mkAbs" "body" t.Expr body;
    };

  mkApp =
    func: arg:
    mkNode "App" {
      func = assertType "mkApp" "func" t.Expr func;
      arg = assertType "mkApp" "arg" t.Expr arg;
    };

  mkAssert =
    cond: body:
    mkNode "Assert" {
      cond = assertType "mkAssert" "cond" t.Expr cond;
      body = assertType "mkAssert" "body" t.Expr body;
    };

  mkBinary =
    op: left: right:
    mkNode "Binary" {
      op = assertType "mkBinary" "op" t.textVal op;
      left = assertType "mkBinary" "left" t.Expr left;
      right = assertType "mkBinary" "right" t.Expr right;
    };

  mkEnvPath = path: mkNode "EnvPath" { contents = assertType "mkEnvPath" "path" t.textVal path; };

  mkHasAttr =
    expr: attrPath:
    mkNode "HasAttr" {
      expr = assertType "mkHasAttr" "expr" t.Expr expr;
      attrPath = assertType "mkHasAttr" "attrPath" (t.listOf t.KeyName) attrPath;
    };

  mkIf =
    cond: thenExpr: elseExpr:
    mkNode "If" {
      cond = assertType "mkIf" "cond" t.Expr cond;
      thenExpr = assertType "mkIf" "thenExpr" t.Expr thenExpr;
      elseExpr = assertType "mkIf" "elseExpr" t.Expr elseExpr;
    };

  mkLet =
    bindings: body:
    mkNode "Let" {
      bindings = assertType "mkLet" "bindings" (t.listOf t.Binding) bindings;
      body = assertType "mkLet" "body" t.Expr body;
    };

  mkList = items: mkNode "List" { contents = assertType "mkList" "items" (t.listOf t.Expr) items; };

  mkLiteralPath =
    path: mkNode "LiteralPath" { contents = assertType "mkLiteralPath" "path" t.textVal path; };

  mkSelect =
    defaultValue: expr: selectPath:
    mkNode "Select" {
      defaultValue = assertType "mkSelect" "defaultValue" (t.maybe t.Expr) defaultValue;
      expr = assertType "mkSelect" "expr" t.Expr expr;
      selectPath = assertType "mkSelect" "selectPath" (t.listOf t.KeyName) selectPath;
    };

  mkSet =
    recursive: bindings:
    mkNode "Set" {
      recursive = assertType "mkSet" "recursive" t.boolVal recursive;
      bindings = assertType "mkSet" "bindings" (t.listOf t.Binding) bindings;
    };

  mkSym = name: mkNode "Sym" { contents = assertType "mkSym" "name" t.textVal name; };

  mkSynHole = name: mkNode "SynHole" { contents = assertType "mkSynHole" "name" t.textVal name; };

  mkUnary =
    op: arg:
    mkNode "Unary" {
      op = assertType "mkUnary" "op" t.textVal op;
      arg = assertType "mkUnary" "arg" t.Expr arg;
    };

  mkWith =
    namespace: body:
    mkNode "With" {
      namespace = assertType "mkWith" "namespace" t.Expr namespace;
      body = assertType "mkWith" "body" t.Expr body;
    };

  # Helpers wrapping atoms into Expr directly
  mkInt = value: mkConstant (mkIntAtom value);
  mkFloat = value: mkConstant (mkFloatAtom value);
  mkBool = value: mkConstant (mkBoolAtom value);
  mkNull = mkConstant mkNullAtom;
  mkUri = value: mkConstant (mkUriAtom value);

  mkInherit =
    scope: names:
    mkNode "Inherit" {
      scope = assertType "mkInherit" "scope" (t.maybe t.Expr) scope;
      names = assertType "mkInherit" "names" (t.listOf t.textVal) names;
    };

  mkNamedVar =
    attrPath: value:
    mkNode "NamedVar" {
      attrPath = assertType "mkNamedVar" "attrPath" (t.listOf t.KeyName) attrPath;
      value = assertType "mkNamedVar" "value" t.Expr value;
    };

  mkDynamicKey =
    content: mkNode "DynamicKey" { contents = assertType "mkDynamicKey" "content" t.String content; };

  mkStaticKey =
    keyName: mkNode "StaticKey" { contents = assertType "mkStaticKey" "keyName" t.textVal keyName; };

  mkParam = name: mkNode "Param" { contents = assertType "mkParam" "name" t.textVal name; };

  mkParamSet =
    paramSetName: params: variadic:
    mkNode "ParamSet" {
      paramSetName = assertType "mkParamSet" "paramSetName" (t.maybe t.textVal) paramSetName;
      params = assertType "mkParamSet" "params" (t.listOf t.anyVal) params; # list of pairs [name, default]
      variadic = assertType "mkParamSet" "variadic" t.boolVal variadic;
    };

  # Helpers wrapping string nodes into Expr directly
  mkDoubleQuoted = parts: mkStr (mkDoubleQuotedNode parts);
  mkIndented = indent: parts: mkStr (mkIndentedNode indent parts);

  mkPlain = content: mkNode "Plain" { contents = assertType "mkPlain" "content" t.textVal content; };
  mkAntiquoted =
    expr: mkNode "Antiquoted" { contents = assertType "mkAntiquoted" "expr" t.Expr expr; };
  mkEscapedNewline = mkNode "EscapedNewline" { };

  # --- predicates ---
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

  # Atoms (rarely directly expressions, but useful predicates)
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
