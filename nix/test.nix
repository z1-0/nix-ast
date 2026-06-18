# nix/test.nix — Nix AST API Tests
# Run: nix-instantiate --eval nix/test.nix 2>&1
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

    # ═══ 4. core: children & rebuild ═══
    (check "children Abs" (builtins.length (t.children (s.mkAbs (s.mkParam "x") (sym "x"))) == 1))
    (check "children App" (builtins.length (t.children (s.mkApp (sym "f") (sym "x"))) == 2))
    (check "children Constant" (builtins.length (t.children (s.mkInt 42)) == 0))
    (check "children List" (builtins.length (t.children (s.mkList [(sym "a") (sym "b")])) == 2))
    (check "children Str interpolation" (
      let
        strNode = s.mkDoubleQuoted [(s.mkPlain "foo ") (s.mkAntiquoted (sym "x")) (s.mkPlain " bar")];
      in
        builtins.length (t.children strNode) == 1
    ))
    (check "map leaves" (
      let
        app = s.mkApp (sym "f") (sym "x");
        mapped = t.transform (node:
          match node {
            Sym = sNode: sym "${sNode.contents}1";
            _ = _: node;
          })
        app;
      in
        match mapped {
          App = {
            func,
            arg,
            ...
          }:
            func.contents == "f1" && arg.contents == "x1";
        }
    ))

    # ═══ 5. traverse: generic traversal ═══
    (check "traversal transform rename syms" (
      let
        ast = s.mkApp (sym "x") (sym "x");
        renamed = t.transform (node:
          if node.tag == "Sym"
          then node // {contents = "y";}
          else node
        ) ast;
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
    (check "traversal universe count syms" (
      let
        ast = s.mkApp (sym "f") (sym "x");
        symCount = builtins.length (builtins.filter (node: node.tag == "Sym") (t.universe ast));
      in
        symCount == 2
    ))

  ];

  failed = map (t: t.name) (builtins.filter (t: !t.pass) allTests);
  total = builtins.length allTests;
  failCount = builtins.length failed;
in
  if failCount == 0
  then builtins.trace "ALL ${toString total} TESTS PASSED" true
  else builtins.trace "${toString failCount}/${toString total} TESTS FAILED:" (builtins.trace (builtins.concatStringsSep "\n" failed) false)
