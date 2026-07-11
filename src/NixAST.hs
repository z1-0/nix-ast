module NixAST (
    module NixAST.Types,
    module NixAST.Convert,
    jsonToNix,
    nixToJSON,
    parseNix,
    renderNix,
    parseBatch,
    renderBatch,
) where

import Data.Aeson (eitherDecode, encode)
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

jsonToNix :: BL.ByteString -> Either Text Text
jsonToNix bs = case eitherDecode @Expr bs of
    Left err -> Left $ "JSON decode failed: " <> T.pack err
    Right expr -> renderNix <$> fromExpr expr

nixToJSON :: Text -> Either Text BL.ByteString
nixToJSON src = encode . toExpr <$> parseNix src

parseNix :: Text -> Either Text HT.NExpr
parseNix src = case parseNixText src of
    Left err -> Left (T.pack (show err))
    Right expr -> Right expr

renderNix :: HT.NExpr -> Text
renderNix = renderStrict . layoutPretty defaultLayoutOptions . prettyNix

parseBatch :: [Text] -> Either Text BL.ByteString
parseBatch srcs = encode <$> traverse (fmap toExpr . parseNix) srcs

renderBatch :: BL.ByteString -> Either Text [Text]
renderBatch bs = do
    exprs <- case eitherDecode @[Expr] bs of
        Left err -> Left (T.pack err)
        Right e  -> pure e
    traverse (fmap renderNix . fromExpr) exprs
