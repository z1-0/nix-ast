{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module NixAST.Convert (
    dummyPos,
    fromExpr,
    toExpr,
) where

import Data.Coerce (coerce)
import Data.Fix (Fix (..))
import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import Data.Text qualified as T
import Nix.Atoms qualified as HT
import Nix.Expr.Types qualified as HT
import Nix.Prelude (Path (..))
import NixAST.Types qualified as NT
import Prelude hiding (String)
import Text.Megaparsec (mkPos)

----------------------------------------------------------------------
-- HT.NExpr → Expr
----------------------------------------------------------------------

toExpr :: HT.NExpr             -> NT.Expr
toExpr (Fix x) = case x of
    HT.NAbs params body        -> NT.Abs (toParams params) (toExpr body)
    HT.NApp f a                -> NT.App (toExpr f) (toExpr a)
    HT.NAssert c body          -> NT.Assert (toExpr c) (toExpr body)
    HT.NBinary op l r          -> NT.Binary (binaryOpToText op) (toExpr l) (toExpr r)
    HT.NConstant a             -> NT.Constant (toAtom a)
    HT.NEnvPath p              -> NT.EnvPath (coerce p)
    HT.NHasAttr e attrs        -> NT.HasAttr (toExpr e) (NE.map toKey attrs)
    HT.NIf c t f               -> NT.If (toExpr c) (toExpr t) (toExpr f)
    HT.NLet bs body            -> NT.Let (map toBinding bs) (toExpr body)
    HT.NList xs                -> NT.List (map toExpr xs)
    HT.NLiteralPath p          -> NT.LiteralPath (coerce p)
    HT.NSelect def e attrs     -> NT.Select (toExpr e) (NE.map toKey attrs) (fmap toExpr def)
    HT.NSet r bs               -> NT.Set (r == HT.Recursive) (map toBinding bs)
    HT.NStr s                  -> NT.Str (toNString s)
    HT.NSym (HT.VarName n)     -> NT.Sym n
    HT.NSynHole (HT.VarName t) -> NT.SynHole t
    HT.NUnary op a             -> NT.Unary (unaryOpToText op) (toExpr a)
    HT.NWith ns body           -> NT.With (toExpr ns) (toExpr body)

toAtom :: HT.NAtom -> NT.Atom
toAtom (HT.NBool b)  = NT.Bool b
toAtom (HT.NFloat f) = NT.Float (realToFrac f)
toAtom (HT.NInt i)   = NT.Int i
toAtom (HT.NURI t)   = NT.Uri t
toAtom HT.NNull      = NT.Null

toNString :: HT.NString HT.NExpr -> NT.String
toNString (HT.DoubleQuoted parts) = NT.DoubleQuoted (map toAntiquoted parts)
toNString (HT.Indented n parts)   = NT.Indented n (map toAntiquoted parts)

toAntiquoted :: HT.Antiquoted Text HT.NExpr -> NT.Antiquoted Text
toAntiquoted (HT.Antiquoted e) = NT.Interpolation (toExpr e)
toAntiquoted (HT.Plain t)      = NT.Plain t
toAntiquoted HT.EscapedNewline = NT.EscapedNewline

toBinding :: HT.Binding HT.NExpr -> NT.Binding
toBinding (HT.Inherit scope names _) = NT.Inherit (fmap toExpr scope) (coerce names)
toBinding (HT.NamedVar path val _)   = NT.NamedVar (NE.map toKey path) (toExpr val)

toKey :: HT.NKeyName HT.NExpr -> NT.Key
toKey (HT.DynamicKey (HT.Antiquoted e)) = NT.DynamicKey (NT.Interpolation (toExpr e))
toKey (HT.DynamicKey (HT.Plain s))      = NT.DynamicKey (NT.Plain (toNString s))
toKey (HT.DynamicKey HT.EscapedNewline) = NT.DynamicKey NT.EscapedNewline
toKey (HT.StaticKey (HT.VarName t))     = NT.StaticKey t

toParams :: HT.Params HT.NExpr -> NT.Params
toParams (HT.Param (HT.VarName n))       = NT.Single n
toParams (HT.ParamSet args variadic set) = NT.ParamSet (coerce args) (map convertParam set) isVariadic
  where
    convertParam (HT.VarName n, d) = (n, fmap toExpr d)
    isVariadic                     = variadic == HT.Variadic

----------------------------------------------------------------------
-- Expr → HT.NExpr
----------------------------------------------------------------------

fromExpr :: NT.Expr -> HT.NExpr
fromExpr = Fix . fromExprF

fromExprF :: NT.Expr -> HT.NExprF HT.NExpr
fromExprF NT.Abs{..}         = HT.NAbs (fromParams params) (fromExpr body)
fromExprF NT.App{..}         = HT.NApp (fromExpr func) (fromExpr arg)
fromExprF NT.Assert{..}      = HT.NAssert (fromExpr cond) (fromExpr body)
fromExprF NT.Binary{..}      = HT.NBinary (fromBinaryOp op) (fromExpr left) (fromExpr right)
fromExprF NT.Constant{..}    = HT.NConstant (fromAtom atom)
fromExprF NT.EnvPath{..}     = HT.NEnvPath (Path path)
fromExprF NT.HasAttr{..}     = HT.NHasAttr (fromExpr expr) (NE.map fromKey attrPath)
fromExprF NT.If{..}          = HT.NIf (fromExpr cond) (fromExpr then_) (fromExpr else_)
fromExprF NT.Let{..}         = HT.NLet (map fromBinding bindings) (fromExpr body)
fromExprF NT.List{..}        = HT.NList (map fromExpr items)
fromExprF NT.LiteralPath{..} = HT.NLiteralPath (Path path)
fromExprF NT.Select{..}      = HT.NSelect (fmap fromExpr _default) (fromExpr expr) (NE.map fromKey selectPath)
fromExprF NT.Set{..}         = HT.NSet (if rec then HT.Recursive else HT.NonRecursive) (map fromBinding bindings)
fromExprF NT.Str{..}         = HT.NStr (fromNString str)
fromExprF NT.Sym{..}         = HT.NSym (HT.VarName name)
fromExprF NT.SynHole{..}     = HT.NSynHole (HT.VarName name)
fromExprF NT.Unary{..}       = HT.NUnary (fromUnaryOp op) (fromExpr arg)
fromExprF NT.With{..}        = HT.NWith (fromExpr namespace) (fromExpr body)

fromAtom :: NT.Atom -> HT.NAtom
fromAtom (NT.Bool b)  = HT.NBool b
fromAtom (NT.Float f) = HT.NFloat (realToFrac f)
fromAtom (NT.Int i)   = HT.NInt i
fromAtom (NT.Uri t)   = HT.NURI t
fromAtom NT.Null      = HT.NNull

fromNString :: NT.String -> HT.NString HT.NExpr
fromNString (NT.DoubleQuoted parts) = HT.DoubleQuoted (map fromAntiquoted parts)
fromNString (NT.Indented n parts)   = HT.Indented n (map fromAntiquoted parts)

fromAntiquoted :: NT.Antiquoted Text -> HT.Antiquoted Text HT.NExpr
fromAntiquoted (NT.Interpolation e) = HT.Antiquoted (fromExpr e)
fromAntiquoted (NT.Plain t)         = HT.Plain t
fromAntiquoted NT.EscapedNewline    = HT.EscapedNewline

fromBinding :: NT.Binding -> HT.Binding HT.NExpr
fromBinding NT.Inherit{..} = HT.Inherit (fmap fromExpr scope) (coerce names) dummyPos
fromBinding NT.NamedVar{..} = HT.NamedVar (NE.map fromKey attrPath) (fromExpr value) dummyPos

fromKey :: NT.Key -> HT.NKeyName HT.NExpr
fromKey (NT.DynamicKey (NT.Interpolation e)) = HT.DynamicKey (HT.Antiquoted (fromExpr e))
fromKey (NT.DynamicKey (NT.Plain s))         = HT.DynamicKey (HT.Plain (fromNString s))
fromKey (NT.DynamicKey NT.EscapedNewline)    = HT.DynamicKey HT.EscapedNewline
fromKey (NT.StaticKey t)                     = HT.StaticKey (HT.VarName t)

fromParams :: NT.Params -> HT.Params HT.NExpr
fromParams NT.Single{..}   = HT.Param (HT.VarName paramName)
fromParams NT.ParamSet{..} = HT.ParamSet (coerce paramArgs) v (map convertParam paramList)
  where
    convertParam (name, default') = (HT.VarName name, fmap fromExpr default')
    v                             = if variadic then HT.Variadic else HT.Closed

dummyPos :: HT.NSourcePos
dummyPos = HT.NSourcePos (Path "") (HT.NPos (mkPos 1)) (HT.NPos (mkPos 1))

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

fromUnaryOp :: Text -> HT.NUnaryOp
fromUnaryOp "!"           = HT.NNot
fromUnaryOp "-"           = HT.NNeg
fromUnaryOp op            = error ("Unknown unary operator: " <> T.unpack op)

fromBinaryOp :: Text -> HT.NBinaryOp
fromBinaryOp "!="         = HT.NNEq
fromBinaryOp "&&"         = HT.NAnd
fromBinaryOp "++"         = HT.NConcat
fromBinaryOp "-"          = HT.NMinus
fromBinaryOp "//"         = HT.NUpdate
fromBinaryOp "/"          = HT.NDiv
fromBinaryOp "->"         = HT.NImpl
fromBinaryOp "<"          = HT.NLt
fromBinaryOp "<="         = HT.NLte
fromBinaryOp "=="         = HT.NEq
fromBinaryOp ">"          = HT.NGt
fromBinaryOp ">="         = HT.NGte
fromBinaryOp "*"          = HT.NMult
fromBinaryOp "||"         = HT.NOr
fromBinaryOp "+"          = HT.NPlus
fromBinaryOp op           = error ("Unknown binary operator: " <> T.unpack op)
