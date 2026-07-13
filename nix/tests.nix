{ lib, pkgs }:
let
  inherit (pkgs.lib.debug) runTests throwTestFailures;
  inherit (lib) match syntax traversal eval parse render toAST fromAST;
  test = expr: expected: { inherit expr expected; };
  assertThrows = expr: test (!(builtins.tryEval expr).success) true;
  flakeAST = builtins.head (parse pkgs [ ../flake.nix ]);
in throwTestFailures {
  failures = runTests {
    testMatch_exact = test (match (syntax.mkSym "x") { Sym = n: n.contents; }) "x";
    testMatch_wildcard = test (match syntax.mkNull { _ = n: n.tag; }) "Constant";
    testMatch_nonNode = assertThrows (match { } { _ = n: true; });
    testMatch_nonExhaustive = assertThrows (match (syntax.mkSym "x") { Int = n: n; });
    testTraversal_sym = test (traversal.rebuild (syntax.mkSym "x") (traversal.children (syntax.mkSym "x"))) (syntax.mkSym "x");
    testTraversal_int = test (traversal.rebuild (syntax.mkInt 42) (traversal.children (syntax.mkInt 42))) (syntax.mkInt 42);
    testTraversal_null = test (traversal.rebuild syntax.mkNull (traversal.children syntax.mkNull)) syntax.mkNull;
    testTraversal_list = let n = syntax.mkList [ (syntax.mkInt 1) (syntax.mkSym "x") ]; in test (traversal.rebuild n (traversal.children n)) n;
    testTraversal_set = let n = syntax.mkSet false [ (syntax.mkNamedVar [ (syntax.mkStaticKey "a") ] (syntax.mkInt 1)) ]; in test (traversal.rebuild n (traversal.children n)) n;
    testTraversal_abs = let n = syntax.mkAbs (syntax.mkParam "x") (syntax.mkSym "x"); in test (traversal.rebuild n (traversal.children n)) n;
    testTraversal_app = let n = syntax.mkApp (syntax.mkSym "f") (syntax.mkSym "x"); in test (traversal.rebuild n (traversal.children n)) n;
    testTraversal_binary = let n = syntax.mkBinary "+" (syntax.mkInt 1) (syntax.mkInt 2); in test (traversal.rebuild n (traversal.children n)) n;
    testTraversal_if = let n = syntax.mkIf (syntax.mkBool true) (syntax.mkInt 1) (syntax.mkInt 2); in test (traversal.rebuild n (traversal.children n)) n;
    testTraversal_with = let n = syntax.mkWith (syntax.mkSym "ns") (syntax.mkSym "x"); in test (traversal.rebuild n (traversal.children n)) n;
    testTraversal_unary = let n = syntax.mkUnary "!" (syntax.mkBool true); in test (traversal.rebuild n (traversal.children n)) n;
    testTraversal_hasAttr = let n = syntax.mkHasAttr (syntax.mkSym "x") [ (syntax.mkStaticKey "y") ]; in test (traversal.rebuild n (traversal.children n)) n;
    testEval_int = test (builtins.head (eval pkgs [ (syntax.mkInt 42) ])) 42;
    testEval_bool = test (builtins.head (eval pkgs [ (syntax.mkBool true) ])) true;
    testParse_flake = test (match flakeAST { Set = _: true; _ = _: false; }) true;
    testParse_count = test (builtins.length (parse pkgs [ ../flake.nix ../flake.nix ])) 2;
    testParse_content = test (builtins.head (parse pkgs [ ../flake.nix ])) flakeAST;
    testToAST_bool = test (toAST true) (syntax.mkBool true);
    testToAST_int = test (toAST 42) (syntax.mkInt 42);
    testToAST_float = test (toAST 3.14) (syntax.mkFloat 3.14);
    testToAST_null = test (toAST null) syntax.mkNull;
    testToAST_string = test (toAST "hi") (syntax.mkStr (syntax.mkDoubleQuoted [ (syntax.mkPlain "hi") ]));
    testToAST_list = test (toAST [ 1 "a" ]) (syntax.mkList [ (syntax.mkInt 1) (syntax.mkStr (syntax.mkDoubleQuoted [ (syntax.mkPlain "a") ])) ]);
    testToAST_function = assertThrows (toAST (x: x));
    testToAST_attrset = test (toAST { x = 1; }) (syntax.mkSet false [ (syntax.mkNamedVar [ (syntax.mkStaticKey "x") ] (syntax.mkInt 1)) ]);
    testRender_returnsList = test (builtins.isList (render pkgs [ flakeAST ])) true;
    testRender_pathsAreStrings = let f = render pkgs [ flakeAST flakeAST ]; in test (builtins.all builtins.isString f) true;
    testRender_twoAsts = test (builtins.length (render pkgs [ flakeAST flakeAST ])) 2;
    testRoundtrip_simple = let
      src = "{ a = 1; b = 2; }";
      srcFile = pkgs.writeText "test.nix" src;
      ast = builtins.head (parse pkgs [ srcFile ]);
      rendered = builtins.head (render pkgs [ ast ]);
    in test src (builtins.readFile rendered);
    testFromAST_int = test (fromAST (syntax.mkInt 42)) 42;
    testFromAST_float = test (fromAST (syntax.mkFloat 3.14)) 3.14;
    testFromAST_bool = test (fromAST (syntax.mkBool true)) true;
    testFromAST_null = test (fromAST syntax.mkNull) null;
    testFromAST_string = test (fromAST (syntax.mkStr (syntax.mkDoubleQuoted [ (syntax.mkPlain "hi") ]))) "hi";
    testFromAST_list = test (fromAST (syntax.mkList [ (syntax.mkInt 1) (syntax.mkStr (syntax.mkDoubleQuoted [ (syntax.mkPlain "a") ])) ])) [ 1 "a" ];
    testFromAST_set = test (fromAST (syntax.mkSet false [ (syntax.mkNamedVar [ (syntax.mkStaticKey "x") ] (syntax.mkInt 1)) ])) { x = 1; };
    testFromAST_recursiveSet = assertThrows (fromAST (syntax.mkSet true []));
  };
}
