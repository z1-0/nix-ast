{
  mkAbs = params: body: { tag = "Abs"; inherit params body; };
  mkApp = func: arg: { tag = "App"; inherit func arg; };
  mkAssert = cond: body: { tag = "Assert"; inherit cond body; };
  mkBinary = op: left: right: { tag = "Binary"; inherit op left right; };
  mkConstant = atom: { tag = "Constant"; inherit atom; };
  mkEnvPath = path: { tag = "EnvPath"; inherit path; };
  mkHasAttr = expr: attrPath: { tag = "HasAttr"; inherit expr attrPath; };
  mkIf = cond: then_: else_: { tag = "If"; inherit cond; "then" = then_; "else" = else_; };
  mkLet = bindings: body: { tag = "Let"; inherit bindings body; };
  mkList = items: { tag = "List"; inherit items; };
  mkLiteralPath = path: { tag = "LiteralPath"; inherit path; };
  mkSelect = expr: selectPath: _default: { tag = "Select"; inherit expr selectPath _default; };
  mkSet = rec_: bindings: { tag = "Set"; "rec" = rec_; inherit bindings; };
  mkStr = str: { tag = "Str"; inherit str; };
  mkSym = name: { tag = "Sym"; inherit name; };
  mkSynHole = name: { tag = "SynHole"; inherit name; };
  mkUnary = op: arg: { tag = "Unary"; inherit op arg; };
  mkWith = namespace: body: { tag = "With"; inherit namespace body; };

  mkInherit = scope: names: { tag = "Inherit"; inherit scope names; };
  mkNamedVar = attrPath: value: { tag = "NamedVar"; inherit attrPath value; };

  mkParam = paramName: { tag = "Single"; inherit paramName; };
  mkParamSet = paramArgs: paramList: variadic: { tag = "ParamSet"; inherit paramArgs paramList variadic; };

  getExprKind = node: node.tag;

  isAbs = node: node ? tag && node.tag == "Abs";
  isApp = node: node ? tag && node.tag == "App";
  isAssert = node: node ? tag && node.tag == "Assert";
  isBinary = node: node ? tag && node.tag == "Binary";
  isConstant = node: node ? tag && node.tag == "Constant";
  isEnvPath = node: node ? tag && node.tag == "EnvPath";
  isHasAttr = node: node ? tag && node.tag == "HasAttr";
  isIf = node: node ? tag && node.tag == "If";
  isLet = node: node ? tag && node.tag == "Let";
  isList = node: node ? tag && node.tag == "List";
  isLiteralPath = node: node ? tag && node.tag == "LiteralPath";
  isSelect = node: node ? tag && node.tag == "Select";
  isSet = node: node ? tag && node.tag == "Set";
  isStr = node: node ? tag && node.tag == "Str";
  isSym = node: node ? tag && node.tag == "Sym";
  isSynHole = node: node ? tag && node.tag == "SynHole";
  isUnary = node: node ? tag && node.tag == "Unary";
  isWith = node: node ? tag && node.tag == "With";

  getInheritScope = node: node.scope;
  getInheritNames = node: node.names;
  getNamedVarAttrPath = node: node.attrPath;
  getNamedVarValue = node: node.value;

  getAppFunc = node: node.func;
  getAppArg = node: node.arg;
  getAbsParams = node: node.params;
  getAbsBody = node: node.body;
  getAssertCond = node: node.cond;
  getAssertBody = node: node.body;
  getBinaryOp = node: node.op;
  getBinaryLeft = node: node.left;
  getBinaryRight = node: node.right;
  getConstantAtom = node: node.atom;
  getEnvPathPath = node: node.path;
  getHasAttrExpr = node: node.expr;
  getHasAttrPath = node: node.path;
  getIfCond = node: node.cond;
  getIfThen = node: node."then";
  getIfElse = node: node."else";
  getLetBindings = node: node.bindings;
  getLetBody = node: node.body;
  getListItems = node: node.items;
  getLiteralPathPath = node: node.path;
  getSelectExpr = node: node.expr;
  getSelectPath = node: node.path;
  getSelectDefault = node: node.default;
  getSetRec = node: node."rec";
  getSetBindings = node: node.bindings;
  getStrStr = node: node.str;
  getSymName = node: node.name;
  getSynHoleName = node: node.name;
  getUnaryOp = node: node.op;
  getUnaryArg = node: node.arg;
  getWithNamespace = node: node.namespace;
  getWithBody = node: node.body;
}
