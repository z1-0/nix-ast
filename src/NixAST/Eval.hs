module NixAST.Eval (evalAST, evalASTs) where

import Control.Exception (IOException, try)
import Data.Aeson (encode, Value)
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time.Clock (getCurrentTime)
import Nix (Options, defaultOptions, nixEvalExpr)
import Nix.Json (toJSON)
import Nix.Standard (runWithBasicEffectsIO)
import Nix.String (runWithStringContextT')
import NixAST.Convert (fromExpr)
import NixAST.Types (Expr)

evalOne :: Options -> Expr -> IO (Either Text Value)
evalOne opts expr = do
    case fromExpr expr of
        Left err -> pure (Left err)
        Right nExpr -> do
            result <- try @IOException
                (runWithBasicEffectsIO opts $ do
                    val <- nixEvalExpr Nothing nExpr
                    (json, _) <- runWithStringContextT' (toJSON val)
                    pure json
                )
            pure $ case result of
                Right v -> Right v
                Left  e -> Left (T.pack (show e))

evalAST :: Expr -> IO (Either Text BL.ByteString)
evalAST expr = do
    opts <- defaultOptions <$> getCurrentTime
    res <- evalOne opts expr
    pure $ encode <$> res

evalASTs :: [Expr] -> IO (Either Text BL.ByteString)
evalASTs exprs = do
    opts <- defaultOptions <$> getCurrentTime
    results <- traverse (evalOne opts) exprs
    pure $ case sequence results of
        Left err -> Left err
        Right vals -> Right (encode vals)
