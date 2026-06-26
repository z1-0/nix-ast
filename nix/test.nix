let
  lib = import ./lib/default.nix {
    pkgs = import <nixpkgs> {};
    packages = {}; # Not needed for pure nix tests
  };
  s = lib.syntax;
  t = lib.traversal;
  inherit (lib) match;

  check = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else {
      inherit name;
      pass = false;
    };

  sym = name: s.mkSym name;
  nv = name: val: s.mkNamedVar [(s.mkStaticKey name)] val;

  throwsError = expr: !(builtins.tryEval (builtins.deepSeq expr expr)).success;

  allTests = [
    # ═══ 1. syntax: constructors (Outer Tag Alignment) ═══
    (check "mkAbs" (s.getExprKind (s.mkAbs (s.mkParam "x") (sym "x")) == "Abs"))
    (check "mkApp" (s.getExprKind (s.mkApp (sym "f") (sym "x")) == "App"))
    (check "mkAssert" (s.getExprKind (s.mkAssert (sym "c") (sym "x")) == "Assert"))
    (check "mkBinary" (s.getExprKind (s.mkBinary "+" (sym "a") (sym "b")) == "Binary"))
    (check "mkInt" (s.getExprKind (s.mkInt 42) == "Constant")) # Wrapped in Constant
    (check "mkFloat" (s.getExprKind (s.mkFloat 3.14) == "Constant")) # Wrapped in Constant
    (check "mkBool" (s.getExprKind (s.mkBool true) == "Constant")) # Wrapped in Constant
    (check "mkNull" (s.getExprKind s.mkNull == "Constant")) # Wrapped in Constant
    (check "mkUri" (s.getExprKind (s.mkUri "https://example.com") == "Constant")) # Wrapped in Constant
    (check "mkEnvPath" (s.getExprKind (s.mkEnvPath "nixpkgs") == "EnvPath"))
    (check "mkHasAttr" (s.getExprKind (s.mkHasAttr (sym "x") [(s.mkStaticKey "y")]) == "HasAttr"))
    (check "mkIf" (s.getExprKind (s.mkIf (sym "c") (sym "t") (sym "f")) == "If"))
    (check "mkLet" (s.getExprKind (s.mkLet [] (sym "x")) == "Let"))
    (check "mkList" (s.getExprKind (s.mkList []) == "List"))
    (check "mkLiteralPath" (s.getExprKind (s.mkLiteralPath "./foo.nix") == "LiteralPath"))
    (check "mkSelect" (s.getExprKind (s.mkSelect null (sym "x") [(s.mkStaticKey "y")]) == "Select"))
    (check "mkSet" (s.getExprKind (s.mkSet false []) == "Set"))
    (check "mkDoubleQuoted" (s.getExprKind (s.mkDoubleQuoted [(s.mkPlain "hi")]) == "Str")) # Wrapped in Str
    (check "mkIndented" (s.getExprKind (s.mkIndented 0 [(s.mkPlain "hi")]) == "Str")) # Wrapped in Str
    (check "mkPlain" (s.getExprKind (s.mkPlain "hi") == "Plain"))
    (check "mkAntiquoted" (s.getExprKind (s.mkAntiquoted (sym "x")) == "Antiquoted"))
    (check "mkEscapedNewline" (s.getExprKind s.mkEscapedNewline == "EscapedNewline"))
    (check "mkSym" (s.getExprKind (sym "x") == "Sym"))
    (check "mkSynHole" (s.getExprKind (s.mkSynHole "a") == "SynHole"))
    (check "mkUnary" (s.getExprKind (s.mkUnary "!" (sym "x")) == "Unary"))
    (check "mkWith" (s.getExprKind (s.mkWith (sym "ns") (sym "x")) == "With"))
    (check "mkInherit" (s.getExprKind (s.mkInherit null ["x"]) == "Inherit"))
    (check "mkNamedVar" (s.getExprKind (nv "x" (sym "x")) == "NamedVar"))
    (check "mkParam" (s.getExprKind (s.mkParam "x") == "Param"))
    (check "mkParamSet" (s.getExprKind (s.mkParamSet null [] false) == "ParamSet"))

    # ═══ 2. syntax: type contracts validation ═══
    (check "contract mkAbs params invalid" (throwsError (s.mkAbs "not-a-param" (sym "x"))))
    (check "contract mkAbs body invalid" (throwsError (s.mkAbs (s.mkParam "x") "not-an-expr")))
    (check "contract mkApp args invalid" (throwsError (s.mkApp "not-func" (sym "x"))))
    (check "contract mkBinary left invalid" (throwsError (s.mkBinary "+" 42 (sym "b"))))
    (check "contract mkInt value invalid" (throwsError (s.mkInt "not-an-int")))
    (check "contract mkDoubleQuoted parts invalid" (throwsError (s.mkDoubleQuoted [(sym "not-antiquoted-text")])))

    # ═══ 3. match: deconstruction ═══
    (check "match Abs" (
      match (s.mkAbs (s.mkParam "x") (sym "x")) {
        Abs = {
          params,
          body,
          ...
        }:
          params.tag == "Param" && body.tag == "Sym";
      }
    ))
    (check "match App" (
      match (s.mkApp (sym "f") (sym "x")) {
        App = {
          func,
          arg,
          ...
        }:
          func.contents == "f" && arg.contents == "x";
      }
    ))
    (check "match Constant Int" (
      match (s.mkInt 42) {
        Constant = {contents, ...}:
          match contents {
            Int = {contents, ...}: contents == 42;
          };
      }
    ))
    (check "match Str DoubleQuoted" (
      match (s.mkDoubleQuoted [(s.mkPlain "hello")]) {
        Str = {contents, ...}:
          match contents {
            DoubleQuoted = {contents, ...}: (builtins.head contents).contents == "hello";
          };
      }
    ))
    (check "match fallback" (
      match (sym "x") {
        Abs = _: false;
        "_" = node: node.tag == "Sym";
      }
    ))

    # ═══ 4. children & rebuild ═══
    (check "children Abs" (builtins.length (t.children (s.mkAbs (s.mkParam "x") (sym "x"))) == 1))
    (check "children App" (builtins.length (t.children (s.mkApp (sym "f") (sym "x"))) == 2))
    (check "children Assert" (builtins.length (t.children (s.mkAssert (sym "c") (sym "x"))) == 2))
    (check "children Binary" (builtins.length (t.children (s.mkBinary "+" (sym "a") (sym "b"))) == 2))
    (check "children Constant" (builtins.length (t.children (s.mkInt 42)) == 0))
    (check "children HasAttr" (builtins.length (t.children (s.mkHasAttr (sym "x") [(s.mkStaticKey "y")])) == 1))
    (check "children If" (builtins.length (t.children (s.mkIf (sym "c") (sym "t") (sym "f"))) == 3))
    (check "children Let" (
      let
        ast = s.mkLet [(nv "x" (s.mkInt 1))] (sym "x");
      in
        builtins.length (t.children ast) == 2
    ))
    (check "children List" (builtins.length (t.children (s.mkList [(sym "a") (sym "b")])) == 2))
    (check "children Select" (
      builtins.length (t.children (s.mkSelect null (sym "x") [(s.mkStaticKey "y")])) == 1
    ))
    (check "children Select with default" (
      builtins.length (t.children (s.mkSelect (s.mkInt 0) (sym "x") [(s.mkStaticKey "y")])) == 2
    ))
    (check "children Set" (
      let
        ast = s.mkSet false [(nv "x" (s.mkInt 1))];
      in
        builtins.length (t.children ast) == 1
    ))
    (check "children Str interpolation" (
      let
        strNode = s.mkDoubleQuoted [(s.mkPlain "foo ") (s.mkAntiquoted (sym "x")) (s.mkPlain " bar")];
      in
        builtins.length (t.children strNode) == 1
    ))
    (check "children Unary" (builtins.length (t.children (s.mkUnary "!" (sym "x"))) == 1))
    (check "children With" (builtins.length (t.children (s.mkWith (sym "ns") (sym "x"))) == 2))
    (check "rebuild roundtrip" (
      let
        ast = s.mkApp (sym "f") (sym "x");
      in
        match (t.rebuild ast (t.children ast)) {
          App = {
            func,
            arg,
            ...
          }:
            func.contents == "f" && arg.contents == "x";
        }
    ))

    # ═══ 5. traversal ═══
    (check "transform rename syms" (
      let
        ast = s.mkApp (sym "x") (sym "x");
        renamed =
          t.transform (
            node:
              if node.tag == "Sym"
              then node // {contents = "y";}
              else node
          )
          ast;
      in
        match renamed {
          App = {
            func,
            arg,
            ...
          }:
            func.contents == "y" && arg.contents == "y";
        }
    ))
    (check "universe count syms" (
      let
        ast = s.mkApp (sym "f") (sym "x");
        symCount = builtins.length (builtins.filter (node: node.tag == "Sym") (t.universe ast));
      in
        symCount == 2
    ))
    (check "rewrite collapse nested" (
      let
        ast = s.mkApp (s.mkApp (sym "f") (sym "x")) (sym "y");
        rule = node:
          match node {
            App = {
              func,
              arg,
              ...
            }:
              if func.tag == "Sym" && arg.tag == "Sym"
              then sym "${func.contents}${arg.contents}"
              else null;
            _ = _: null;
          };
        result = t.rewrite rule ast;
      in
        match result {
          Sym = {contents, ...}: contents == "fxy";
        }
    ))
    (check "para count syms" (
      let
        ast = s.mkApp (sym "f") (sym "x");
        count =
          t.para (
            node: cs:
              (
                if node.tag == "Sym"
                then 1
                else 0
              )
              + builtins.foldl' builtins.add 0 cs
          )
          ast;
      in
        count == 2
    ))
    (check "holes round-trip" (
      let
        ast = s.mkApp (sym "f") (sym "x");
        hs = t.holes ast;
        firstChild = builtins.head (t.children ast);
        firstPair = builtins.head hs;
        child = builtins.elemAt firstPair 0;
        replace = builtins.elemAt firstPair 1;
      in
        child.contents
        == firstChild.contents
        && (match (replace child) {
          App = {
            func,
            arg,
            ...
          }:
            func.contents == "f" && arg.contents == "x";
        })
    ))
    (check "descend transforms only immediate children" (
      let
        deep = s.mkApp (sym "f") (sym "x");
        ast = s.mkApp deep (sym "y");
        result = t.descend (node:
          if node.tag == "Sym"
          then sym "z"
          else node)
        ast;
      in
        match result {
          App = {
            func,
            arg,
            ...
          }:
            arg.contents
            == "z"
            && match func {
              App = inner:
                inner.func.contents == "f" && inner.arg.contents == "x";
            };
        }
    ))
    (check "contexts replace restores parent" (
      let
        ast = s.mkApp (sym "f") (sym "x");
        ctxs = t.contexts ast;
        symCtxs = builtins.filter (pair: (builtins.elemAt pair 0).tag == "Sym") ctxs;
        pair = builtins.head symCtxs;
        sub = builtins.elemAt pair 0;
        repl = builtins.elemAt pair 1;
      in
        match (repl sub) {
          App = {
            func,
            arg,
            ...
          }:
            func.contents == "f" && arg.contents == "x";
        }
    ))

    # ═══ 6. toAST ═══
    (check "toAST int" ((lib.toAST 42).contents.contents == 42))
    (check "toAST bool" ((lib.toAST true).contents.contents == true))
    (check "toAST null" ((lib.toAST null).contents.tag == "Null"))
    (check "toAST string" ((builtins.head (lib.toAST "hi").contents.contents).contents == "hi"))
    (check "toAST path" ((lib.toAST ./test.nix).tag == "LiteralPath"))
    (check "toAST list" ((builtins.length (lib.toAST [1 true]).contents) == 2))
    (check "toAST empty list" ((builtins.length (lib.toAST []).contents) == 0))
    (check "toAST attrset" ((builtins.length (lib.toAST {a = 1;}).bindings) == 1))
    (check "toAST nested" (
      let
        ast = lib.toAST {outer = {inner = 42;};};
        outerBinding = builtins.head ast.bindings;
        innerSet = outerBinding.value;
        innerBinding = builtins.head innerSet.bindings;
      in
        ast.tag
        == "Set"
        && (builtins.head outerBinding.attrPath).contents == "outer"
        && innerSet.tag == "Set"
        && (builtins.head innerBinding.attrPath).contents == "inner"
        && innerBinding.value.contents.contents == 42
    ))
    (check "toAST function throws" (throwsError (lib.toAST (x: x))))
    (check "toAST nested function throws" (throwsError (lib.toAST {a = x: x;})))
    (check "toAST derivation throws" (throwsError (lib.toAST (import <nixpkgs> {}).bash)))
  ];

  failed = map (r: r.name) (builtins.filter (r: !r.pass) allTests);
  total = builtins.length allTests;
  failCount = builtins.length failed;
in
  if failCount == 0
  then builtins.trace "ALL ${toString total} TESTS PASSED" true
  else builtins.trace "${toString failCount}/${toString total} TESTS FAILED:" (builtins.trace (builtins.concatStringsSep "\n" failed) false)
