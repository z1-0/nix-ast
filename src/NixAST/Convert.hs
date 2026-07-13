module NixAST.Convert (
    fromExpr,
    toExpr,
) where

import Data.Coerce (coerce)
import Data.Fix (Fix (..))
import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import Nix.Atoms qualified as HT
import Nix.Expr.Types qualified as HT
import Nix.Prelude (Path (..))
import NixAST.Types qualified as NT

----------------------------------------------------------------------
-- HT.NExpr → Expr
----------------------------------------------------------------------

toExpr :: HT.NExpr         -> NT.Expr
toExpr (Fix x) = case x of
    HT.NAbs params body    -> NT.Abs (toParams params) (toExpr body)
    HT.NApp f a            -> NT.App (toExpr f) (toExpr a)
    HT.NAssert c body      -> NT.Assert (toExpr c) (toExpr body)
    HT.NBinary op l r      -> NT.Binary (binaryOpToText op) (toExpr l) (toExpr r)
    HT.NConstant a         -> NT.Constant (toAtom a)
    HT.NEnvPath p          -> NT.EnvPath (coerce p)
    HT.NHasAttr e attrs    -> NT.HasAttr (toExpr e) (NE.map toKey attrs)
    HT.NIf c t f           -> NT.If (toExpr c) (toExpr t) (toExpr f)
    HT.NLet bs body        -> NT.Let (map toBinding bs) (toExpr body)
    HT.NList xs            -> NT.List (map toExpr xs)
    HT.NLiteralPath p      -> NT.LiteralPath (coerce p)
    HT.NSelect def e attrs -> NT.Select{defaultValue = fmap toExpr def, expr = toExpr e, selectPath = NE.map toKey attrs}
    HT.NSet r bs           -> NT.Set (r == HT.Recursive) (map toBinding bs)
    HT.NStr s              -> NT.Str (toNString s)
    HT.NSym n              -> NT.Sym n
    HT.NSynHole n          -> NT.SynHole n
    HT.NUnary op a         -> NT.Unary (unaryOpToText op) (toExpr a)
    HT.NWith ns body       -> NT.With (toExpr ns) (toExpr body)

toAtom :: HT.NAtom -> NT.Atom
toAtom (HT.NBool b)  = NT.Bool b
toAtom (HT.NFloat f) = NT.Float f
toAtom (HT.NInt i)   = NT.Int i
toAtom (HT.NURI t)   = NT.Uri t
toAtom HT.NNull      = NT.Null

toNString :: HT.NString HT.NExpr -> NT.String
toNString (HT.DoubleQuoted parts) = NT.DoubleQuoted (map toAntiquoted parts)
toNString (HT.Indented n parts)   = NT.Indented n (map toAntiquoted parts)

toAntiquoted :: HT.Antiquoted Text HT.NExpr -> NT.Antiquoted Text
toAntiquoted (HT.Antiquoted e) = NT.Antiquoted (toExpr e)
toAntiquoted (HT.Plain t)      = NT.Plain t
toAntiquoted HT.EscapedNewline = NT.EscapedNewline

toBinding :: HT.Binding HT.NExpr -> NT.Binding
toBinding (HT.Inherit scope names _) = NT.Inherit (fmap toExpr scope) names
toBinding (HT.NamedVar path val _)   = NT.NamedVar (NE.map toKey path) (toExpr val)

toKey :: HT.NKeyName HT.NExpr -> NT.KeyName
toKey (HT.DynamicKey (HT.Antiquoted e)) = NT.DynamicKey (NT.Antiquoted (toExpr e))
toKey (HT.DynamicKey (HT.Plain s))      = NT.DynamicKey (NT.Plain (toNString s))
toKey (HT.DynamicKey HT.EscapedNewline) = NT.DynamicKey NT.EscapedNewline
toKey (HT.StaticKey n)                  = NT.StaticKey n

toParams :: HT.Params HT.NExpr -> NT.Params
toParams (HT.Param n)                    = NT.Param n
toParams (HT.ParamSet args variadic set) = NT.ParamSet args isVariadic (map convertParam set)
  where
    convertParam (n, d) = (n, fmap toExpr d)
    isVariadic          = variadic == HT.Variadic

----------------------------------------------------------------------
-- Expr → HT.NExpr
----------------------------------------------------------------------

fromExpr :: NT.Expr -> Either Text HT.NExpr
fromExpr expr = Fix <$> fromExprF expr

fromExprF :: NT.Expr                          -> Either Text (HT.NExprF HT.NExpr)
fromExprF = \case
    NT.Abs{params, body}                      -> HT.NAbs <$> fromParams params <*> fromExpr body
    NT.App{func, arg}                         -> HT.NApp <$> fromExpr func <*> fromExpr arg
    NT.Assert{cond, body}                     -> HT.NAssert <$> fromExpr cond <*> fromExpr body
    NT.Binary{op, left, right}                -> HT.NBinary <$> fromBinaryOp op <*> fromExpr left <*> fromExpr right
    NT.Constant atom                          -> pure $ HT.NConstant (fromAtom atom)
    NT.EnvPath path                           -> pure $ HT.NEnvPath (Path path)
    NT.HasAttr{expr, attrPath}                -> HT.NHasAttr <$> fromExpr expr <*> traverse fromKey attrPath
    NT.If{cond, thenExpr, elseExpr}           -> HT.NIf <$> fromExpr cond <*> fromExpr thenExpr <*> fromExpr elseExpr
    NT.Let{bindings, body}                    -> HT.NLet <$> traverse fromBinding bindings <*> fromExpr body
    NT.List items                             -> HT.NList <$> traverse fromExpr items
    NT.LiteralPath path                       -> pure $ HT.NLiteralPath (Path path)
    NT.Select{defaultValue, expr, selectPath} -> HT.NSelect <$> traverse fromExpr defaultValue <*> fromExpr expr <*> traverse fromKey selectPath
    NT.Set{recursive, bindings}               -> HT.NSet flag <$> traverse fromBinding bindings where flag = if recursive then HT.Recursive else HT.NonRecursive
    NT.Str value                              -> HT.NStr <$> fromNString value
    NT.Sym name                               -> pure $ HT.NSym name
    NT.SynHole name                           -> pure $ HT.NSynHole name
    NT.Unary{op, arg}                         -> HT.NUnary <$> fromUnaryOp op <*> fromExpr arg
    NT.With{namespace, body}                  -> HT.NWith <$> fromExpr namespace <*> fromExpr body

fromAtom :: NT.Atom -> HT.NAtom
fromAtom (NT.Bool b)  = HT.NBool b
fromAtom (NT.Float f) = HT.NFloat f
fromAtom (NT.Int i)   = HT.NInt i
fromAtom (NT.Uri t)   = HT.NURI t
fromAtom NT.Null      = HT.NNull

fromNString :: NT.String -> Either Text (HT.NString HT.NExpr)
fromNString (NT.DoubleQuoted parts) = HT.DoubleQuoted <$> traverse fromAntiquoted parts
fromNString (NT.Indented n parts)   = HT.Indented n <$> traverse fromAntiquoted parts

fromAntiquoted :: NT.Antiquoted Text -> Either Text (HT.Antiquoted Text HT.NExpr)
fromAntiquoted (NT.Antiquoted e) = HT.Antiquoted <$> fromExpr e
fromAntiquoted (NT.Plain t)      = pure $ HT.Plain t
fromAntiquoted NT.EscapedNewline = pure HT.EscapedNewline

fromBinding :: NT.Binding -> Either Text (HT.Binding HT.NExpr)
fromBinding NT.Inherit{..}  = HT.Inherit <$> traverse fromExpr scope <*> pure names <*> pure HT.nullPos
fromBinding NT.NamedVar{..} = HT.NamedVar <$> traverse fromKey attrPath <*> fromExpr value <*> pure HT.nullPos

fromKey :: NT.KeyName -> Either Text (HT.NKeyName HT.NExpr)
fromKey (NT.DynamicKey (NT.Antiquoted e)) = HT.DynamicKey . HT.Antiquoted <$> fromExpr e
fromKey (NT.DynamicKey (NT.Plain s))      = HT.DynamicKey . HT.Plain <$> fromNString s
fromKey (NT.DynamicKey NT.EscapedNewline) = pure $ HT.DynamicKey HT.EscapedNewline
fromKey (NT.StaticKey n)                  = pure $ HT.StaticKey n

fromParams :: NT.Params -> Either Text (HT.Params HT.NExpr)
fromParams (NT.Param paramName) = pure $ HT.Param paramName
fromParams NT.ParamSet{..}      = HT.ParamSet paramSetName v <$> traverse convertParam params
  where
    convertParam (name, defaultValue) = (name,) <$> traverse fromExpr defaultValue
    v                                 = if variadic then HT.Variadic else HT.Closed

----------------------------------------------------------------------
-- Op mapping
----------------------------------------------------------------------

unaryOpToText :: HT.NUnaryOp -> Text
unaryOpToText HT.NNeg     = "-"
unaryOpToText HT.NNot     = "!"

binaryOpToText :: HT.NBinaryOp -> Text
binaryOpToText HT.NAnd    = "&&"
binaryOpToText HT.NConcat = "++"
binaryOpToText HT.NDiv    = "/"
binaryOpToText HT.NEq     = "=="
binaryOpToText HT.NGt     = ">"
binaryOpToText HT.NGte    = ">="
binaryOpToText HT.NImpl   = "->"
binaryOpToText HT.NLt     = "<"
binaryOpToText HT.NLte    = "<="
binaryOpToText HT.NMinus  = "-"
binaryOpToText HT.NMult   = "*"
binaryOpToText HT.NNEq    = "!="
binaryOpToText HT.NOr     = "||"
binaryOpToText HT.NPlus   = "+"
binaryOpToText HT.NUpdate = "//"

fromUnaryOp :: Text -> Either Text HT.NUnaryOp
fromUnaryOp "!"           = Right HT.NNot
fromUnaryOp "-"           = Right HT.NNeg
fromUnaryOp op            = Left ("Unknown unary operator: " <> op)

fromBinaryOp :: Text -> Either Text HT.NBinaryOp
fromBinaryOp "!="         = Right HT.NNEq
fromBinaryOp "&&"         = Right HT.NAnd
fromBinaryOp "++"         = Right HT.NConcat
fromBinaryOp "-"          = Right HT.NMinus
fromBinaryOp "//"         = Right HT.NUpdate
fromBinaryOp "/"          = Right HT.NDiv
fromBinaryOp "->"         = Right HT.NImpl
fromBinaryOp "<"          = Right HT.NLt
fromBinaryOp "<="         = Right HT.NLte
fromBinaryOp "=="         = Right HT.NEq
fromBinaryOp ">"          = Right HT.NGt
fromBinaryOp ">="         = Right HT.NGte
fromBinaryOp "*"          = Right HT.NMult
fromBinaryOp "||"         = Right HT.NOr
fromBinaryOp "+"          = Right HT.NPlus
fromBinaryOp op           = Left ("Unknown binary operator: " <> op)
