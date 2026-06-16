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

  allTests = [
    # syntax: constructors
    (check "mkSym" (s.getExprKind (sym "x") == "Sym"))
    (check "mkApp" (s.getExprKind (s.mkApp (sym "f") (sym "x")) == "App"))
    (check "mkIf" (s.getExprKind (s.mkIf (s.mkConstant { tag = "Bool"; contents = true; }) (sym "a") (sym "b")) == "If"))
    (check "mkLet" (s.getExprKind (s.mkLet [] (sym "x")) == "Let"))
    (check "mkList" (s.getExprKind (s.mkList []) == "List"))
    (check "mkSet" (s.getExprKind (s.mkSet false []) == "Set"))
    (check "mkStr" (s.getExprKind (s.mkStr [{ tag = "Plain"; contents = "hi"; }]) == "Str"))
    (check "mkBinary" (s.getExprKind (s.mkBinary "+" (s.mkConstant { tag = "Int"; contents = 1; }) (s.mkConstant { tag = "Int"; contents = 2; })) == "Binary"))
    (check "mkWith" (s.getExprKind (s.mkWith (sym "pkgs") (sym "x")) == "With"))
    (check "mkAssert" (s.getExprKind (s.mkAssert (s.mkConstant { tag = "Bool"; contents = true; }) (sym "x")) == "Assert"))
    (check "mkUnary" (s.getExprKind (s.mkUnary "!" (s.mkConstant { tag = "Bool"; contents = true; })) == "Unary"))
    (check "mkInherit" (s.getExprKind (s.mkInherit null ["x"]) == "Inherit"))
    (check "mkNamedVar" (s.getExprKind (s.mkNamedVar [{ tag = "StaticKey"; contents = "x"; }] (sym "x")) == "NamedVar"))
    (check "mkParam" (s.getExprKind (s.mkParam "x") == "Single"))
    (check "mkParamSet" (s.getExprKind (s.mkParamSet null [] false) == "ParamSet"))

    # syntax: predicates
    (check "isSym" (s.isSym (sym "x")))
    (check "isSym reject" (! (s.isSym (s.mkApp (sym "f") (sym "x")))))
    (check "isApp" (s.isApp (s.mkApp (sym "f") (sym "x"))))
    (check "isLet" (s.isLet (s.mkLet [] (sym "x"))))
    (check "isList" (s.isList (s.mkList [])))
    (check "isStr" (s.isStr (s.mkStr [{ tag = "Plain"; contents = "hi"; }])))
    (check "isBinary" (s.isBinary (s.mkBinary "+" (sym "a") (sym "b"))))
    (check "isIf" (s.isIf (s.mkIf (sym "c") (sym "t") (sym "f"))))
    (check "isWith" (s.isWith (s.mkWith (sym "ns") (sym "x"))))
    (check "isSet" (s.isSet (s.mkSet false [])))

    # syntax: accessors
    (check "getAppFunc" (s.getSymName (s.getAppFunc (s.mkApp (sym "f") (sym "x"))) == "f"))
    (check "getAppArg" (s.getSymName (s.getAppArg (s.mkApp (sym "f") (sym "x"))) == "x"))
    (check "getIfCond" (s.isSym (s.getIfCond (s.mkIf (sym "c") (sym "t") (sym "f")))))
    (check "getIfThen" (s.getSymName (s.getIfThen (s.mkIf (sym "c") (sym "t") (sym "f"))) == "t"))
    (check "getIfElse" (s.getSymName (s.getIfElse (s.mkIf (sym "c") (sym "t") (sym "f"))) == "f"))
    (check "getBinaryOp" (s.getBinaryOp (s.mkBinary "+" (sym "a") (sym "b")) == "+"))
    (check "getBinaryLeft" (s.getSymName (s.getBinaryLeft (s.mkBinary "+" (sym "a") (sym "b"))) == "a"))
    (check "getBinaryRight" (s.getSymName (s.getBinaryRight (s.mkBinary "+" (sym "a") (sym "b"))) == "b"))
    (check "getLetBody" (s.getSymName (s.getLetBody (s.mkLet [] (sym "x"))) == "x"))
    (check "getListItems" (builtins.length (s.getListItems (s.mkList [(sym "a") (sym "b")])) == 2))
    (check "getSymName" (s.getSymName (sym "test") == "test"))
    (check "getNamedVarValue" (s.isSym (s.getNamedVarValue (s.mkNamedVar [{ tag = "StaticKey"; contents = "x"; }] (sym "v")))))

    # core: children
    (check "children App" (builtins.length (c.children (s.mkApp (sym "f") (sym "x"))) == 2))
    (check "children If" (builtins.length (c.children (s.mkIf (sym "c") (sym "t") (sym "f"))) == 3))
    (check "children Sym" (builtins.length (c.children (sym "x")) == 0))
    (check "children List" (builtins.length (c.children (s.mkList [(sym "a") (sym "b") (sym "c")])) == 3))

    # core: map
    (check "map" (s.getSymName (s.getAppFunc (c.map (n: if s.isSym n then sym "y" else n) (s.mkApp (sym "f") (sym "x")))) == "y"))

    # core: rewrite
    (check "rewrite" (s.getSymName (s.getAppFunc (c.rewrite (n: if s.isSym n then sym "z" else n) (s.mkApp (sym "f") (sym "x")))) == "z"))

    # core: find
    (check "find match" (builtins.length (c.find s.isSym (s.mkApp (sym "f") (sym "x"))) == 2))
    (check "find empty" (builtins.length (c.find s.isIf (s.mkApp (sym "f") (sym "x"))) == 0))

    # core: fold
    (check "fold" (c.fold 0 (acc: n: acc + 1) (s.mkApp (sym "f") (sym "x")) == 3))

    # core: any
    (check "any true" (c.any s.isSym (s.mkApp (sym "f") (sym "x"))))
    (check "any false" (! (c.any s.isIf (s.mkApp (sym "f") (sym "x")))))

    # core: all
    (check "all Sym in Sym tree" (c.all s.isSym (sym "x")))
    (check "all Sym in If tree" (! (c.all s.isSym (s.mkIf (sym "c") (sym "t") (sym "f")))))

    # core: count
    (check "count" (c.count s.isSym (s.mkApp (sym "f") (sym "x")) == 2))

    # pass: rename
    (check "rename" (s.getSymName (s.getAppFunc (p.rename "x" "y" (s.mkApp (sym "x") (sym "x")))) == "y"))
    (check "rename preserve" (s.getSymName (s.getAppFunc (p.rename "x" "y" (s.mkApp (sym "a") (sym "b")))) == "a"))

    # pass: replaceString
    (check "replaceString" ((builtins.head (s.getStrStr (p.replaceString "world" "nix" (s.mkStr [{ tag = "Plain"; contents = "hello world"; }])))).contents == "hello nix"))

    # pass: wrapWith
    (check "wrapWith" (s.getExprKind (p.wrapWith "pkgs" (sym "x")) == "With"))

    # pass: addOverrides
    (check "addOverrides" (builtins.length (s.getSetBindings (p.addOverrides [(s.mkNamedVar [{ tag = "StaticKey"; contents = "b"; }] (sym "2"))] (s.mkSet false [(s.mkNamedVar [{ tag = "StaticKey"; contents = "a"; }] (sym "1"))]))) == 2))

    # pass: removeBindings
    (check "removeBindings" (builtins.length (s.getLetBindings (p.removeBindings ["x"] (s.mkLet [(s.mkNamedVar [{ tag = "StaticKey"; contents = "x"; }] (sym "1")) (s.mkNamedVar [{ tag = "StaticKey"; contents = "y"; }] (sym "2"))] (sym "x")))) == 1))

    # pass: hoistLet
    (check "hoistLet" (builtins.length (s.getLetBindings (p.hoistLet (s.mkLet [(s.mkNamedVar [{ tag = "StaticKey"; contents = "x"; }] (sym "1"))] (s.mkLet [(s.mkNamedVar [{ tag = "StaticKey"; contents = "y"; }] (sym "2"))] (sym "y"))))) == 2))

    # analysis: depth
    (check "depth 1" (a.depth (sym "x") == 1))
    (check "depth 2" (a.depth (s.mkApp (sym "f") (sym "x")) == 2))
    (check "depth 3" (a.depth (s.mkApp (sym "f") (s.mkApp (sym "g") (sym "x"))) == 3))

    # analysis: size
    (check "size 1" (a.size (sym "x") == 1))
    (check "size 3" (a.size (s.mkApp (sym "f") (sym "x")) == 3))
    (check "size list" (a.size (s.mkList [(sym "a") (sym "b")]) == 3))

    # analysis: allStrings
    (check "allStrings" (a.allStrings (s.mkList [(s.mkStr [{ tag = "Plain"; contents = "a"; }]) (s.mkStr [{ tag = "Plain"; contents = "b"; }])]) == ["a" "b"]))
    (check "allStrings empty" (a.allStrings (s.mkApp (sym "f") (sym "x")) == []))

    # analysis: allPaths
    (check "allPaths" (builtins.length (a.allPaths (s.mkList [(s.mkLiteralPath "./foo.nix") (s.mkEnvPath "nixpkgs")])) == 2))
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
