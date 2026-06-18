module NixAST.Types (
    Antiquoted (..),
    Atom (..),
    Binding (..),
    Expr (..),
    KeyName (..),
    String (..),
    Params (..),
    AttrPath,
    ParamSet,
    VarName,
) where

import Data.Aeson (FromJSON, ToJSON)
import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import GHC.Generics (Generic)
import Nix.Expr.Types qualified as HT
import Prelude hiding (String)

type VarName = HT.VarName
type AttrPath = NE.NonEmpty KeyName
type ParamSet = HT.ParamSet Expr

data Expr
    = Abs {params :: Params, body :: Expr}
    | App {func :: Expr, arg :: Expr}
    | Assert {cond :: Expr, body :: Expr}
    | Binary {op :: Text, left :: Expr, right :: Expr}
    | Constant {atom :: Atom}
    | EnvPath {path :: FilePath}
    | HasAttr {expr :: Expr, attrPath :: AttrPath}
    | If {cond :: Expr, thenExpr :: Expr, elseExpr :: Expr}
    | Let {bindings :: [Binding], body :: Expr}
    | List {items :: [Expr]}
    | LiteralPath {path :: FilePath}
    | Select {defaultValue :: Maybe Expr, expr :: Expr, selectPath :: AttrPath}
    | Set {recursive :: Bool, bindings :: [Binding]}
    | Str {value :: String}
    | Sym {name :: VarName}
    | SynHole {name :: VarName}
    | Unary {op :: Text, arg :: Expr}
    | With {namespace :: Expr, body :: Expr}
    deriving (Generic, Show, Eq, ToJSON, FromJSON)

data Atom
    = Bool Bool
    | Float Double
    | Int Integer
    | Null
    | Uri Text
    deriving (Generic, Show, Eq, ToJSON, FromJSON)

data Binding
    = Inherit {scope :: Maybe Expr, names :: [VarName]}
    | NamedVar {attrPath :: AttrPath, value :: Expr}
    deriving (Generic, Show, Eq, ToJSON, FromJSON)

data KeyName
    = DynamicKey {antiquoted :: Antiquoted String Expr}
    | StaticKey {keyName :: VarName}
    deriving (Generic, Show, Eq, ToJSON, FromJSON)

data Params
    = ParamSet {paramSetName :: Maybe VarName, variadic :: Bool, params :: ParamSet}
    | Param {paramName :: VarName}
    deriving (Generic, Show, Eq, ToJSON, FromJSON)

data String
    = DoubleQuoted {parts :: [Antiquoted Text Expr]}
    | Indented {indent :: Int, parts :: [Antiquoted Text Expr]}
    deriving (Generic, Show, Eq, ToJSON, FromJSON)

data Antiquoted v r
    = Plain v
    | Antiquoted r
    | EscapedNewline
    deriving (Generic, Show, Eq, ToJSON, FromJSON)
