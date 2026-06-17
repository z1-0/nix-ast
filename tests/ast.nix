# tests/ast.nix — Nix AST API tests
# Run: nix-instantiate --eval tests/ast.nix 2>&1
let
  s = import ../lib/ast/syntax.nix;
  c = import ../lib/ast/core.nix;
  p = import ../lib/ast/pass.nix;
  a = import ../lib/ast/analysis.nix;

  check = name: cond:
    if cond then { inherit name; pass = true; }
    else { inherit name; pass = false; };

  sym = name: s.mkSym name;
  str_ = content: s.mkStr [{ tag = "Plain"; contents = content; }];
  sk = name: { tag = "StaticKey"; contents = name; };
  nv = name: val: s.mkNamedVar [(sk name)] val;

  allTests = [
    # ═══ syntax: constructors (20) ═══
    (check "mkAbs" (s.getExprKind (s.mkAbs (s.mkParam "x") (sym "x")) == "Abs"))
    (check "mkApp" (s.getExprKind (s.mkApp (sym "f") (sym "x")) == "App"))
    (check "mkAssert" (s.getExprKind (s.mkAssert (sym "c") (sym "x")) == "Assert"))
    (check "mkBinary" (s.getExprKind (s.mkBinary "+" (sym "a") (sym "b")) == "Binary"))
    (check "mkConstant" (s.getExprKind (s.mkConstant { tag = "Int"; contents = 42; }) == "Constant"))
    (check "mkEnvPath" (s.getExprKind (s.mkEnvPath "nixpkgs") == "EnvPath"))
    (check "mkHasAttr" (s.getExprKind (s.mkHasAttr (sym "x") [(sk "y")]) == "HasAttr"))
    (check "mkIf" (s.getExprKind (s.mkIf (sym "c") (sym "t") (sym "f")) == "If"))
    (check "mkLet" (s.getExprKind (s.mkLet [] (sym "x")) == "Let"))
    (check "mkList" (s.getExprKind (s.mkList []) == "List"))
    (check "mkLiteralPath" (s.getExprKind (s.mkLiteralPath "./foo.nix") == "LiteralPath"))
    (check "mkSelect" (s.getExprKind (s.mkSelect (sym "x") [(sk "y")] null) == "Select"))
    (check "mkSet" (s.getExprKind (s.mkSet false []) == "Set"))
    (check "mkStr" (s.getExprKind (str_ "hi") == "Str"))
    (check "mkSym" (s.getExprKind (sym "x") == "Sym"))
    (check "mkSynHole" (s.getExprKind (s.mkSynHole "a") == "SynHole"))
    (check "mkUnary" (s.getExprKind (s.mkUnary "!" (sym "x")) == "Unary"))
    (check "mkWith" (s.getExprKind (s.mkWith (sym "ns") (sym "x")) == "With"))
    (check "mkInherit" (s.getExprKind (s.mkInherit null ["x"]) == "Inherit"))
    (check "mkNamedVar" (s.getExprKind (nv "x" (sym "x")) == "NamedVar"))
    (check "mkParam" (s.getExprKind (s.mkParam "x") == "Single"))
    (check "mkParamSet" (s.getExprKind (s.mkParamSet null [] false) == "ParamSet"))

    # ═══ syntax: predicates (20) ═══
    (check "isAbs" (s.isAbs (s.mkAbs (s.mkParam "x") (sym "x"))))
    (check "isApp" (s.isApp (s.mkApp (sym "f") (sym "x"))))
    (check "isAssert" (s.isAssert (s.mkAssert (sym "c") (sym "x"))))
    (check "isBinary" (s.isBinary (s.mkBinary "+" (sym "a") (sym "b"))))
    (check "isConstant" (s.isConstant (s.mkConstant { tag = "Int"; contents = 1; })))
    (check "isEnvPath" (s.isEnvPath (s.mkEnvPath "nixpkgs")))
    (check "isHasAttr" (s.isHasAttr (s.mkHasAttr (sym "x") [(sk "y")])))
    (check "isIf" (s.isIf (s.mkIf (sym "c") (sym "t") (sym "f"))))
    (check "isLet" (s.isLet (s.mkLet [] (sym "x"))))
    (check "isList" (s.isList (s.mkList [])))
    (check "isLiteralPath" (s.isLiteralPath (s.mkLiteralPath "./foo.nix")))
    (check "isSelect" (s.isSelect (s.mkSelect (sym "x") [(sk "y")] null)))
    (check "isSet" (s.isSet (s.mkSet false [])))
    (check "isStr" (s.isStr (str_ "hi")))
    (check "isSym" (s.isSym (sym "x")))
    (check "isSynHole" (s.isSynHole (s.mkSynHole "a")))
    (check "isUnary" (s.isUnary (s.mkUnary "!" (sym "x"))))
    (check "isWith" (s.isWith (s.mkWith (sym "ns") (sym "x"))))
    (check "isNamedVar" (s.isNamedVar (nv "x" (sym "x"))))
    (check "isSym reject" (! (s.isSym (s.mkApp (sym "f") (sym "x")))))

    # ═══ syntax: accessors (36) ═══
    (check "getInheritScope" (s.getInheritScope (s.mkInherit null ["x"]) == null))
    (check "getInheritNames" (s.getInheritNames (s.mkInherit null ["x"]) == ["x"]))
    (check "getNamedVarAttrPath" (builtins.length (s.getNamedVarAttrPath (nv "x" (sym "x"))) == 1))
    (check "getNamedVarValue" (s.isSym (s.getNamedVarValue (nv "x" (sym "v")))))
    (check "getAbsParams" (s.getExprKind (s.getAbsParams (s.mkAbs (s.mkParam "x") (sym "x"))) == "Single"))
    (check "getAbsBody" (s.isSym (s.getAbsBody (s.mkAbs (s.mkParam "x") (sym "x")))))
    (check "getAppFunc" (s.getSymName (s.getAppFunc (s.mkApp (sym "f") (sym "x"))) == "f"))
    (check "getAppArg" (s.getSymName (s.getAppArg (s.mkApp (sym "f") (sym "x"))) == "x"))
    (check "getAssertCond" (s.isSym (s.getAssertCond (s.mkAssert (sym "c") (sym "x")))))
    (check "getAssertBody" (s.isSym (s.getAssertBody (s.mkAssert (sym "c") (sym "x")))))
    (check "getBinaryOp" (s.getBinaryOp (s.mkBinary "+" (sym "a") (sym "b")) == "+"))
    (check "getBinaryLeft" (s.getSymName (s.getBinaryLeft (s.mkBinary "+" (sym "a") (sym "b"))) == "a"))
    (check "getBinaryRight" (s.getSymName (s.getBinaryRight (s.mkBinary "+" (sym "a") (sym "b"))) == "b"))
    (check "getConstantAtom" (s.getConstantAtom (s.mkConstant { tag = "Int"; contents = 42; }) == { tag = "Int"; contents = 42; }))
    (check "getEnvPathPath" (s.getEnvPathPath (s.mkEnvPath "nixpkgs") == "nixpkgs"))
    (check "getHasAttrExpr" (s.isSym (s.getHasAttrExpr (s.mkHasAttr (sym "x") [(sk "y")]))))
    (check "getHasAttrPath" (builtins.length (s.getHasAttrPath (s.mkHasAttr (sym "x") [(sk "y")])) == 1))
    (check "getIfCond" (s.isSym (s.getIfCond (s.mkIf (sym "c") (sym "t") (sym "f")))))
    (check "getIfThen" (s.getSymName (s.getIfThen (s.mkIf (sym "c") (sym "t") (sym "f"))) == "t"))
    (check "getIfElse" (s.getSymName (s.getIfElse (s.mkIf (sym "c") (sym "t") (sym "f"))) == "f"))
    (check "getLetBindings" (builtins.length (s.getLetBindings (s.mkLet [(nv "x" (sym "1"))] (sym "x"))) == 1))
    (check "getLetBody" (s.getSymName (s.getLetBody (s.mkLet [] (sym "x"))) == "x"))
    (check "getListItems" (builtins.length (s.getListItems (s.mkList [(sym "a") (sym "b")])) == 2))
    (check "getLiteralPathPath" (s.getLiteralPathPath (s.mkLiteralPath "./foo.nix") == "./foo.nix"))
    (check "getSelectExpr" (s.isSym (s.getSelectExpr (s.mkSelect (sym "x") [(sk "y")] null))))
    (check "getSelectPath" (builtins.length (s.getSelectPath (s.mkSelect (sym "x") [(sk "y")] null)) == 1))
    (check "getSelectDefault" (s.getSelectDefault (s.mkSelect (sym "x") [(sk "y")] null) == null))
    (check "getSetRec" (s.getSetRec (s.mkSet true []) == true))
    (check "getSetBindings" (builtins.length (s.getSetBindings (s.mkSet false [(nv "a" (sym "1"))])) == 1))
    (check "getStrStr" (builtins.isList (s.getStrStr (str_ "hello"))))
    (check "getSymName" (s.getSymName (sym "test") == "test"))
    (check "getSynHoleName" (s.getSynHoleName (s.mkSynHole "a") == "a"))
    (check "getUnaryOp" (s.getUnaryOp (s.mkUnary "!" (sym "x")) == "!"))
    (check "getUnaryArg" (s.isSym (s.getUnaryArg (s.mkUnary "!" (sym "x")))))
    (check "getWithNamespace" (s.isSym (s.getWithNamespace (s.mkWith (sym "ns") (sym "x")))))
    (check "getWithBody" (s.isSym (s.getWithBody (s.mkWith (sym "ns") (sym "x")))))

    # ═══ core: children (20 types) ═══
    (check "children Abs" (builtins.length (c.children (s.mkAbs (s.mkParam "x") (sym "x"))) == 1))
    (check "children App" (builtins.length (c.children (s.mkApp (sym "f") (sym "x"))) == 2))
    (check "children Assert" (builtins.length (c.children (s.mkAssert (sym "c") (sym "x"))) == 2))
    (check "children Binary" (builtins.length (c.children (s.mkBinary "+" (sym "a") (sym "b"))) == 2))
    (check "children Constant" (builtins.length (c.children (s.mkConstant { tag = "Int"; contents = 1; })) == 0))
    (check "children EnvPath" (builtins.length (c.children (s.mkEnvPath "nixpkgs")) == 0))
    (check "children HasAttr" (builtins.length (c.children (s.mkHasAttr (sym "x") [(sk "y")])) == 1))
    (check "children If" (builtins.length (c.children (s.mkIf (sym "c") (sym "t") (sym "f"))) == 3))
    (check "children Let" (builtins.length (c.children (s.mkLet [] (sym "x"))) == 1))
    (check "children List" (builtins.length (c.children (s.mkList [(sym "a") (sym "b") (sym "c")])) == 3))
    (check "children LiteralPath" (builtins.length (c.children (s.mkLiteralPath "./foo.nix")) == 0))
    (check "children Select no default" (builtins.length (c.children (s.mkSelect (sym "x") [(sk "y")] null)) == 1))
    (check "children Select with default" (builtins.length (c.children (s.mkSelect (sym "x") [(sk "y")] (sym "d"))) == 2))
    (check "children Set" (builtins.length (c.children (s.mkSet false [(nv "a" (sym "1")) (nv "b" (sym "2"))])) == 2))
    (check "children Str no interp" (builtins.length (c.children (str_ "hello")) == 0))
    (check "children Str with interp" (builtins.length (c.children (s.mkStr [{ tag = "Interpolation"; expr = sym "x"; }])) == 1))
    (check "children Sym" (builtins.length (c.children (sym "x")) == 0))
    (check "children SynHole" (builtins.length (c.children (s.mkSynHole "a")) == 0))
    (check "children Unary" (builtins.length (c.children (s.mkUnary "!" (sym "x"))) == 1))
    (check "children With" (builtins.length (c.children (s.mkWith (sym "ns") (sym "x"))) == 2))

    # ═══ core: map ═══
    (check "map transforms children" (s.getSymName (s.getAppFunc (c.map (n: if s.isSym n then sym "y" else n) (s.mkApp (sym "f") (sym "x")))) == "y"))
    (check "map leaf" (s.getSymName (c.map (n: if s.isSym n then sym "z" else n) (sym "x")) == "z"))

    # ═══ core: rewrite ═══
    (check "rewrite bottom-up" (s.getSymName (s.getAppFunc (c.rewrite (n: if s.isSym n then sym "z" else n) (s.mkApp (sym "f") (sym "x")))) == "z"))

    # ═══ core: rewriteTopDown ═══
    (check "rewriteTopDown match" (s.getSymName (s.getAppFunc (c.rewriteTopDown s.isSym (n: s.mkSym "y") (s.mkApp (sym "f") (sym "x")))) == "y"))
    (check "rewriteTopDown no match" (s.getExprKind (c.rewriteTopDown s.isIf (n: s.mkSym "y") (s.mkApp (sym "f") (sym "x"))) == "App"))

    # ═══ core: find ═══
    (check "find match" (builtins.length (c.find s.isSym (s.mkApp (sym "f") (sym "x"))) == 2))
    (check "find empty" (builtins.length (c.find s.isIf (s.mkApp (sym "f") (sym "x"))) == 0))
    (check "find nested" (builtins.length (c.find s.isSym (s.mkLet [(nv "a" (sym "1"))] (s.mkApp (sym "f") (sym "x")))) == 2))

    # ═══ core: findFirst ═══
    (check "findFirst match" (s.getExprKind (c.findFirst s.isSym (s.mkApp (sym "f") (sym "x"))) == "Sym"))
    (check "findFirst empty" (c.findFirst s.isIf (s.mkApp (sym "f") (sym "x")) == null))

    # ═══ core: collect ═══
    (check "collect" (builtins.length (c.collect (n: if s.isSym n then s.getSymName n else null) (s.mkApp (sym "f") (sym "x"))) == 2))

    # ═══ core: fold ═══
    (check "fold count" (c.fold 0 (acc: n: acc + 1) (s.mkApp (sym "f") (sym "x")) == 3))
    (check "fold concat" (builtins.length (c.fold [] (acc: n: acc ++ (if s.isSym n then [n] else [])) (s.mkApp (sym "f") (sym "x"))) == 2))

    # ═══ core: filter ═══
    (check "filter" (builtins.length (c.filter s.isSym (s.mkApp (sym "f") (sym "x"))) == 2))
    (check "filter empty" (builtins.length (c.filter s.isIf (s.mkApp (sym "f") (sym "x"))) == 0))

    # ═══ core: any ═══
    (check "any true" (c.any s.isSym (s.mkApp (sym "f") (sym "x"))))
    (check "any false" (! (c.any s.isIf (s.mkApp (sym "f") (sym "x")))))
    (check "any leaf" (c.any s.isSym (sym "x")))
    (check "any leaf false" (! (c.any s.isIf (sym "x"))))

    # ═══ core: all ═══
    (check "all true" (c.all s.isSym (sym "x")))
    (check "all false" (! (c.all s.isSym (s.mkIf (sym "c") (sym "t") (sym "f")))))

    # ═══ core: count ═══
    (check "count match" (c.count s.isSym (s.mkApp (sym "f") (sym "x")) == 2))
    (check "count empty" (c.count s.isIf (s.mkApp (sym "f") (sym "x")) == 0))

    # ═══ pass: rename ═══
    (check "rename match" (s.getSymName (s.getAppFunc (p.rename "x" "y" (s.mkApp (sym "x") (sym "x")))) == "y"))
    (check "rename no match" (s.getSymName (s.getAppFunc (p.rename "x" "y" (s.mkApp (sym "a") (sym "b")))) == "a"))
    (check "rename nested" (s.getSymName (s.getLetBody (p.rename "x" "z" (s.mkLet [(nv "x" (sym "1"))] (sym "x")))) == "z"))

    # ═══ pass: replaceString ═══
    (check "replaceString" ((builtins.head (s.getStrStr (p.replaceString "world" "nix" (str_ "hello world")))).contents == "hello nix"))
    (check "replaceString no match" ((builtins.head (s.getStrStr (p.replaceString "xyz" "abc" (str_ "hello")))).contents == "hello"))

    # ═══ pass: wrapWith ═══
    (check "wrapWith" (s.getExprKind (p.wrapWith "pkgs" (sym "x")) == "With"))

    # ═══ pass: addOverrides ═══
    (check "addOverrides" (builtins.length (s.getSetBindings (p.addOverrides [(nv "b" (sym "2"))] (s.mkSet false [(nv "a" (sym "1"))]))) == 2))
    (check "addOverrides non-set" (s.getExprKind (p.addOverrides [(nv "b" (sym "2"))] (sym "x")) == "Sym"))

    # ═══ pass: removeBindings ═══
    (check "removeBindings let" (builtins.length (s.getLetBindings (p.removeBindings ["x"] (s.mkLet [(nv "x" (sym "1")) (nv "y" (sym "2"))] (sym "x")))) == 1))
    (check "removeBindings set" (builtins.length (s.getSetBindings (p.removeBindings ["a"] (s.mkSet false [(nv "a" (sym "1")) (nv "b" (sym "2"))]))) == 1))
    (check "removeBindings non-matching" (builtins.length (s.getLetBindings (p.removeBindings ["z"] (s.mkLet [(nv "x" (sym "1"))] (sym "x")))) == 1))

    # ═══ pass: inline ═══
    (check "inline single use" (s.getSymName (p.inline "x" (s.mkLet [(nv "x" (sym "42"))] (sym "x"))) == "42"))
    (check "inline multi use" (s.getExprKind (p.inline "x" (s.mkLet [(nv "x" (sym "42"))] (s.mkApp (sym "x") (sym "x")))) == "Let"))

    # ═══ pass: hoistLet ═══
    (check "hoistLet nested" (builtins.length (s.getLetBindings (p.hoistLet (s.mkLet [(nv "x" (sym "1"))] (s.mkLet [(nv "y" (sym "2"))] (sym "y"))))) == 2))
    (check "hoistLet no nested" (s.getExprKind (p.hoistLet (s.mkLet [(nv "x" (sym "1"))] (sym "x"))) == "Let"))

    # ═══ pass: flattenSets ═══
    (check "flattenSets binary" (s.getExprKind (p.flattenSets (s.mkBinary "//" (s.mkSet false [(nv "a" (sym "1"))]) (s.mkSet false [(nv "b" (sym "2"))]))) == "Binary"))
    (check "flattenSets non-binary" (s.getExprKind (p.flattenSets (s.mkSet false [])) == "Set"))

    # ═══ analysis: depth ═══
    (check "depth leaf" (a.depth (sym "x") == 1))
    (check "depth 2" (a.depth (s.mkApp (sym "f") (sym "x")) == 2))
    (check "depth 3" (a.depth (s.mkApp (sym "f") (s.mkApp (sym "g") (sym "x"))) == 3))
    (check "depth list" (a.depth (s.mkList [(sym "a") (sym "b")]) == 2))

    # ═══ analysis: size ═══
    (check "size leaf" (a.size (sym "x") == 1))
    (check "size app" (a.size (s.mkApp (sym "f") (sym "x")) == 3))
    (check "size list" (a.size (s.mkList [(sym "a") (sym "b")]) == 3))
    (check "size nested" (a.size (s.mkApp (sym "f") (s.mkApp (sym "g") (sym "x"))) == 5))

    # ═══ analysis: allStrings ═══
    (check "allStrings" (a.allStrings (s.mkList [(str_ "a") (str_ "b")]) == ["a" "b"]))
    (check "allStrings empty" (a.allStrings (s.mkApp (sym "f") (sym "x")) == []))
    (check "allStrings nested" (builtins.length (a.allStrings (s.mkIf (sym "c") (str_ "hello") (sym "x"))) == 1))

    # ═══ analysis: allPaths ═══
    (check "allPaths literal" (builtins.length (a.allPaths (s.mkList [(s.mkLiteralPath "./foo.nix") (s.mkEnvPath "nixpkgs")])) == 2))
    (check "allPaths empty" (a.allPaths (sym "x") == []))
    (check "allPaths literal only" (a.allPaths (s.mkLiteralPath "./a.nix") == ["./a.nix"]))

    # ═══ analysis: freeVars ═══
    (check "freeVars simple" (builtins.elem "x" (a.freeVars (sym "x"))))
    (check "freeVars bound" (! (builtins.elem "x" (a.freeVars (s.mkLet [(nv "x" (sym "1"))] (sym "x"))))))
    (check "freeVars mixed" (builtins.elem "y" (a.freeVars (s.mkLet [(nv "x" (sym "1"))] (s.mkApp (sym "x") (sym "y"))))))

    # ═══ analysis: boundVars ═══
    (check "boundVars let" (builtins.elem "x" (a.boundVars (s.mkLet [(nv "x" (sym "1"))] (sym "x")))))
    (check "boundVars abs" (builtins.elem "x" (a.boundVars (s.mkAbs (s.mkParam "x") (sym "x")))))
    (check "boundVars empty" (a.boundVars (sym "x") == []))
  ];

  failed = map (t: t.name) (builtins.filter (t: !t.pass) allTests);
  total = builtins.length allTests;
  failCount = builtins.length failed;
in
  if failCount == 0 then
    builtins.trace "ALL ${toString total} TESTS PASSED" true
  else
    builtins.trace "${toString failCount}/${toString total} TESTS FAILED:" false
    // builtins.trace (builtins.concatStringsSep "\n" failed) false
