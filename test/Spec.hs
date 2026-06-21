{-# OPTIONS_GHC -Wno-orphans #-}

module Main (main) where

import Data.Aeson (decode, encode)
import Data.Fix (Fix (..))
import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import Data.Text qualified as T
import Nix.Expr.Types qualified as HT
import Nix.Parser (parseNixText)
import NixAST
import Test.QuickCheck
import Test.Tasty (TestTree, defaultMain, testGroup)
import Test.Tasty.HUnit (assertFailure, testCase, (@?=))
import Test.Tasty.QuickCheck (testProperty)

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
    testGroup
        "nix-ast"
        [ parseRoundtripTests
        , jsonRoundtripTests
        , propertyTests
        ]

----------------------------------------------------------------------
-- Roundtrip: Nix → Expr → JSON → Expr → Nix
----------------------------------------------------------------------

parseRoundtripTests :: TestTree
parseRoundtripTests = testGroup "parse roundtrip" (map mkTest cases)

mkTest :: (Text, Text) -> TestTree
mkTest (name, src) =
    testCase (T.unpack name) $ case parseNixText src of
        Left err -> assertFailure (show err)
        Right expr -> do
            let json = encode (toExpr expr)
            case decode @Expr json of
                Nothing -> assertFailure "JSON decode failed (type mismatch)"
                Just ourExpr -> do
                    let hnixBack = fromExpr ourExpr
                        src2 = renderNix hnixBack
                    case parseNixText src2 of
                        Left err ->
                            assertFailure
                                ( "Re-parse failed: "
                                    <> show err
                                    <> "\n  src: "
                                    <> show src
                                    <> "\n  src2: "
                                    <> show src2
                                )
                        Right expr2 ->
                            stripPositions expr @?= stripPositions expr2

----------------------------------------------------------------------
-- jsonToNix: JSON → Nix → re-parse roundtrip
----------------------------------------------------------------------

jsonRoundtripTests :: TestTree
jsonRoundtripTests = testGroup "json roundtrip" (map mkJsonTest cases)

mkJsonTest :: (Text, Text) -> TestTree
mkJsonTest (name, src) =
    testCase (T.unpack name) $ case parseNixText src of
        Left err -> assertFailure (show err)
        Right expr -> do
            let json = encode (toExpr expr)
            case jsonToNix json of
                Left err -> assertFailure ("jsonToNix failed: " <> T.unpack err)
                Right nixSrc -> case parseNixText nixSrc of
                    Left err ->
                        assertFailure
                            ( "Re-parse after jsonToNix failed: "
                                <> show err
                                <> "\n  src:      "
                                <> show src
                                <> "\n  nixSrc:   "
                                <> show nixSrc
                            )
                    Right expr2 -> stripPositions expr @?= stripPositions expr2

----------------------------------------------------------------------
-- Test cases by category
----------------------------------------------------------------------

cases :: [(Text, Text)]
cases =
    [ -- Literals
      ("int", "42")
    , ("negative int", "-1")
    , ("string", "\"hello\"")
    , ("indented string", "''hello''")
    , ("path", "./foo.nix")
    , ("env path", "<nixpkgs>")
    , ("uri", "https://example.com")
    , ("interpolation", "\"foo ${bar} baz\"")
    , -- Expressions
      ("function", "x: x + 1")
    , ("let", "let x = 1; in x")
    , ("if", "if true then 1 else 2")
    , ("with", "with pkgs; python")
    , ("assert", "assert true; 1")
    , ("nested let-in-if", "let x = if true then 1 else 2; in x")
    , ("nested if-in-let", "let f = x: if x then 1 else 0; in f true")
    , -- Operators
      ("binary ops", "1 + 2 * 3")
    , ("unary ops", "!true")
    , ("comparison ops", "1 < 2")
    , ("logic ops", "true && false || true")
    , ("update ops", "{ } // { a = 1; }")
    , -- Sets
      ("set", "{ a = 1; b = 2; }")
    , ("rec set", "rec { a = 1; b = a + 1; }")
    , ("empty set", "{}")
    , ("nested set", "{ a = { b = 1; }; }")
    , ("dynamic key", "{ ${\"foo\"} = 1; }")
    , ("dynamic key with expr", "{ ${x} = 1; }")
    , ("mixed key", "{ \"foo${x}\" = 1; }")
    , -- Lists
      ("list", "[1 2 3]")
    , ("empty list", "[]")
    , ("nested list", "[1 [2 3] 4]")
    , -- Attribute access
      ("attr access", "x.y.z")
    , ("deep attr access", "a.b.c.d")
    , ("select with default", "x.y or 1")
    , -- Parameters
      ("param set", "{ x, y }: x + y")
    , ("param set default", "{ x ? 1 }: x")
    , ("param set variadic", "{ x, ... }: x")
    , -- Inherit
      ("inherit", "{ inherit x y; }")
    , ("inherit from", "{ inherit (pkgs) python; }")
    , -- Has attribute
      ("has attr", "x ? y")
    , ("has attr deep", "x ? y.z")
    ]

----------------------------------------------------------------------
-- Property tests
----------------------------------------------------------------------

propertyTests :: TestTree
propertyTests =
    testGroup
        "Properties"
        [ testProperty "JSON roundtrip: decode . encode == Just" $ \expr ->
            decode (encode expr) == Just (expr :: Expr)
        ]

----------------------------------------------------------------------
-- Arbitrary instances
----------------------------------------------------------------------

instance Arbitrary Expr where
    arbitrary = sized genExpr
    shrink = shrinkExpr

instance Arbitrary Binding where
    arbitrary = sized genBinding
    shrink (NamedVar ks v) =
        [NamedVar ks v' | v' <- shrink v]
    shrink (Inherit scope names) =
        [Inherit scope' names | scope' <- shrink scope]

shrinkExpr :: Expr -> [Expr]
shrinkExpr (App f a) =
    [f, a]
        ++ [App f' a | f' <- shrink f]
        ++ [App f a' | a' <- shrink a]
shrinkExpr (Binary op l r) =
    [l, r]
        ++ [Binary op l' r | l' <- shrink l]
        ++ [Binary op l r' | r' <- shrink r]
shrinkExpr (If c t f) =
    [c, t, f]
        ++ [If c' t f | c' <- shrink c]
        ++ [If c t' f | t' <- shrink t]
        ++ [If c t f' | f' <- shrink f]
shrinkExpr (Let bs b) =
    b
        : [Let bs' b | bs' <- shrink bs]
        ++ [Let bs b' | b' <- shrink b]
shrinkExpr (List xs) =
    xs ++ [List xs' | xs' <- shrink xs]
shrinkExpr (Set recursive bs) =
    [Set recursive bs' | bs' <- shrink bs]
shrinkExpr (Select defaultValue e ks) =
    [e]
        ++ [Select defaultValue e' ks | e' <- shrink e]
        ++ [Select defaultValue' e ks | defaultValue' <- shrink defaultValue]
shrinkExpr (HasAttr e _) =
    [e]
shrinkExpr (Abs _ b) =
    [b]
shrinkExpr (Unary _ a) =
    [a]
shrinkExpr (With ns b) =
    ns
        : b
        : [With ns' b | ns' <- shrink ns]
        ++ [With ns b' | b' <- shrink b]
shrinkExpr (Assert c b) =
    c
        : b
        : [Assert c' b | c' <- shrink c]
        ++ [Assert c b' | b' <- shrink b]
shrinkExpr _ = []

genExpr :: Int -> Gen Expr
genExpr 0 = oneof [genAtom, genSym, genStr]
genExpr n =
    frequency
        [ (3, genAtom)
        , (3, genSym)
        , (2, genStr)
        , (2, genApp n)
        , (2, genBinary n)
        , (1, genIf n)
        , (1, genLet n)
        , (1, genList n)
        , (1, genSet n)
        ]

genAtom :: Gen Expr
genAtom =
    Constant
        <$> oneof
            [ Bool <$> arbitrary
            , Int <$> arbitrary
            , pure Null
            ]

genSym :: Gen Expr
genSym = Sym . HT.VarName . T.pack <$> listOf1 (choose ('a', 'z'))

genStr :: Gen Expr
genStr = Str <$> (DoubleQuoted . pure . Plain . T.pack <$> listOf1 (choose ('a', 'z')))

genApp :: Int -> Gen Expr
genApp n = App <$> genExpr (n `div` 2) <*> genExpr (n `div` 2)

genBinary :: Int -> Gen Expr
genBinary n =
    Binary
        <$> elements ["+", "-", "*", "/", "==", "!=", "<", ">", "<=", ">=", "&&", "||", "++", "//"]
        <*> genExpr (n `div` 2)
        <*> genExpr (n `div` 2)

genIf :: Int -> Gen Expr
genIf n = If <$> genExpr (n `div` 3) <*> genExpr (n `div` 3) <*> genExpr (n `div` 3)

genLet :: Int -> Gen Expr
genLet n = do
    bs <- vectorOf (1 + n `mod` 3) (genBinding (n `div` 2))
    Let bs <$> genExpr (n `div` 2)

genList :: Int -> Gen Expr
genList n = List <$> vectorOf (n `mod` 3) (genExpr (n `div` 2))

genSet :: Int -> Gen Expr
genSet n = Set False <$> vectorOf (n `mod` 3) (genBinding (n `div` 2))

genBinding :: Int -> Gen Binding
genBinding n = do
    name <- HT.VarName . T.pack <$> vectorOf (1 + n `mod` 3) (choose ('a', 'z'))
    NamedVar (NE.singleton (StaticKey name)) <$> genExpr (n `div` 2)

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

stripPositions :: HT.NExpr -> HT.NExpr
stripPositions (Fix x) = Fix (go x)
  where
    go (HT.NAbs p b) = HT.NAbs (stripParams p) (stripPositions b)
    go (HT.NApp f a) = HT.NApp (stripPositions f) (stripPositions a)
    go (HT.NAssert c b) = HT.NAssert (stripPositions c) (stripPositions b)
    go (HT.NBinary op l r) = HT.NBinary op (stripPositions l) (stripPositions r)
    go (HT.NConstant a) = HT.NConstant a
    go (HT.NEnvPath p) = HT.NEnvPath p
    go (HT.NHasAttr e attrs) = HT.NHasAttr (stripPositions e) attrs
    go (HT.NIf c t f_) = HT.NIf (stripPositions c) (stripPositions t) (stripPositions f_)
    go (HT.NLet bs b) = HT.NLet (map stripBinding bs) (stripPositions b)
    go (HT.NList xs) = HT.NList (map stripPositions xs)
    go (HT.NLiteralPath p) = HT.NLiteralPath p
    go (HT.NSelect d e attrs) = HT.NSelect (fmap stripPositions d) (stripPositions e) attrs
    go (HT.NSet r bs) = HT.NSet r (map stripBinding bs)
    go (HT.NStr s) = HT.NStr (stripNString s)
    go (HT.NSym n) = HT.NSym n
    go (HT.NSynHole n) = HT.NSynHole n
    go (HT.NUnary op a) = HT.NUnary op (stripPositions a)
    go (HT.NWith ns b) = HT.NWith (stripPositions ns) (stripPositions b)

    stripBinding (HT.NamedVar path val _) = HT.NamedVar path val HT.nullPos
    stripBinding (HT.Inherit scope names _) = HT.Inherit scope names HT.nullPos

    stripParams (HT.Param n) = HT.Param n
    stripParams (HT.ParamSet n v ps) = HT.ParamSet n v ps

    stripNString (HT.DoubleQuoted parts) = HT.DoubleQuoted parts
    stripNString (HT.Indented n parts) = HT.Indented n parts
