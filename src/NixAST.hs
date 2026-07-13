module NixAST (
    module NixAST.Types,
    module NixAST.Convert,
    nixToJSON,
    parseNix,
    renderNix,
) where

import Data.Aeson (encode)
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text qualified as T
import Nix.Expr.Types qualified as HT
import Nix.Parser (parseNixText)
import Nix.Pretty (prettyNix)
import NixAST.Convert
import NixAST.Types
import Prettyprinter (defaultLayoutOptions, layoutPretty)
import Prettyprinter.Render.Text (renderStrict)

nixToJSON :: Text -> Either Text BL.ByteString
nixToJSON src = encode . toExpr <$> parseNix src

parseNix :: Text -> Either Text HT.NExpr
parseNix src = case parseNixText src of
    Left err -> Left (T.pack (show err))
    Right expr -> Right expr

renderNix :: HT.NExpr -> Text
renderNix = renderStrict . layoutPretty defaultLayoutOptions . prettyNix
