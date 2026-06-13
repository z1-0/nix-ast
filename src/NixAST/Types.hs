{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DuplicateRecordFields #-}

module NixAST.Types (
    Antiquoted (..),
    Atom (..),
    Binding (..),
    Expr (..),
    Key (..),
    Params (..),
    String (..),
) where

import Data.Aeson (FromJSON, ToJSON)
import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import GHC.Generics (Generic)
import Prelude hiding (String)

data Expr
    = Abs {params :: Params, body :: Expr}
    | App {func :: Expr, arg :: Expr}
    | Assert {cond :: Expr, body :: Expr}
    | Binary {op :: Text, left :: Expr, right :: Expr}
    | Constant {atom :: Atom}
    | EnvPath {path :: FilePath}
    | HasAttr {expr :: Expr, attrPath :: NE.NonEmpty Key}
    | If {cond :: Expr, then_ :: Expr, else_ :: Expr}
    | Let {bindings :: [Binding], body :: Expr}
    | List {items :: [Expr]}
    | LiteralPath {path :: FilePath}
    | Select {expr :: Expr, selectPath :: NE.NonEmpty Key, _default :: Maybe Expr}
    | Set {rec :: Bool, bindings :: [Binding]}
    | Str {str :: String}
    | Sym {name :: Text}
    | SynHole {name :: Text}
    | Unary {op :: Text, arg :: Expr}
    | With {namespace :: Expr, body :: Expr}
    deriving (Generic, Show, Eq)
    deriving anyclass (ToJSON, FromJSON)

data Atom
    = Bool Bool
    | Float Double
    | Int Integer
    | Null
    | Uri Text
    deriving (Generic, Show, Eq)
    deriving anyclass (ToJSON, FromJSON)

data Binding
    = Inherit {scope :: Maybe Expr, names :: [Text]}
    | NamedVar {attrPath :: NE.NonEmpty Key, value :: Expr}
    deriving (Generic, Show, Eq)
    deriving anyclass (ToJSON, FromJSON)

data Key
    = DynamicKey (Antiquoted String)
    | StaticKey Text
    deriving (Generic, Show, Eq)
    deriving anyclass (ToJSON, FromJSON)

data Params
    = ParamSet {paramArgs :: Maybe Text, paramList :: [(Text, Maybe Expr)], variadic :: Bool}
    | Single {paramName :: Text}
    deriving (Generic, Show, Eq)
    deriving anyclass (ToJSON, FromJSON)

data String
    = DoubleQuoted [Antiquoted Text]
    | Indented Int [Antiquoted Text]
    deriving (Generic, Show, Eq)
    deriving anyclass (ToJSON, FromJSON)

data Antiquoted v
    = Plain v
    | EscapedNewline
    | Interpolation Expr
    deriving (Generic, Show, Eq)
    deriving anyclass (ToJSON, FromJSON)
