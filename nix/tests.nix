{ lib, pkgs }:
let
  inherit (pkgs.lib.debug) runTests throwTestFailures;
  inherit (lib) match syntax traversal toAST parse render;

  test = expr: expected: { inherit expr expected; };
  assertThrows = expr: test (!(builtins.tryEval expr).success) true;

  flakeAST = parse pkgs ../flake.nix;
in
throwTestFailures {
  failures = runTests {
    testToAST_bool = test (toAST true) (syntax.mkBool true);
    testToAST_int = test (toAST 42) (syntax.mkInt 42);
    testToAST_float = test (toAST 3.14) (syntax.mkFloat 3.14);
    testToAST_null = test (toAST null) syntax.mkNull;
    testToAST_string = test (toAST "hi") (syntax.mkDoubleQuoted [ (syntax.mkPlain "hi") ]);
    testToAST_list = test (toAST [ 1 "a" ]) (syntax.mkList [ (syntax.mkInt 1) (syntax.mkDoubleQuoted [ (syntax.mkPlain "a") ]) ]);
    testToAST_function = assertThrows (toAST (x: x));
    testToAST_attrset = test (toAST { x = 1; }) (syntax.mkSet false [ (syntax.mkNamedVar [ (syntax.mkStaticKey "x") ] (syntax.mkInt 1)) ]);

    testMatch_exact = test (match (syntax.mkSym "x") { Sym = n: n.contents; }) "x";
    testMatch_wildcard = test (match syntax.mkNull { _ = n: n.tag; }) "Constant";
    testMatch_nonNode = assertThrows (match { } { _ = n: true; });
    testMatch_nonExhaustive = assertThrows (match (syntax.mkSym "x") { Int = n: n; });

    testParse_flake = test (match flakeAST { Set = _: true; _ = _: false; }) true;
    testRoundtrip_structure = test flakeAST (parse pkgs (render pkgs flakeAST));

    # --- Traversal: children/rebuild contract ---
    # rebuild node (children node) == node for various node types
    testTraversal_sym = test (traversal.rebuild (syntax.mkSym "x") (traversal.children (syntax.mkSym "x"))) (syntax.mkSym "x");
    testTraversal_int = test (traversal.rebuild (syntax.mkInt 42) (traversal.children (syntax.mkInt 42))) (syntax.mkInt 42);
    testTraversal_null = test (traversal.rebuild syntax.mkNull (traversal.children syntax.mkNull)) syntax.mkNull;
    testTraversal_list =
      let node = syntax.mkList [ (syntax.mkInt 1) (syntax.mkSym "x") ];
      in test (traversal.rebuild node (traversal.children node)) node;
    testTraversal_set =
      let node = syntax.mkSet false [ (syntax.mkNamedVar [ (syntax.mkStaticKey "a") ] (syntax.mkInt 1)) ];
      in test (traversal.rebuild node (traversal.children node)) node;
    testTraversal_abs =
      let node = syntax.mkAbs (syntax.mkParam "x") (syntax.mkSym "x");
      in test (traversal.rebuild node (traversal.children node)) node;
    testTraversal_app =
      let node = syntax.mkApp (syntax.mkSym "f") (syntax.mkSym "x");
      in test (traversal.rebuild node (traversal.children node)) node;
    testTraversal_binary =
      let node = syntax.mkBinary "+" (syntax.mkInt 1) (syntax.mkInt 2);
      in test (traversal.rebuild node (traversal.children node)) node;
    testTraversal_if =
      let node = syntax.mkIf (syntax.mkBool true) (syntax.mkInt 1) (syntax.mkInt 2);
      in test (traversal.rebuild node (traversal.children node)) node;
    testTraversal_with =
      let node = syntax.mkWith (syntax.mkSym "ns") (syntax.mkSym "x");
      in test (traversal.rebuild node (traversal.children node)) node;
    testTraversal_unary =
      let node = syntax.mkUnary "!" (syntax.mkBool true);
      in test (traversal.rebuild node (traversal.children node)) node;
    testTraversal_hasAttr =
      let node = syntax.mkHasAttr (syntax.mkSym "x") [ (syntax.mkStaticKey "y") ];
      in test (traversal.rebuild node (traversal.children node)) node;
  };
}
