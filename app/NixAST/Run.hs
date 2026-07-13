module NixAST.Run (runCommand) where

import Control.Monad                (forM_)
import Data.Aeson                   (FromJSON, eitherDecode, encode)
import Data.ByteString.Lazy         qualified as BL
import Data.Text                    (Text, pack, unpack)
import Data.Text.Encoding           (encodeUtf8)
import Data.Text.IO                 qualified as TIO
import NixAST
import NixAST.CLI                   (Command (..))
import NixAST.Eval                  (evalAST, evalASTs)
import System.Exit                  (exitFailure)
import System.IO                    (stderr)

data AppError
    = ParseErr  Text
    | DecodeErr Text
    | ConvErr   Text
    | EvalErr   Text
    | UsageErr  Text

displayError :: AppError -> Text
displayError = \case
    ParseErr  t  -> "Parse error: "       <> t
    DecodeErr t  -> "Decode error: "      <> t
    ConvErr   t  -> "Conversion error: "  <> t
    EvalErr   t  -> "Eval error: "        <> t
    UsageErr  t  -> t

die :: AppError -> IO a
die err = TIO.hPutStrLn stderr (displayError err) >> exitFailure

dieLeft :: (e -> AppError) -> Either e a -> IO a
dieLeft _ (Right x) = pure x
dieLeft f (Left  e) = die (f e)

runCommand :: Command -> IO ()
runCommand = \case
    Parse  src      -> runParse  src
    Render src dir  -> runRender src dir
    Eval   src      -> runEval   src

runParse :: Maybe Text -> IO ()
runParse (Just expr) =
    case nixToJSON expr of
        Left  err -> die (ParseErr err)
        Right out -> BL.putStr (out <> "\n")
runParse Nothing = do
    paths <- getStdinJSON @Text
    asts  <- traverse parseFile paths
    BL.putStr (encode asts <> "\n")
  where
    parseFile path = do
        src <- TIO.readFile (unpack path)
        case parseNix src of
            Left  err     -> die (ParseErr $ path <> ": " <> err)
            Right nixExpr -> pure (toExpr nixExpr)

runRender :: Maybe Text -> Maybe FilePath -> IO ()
runRender (Just _)   (Just _) =
    die (UsageErr "--out-dir is not supported with --json; render a single AST to stdout")
runRender (Just json) Nothing  = do
    expr    <- dieLeft (DecodeErr . pack) (eitherDecode @Expr (encodeUtf8' json))
    nixExpr <- dieLeft ConvErr (fromExpr expr)
    TIO.putStrLn (renderNix nixExpr)
runRender Nothing    outDir    = do
    asts <- getStdinJSON @Expr
    case outDir of
        Nothing -> do
            nixExprs <- traverse (dieLeft ConvErr . fromExpr) asts
            BL.putStr (encode (map renderNix nixExprs) <> "\n")
        Just dir ->
            forM_ (zip [(0 :: Int) ..] asts) $ \(i, ast) -> do
                nixExpr <- dieLeft ConvErr (fromExpr ast)
                TIO.writeFile (dir <> "/" <> show i <> ".nix") (renderNix nixExpr)

runEval :: Maybe Text -> IO ()
runEval (Just json) = do
    expr   <- dieLeft (DecodeErr . pack) (eitherDecode @Expr (encodeUtf8' json))
    result <- evalAST expr
    case result of
        Left  err -> die (EvalErr err)
        Right bs  -> BL.putStr (bs <> "\n")
runEval Nothing = do
    asts   <- getStdinJSON @Expr
    result <- evalASTs asts
    case result of
        Left  err -> die (EvalErr err)
        Right bs  -> BL.putStr (bs <> "\n")

encodeUtf8' :: Text -> BL.ByteString
encodeUtf8' = BL.fromStrict . encodeUtf8

getStdinJSON :: forall a. FromJSON a => IO [a]
getStdinJSON = do
    bs <- BL.getContents
    dieLeft (DecodeErr . pack) (eitherDecode @[a] bs)
