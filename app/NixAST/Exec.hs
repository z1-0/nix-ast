module NixAST.Exec (exec) where

import Control.Concurrent (newQSem, signalQSem, waitQSem)
import Control.Concurrent.Async (mapConcurrently)
import Control.Exception (bracket_)
import Control.Monad (forM_)
import Data.Aeson (FromJSON, eitherDecode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text, pack, unpack)
import Data.Text.Encoding (encodeUtf8)
import Data.Text.IO qualified as TIO
import NixAST
import NixAST.Command (Command (..))
import NixAST.Eval (evalAST, evalASTs)
import System.Exit (exitFailure)
import System.IO (stderr)

data AppError
    = ConvErr   Text
    | DecodeErr Text
    | EvalErr   Text
    | ParseErr  Text
    | UsageErr  Text

displayError :: AppError -> Text
displayError = \case
    ConvErr   t -> "Conversion error: " <> t
    DecodeErr t -> "Decode error: "     <> t
    EvalErr   t -> "Eval error: "       <> t
    ParseErr  t -> "Parse error: "      <> t
    UsageErr  t -> t

die :: AppError -> IO a
die err = TIO.hPutStrLn stderr (displayError err) >> exitFailure

dieLeft :: (e -> AppError) -> Either e a -> IO a
dieLeft _ (Right x) = pure x
dieLeft f (Left e) = die (f e)

exec :: Command -> IO ()
exec = \case
    Eval src -> execEval src
    Parse src -> execParse src
    Render src dir -> execRender src dir

execEval :: Maybe Text -> IO ()
execEval (Just json) = do
    expr <- dieLeft (DecodeErr . pack) (eitherDecode @Expr (BL.fromStrict . encodeUtf8 $ json))
    result <- evalAST expr
    case result of
        Left err -> die (EvalErr err)
        Right bs -> BL.putStr (bs <> "\n")
execEval Nothing = do
    asts <- getStdinJSON @Expr
    result <- evalASTs asts
    case result of
        Left err -> die (EvalErr err)
        Right bs -> BL.putStr (bs <> "\n")

execParse :: Maybe Text -> IO ()
execParse (Just expr) =
    case nixToJSON expr of
        Left err -> die (ParseErr err)
        Right out -> BL.putStr (out <> "\n")
execParse Nothing = do
    paths <- getStdinJSON @Text
    sem <- newQSem 50
    asts <- mapConcurrently (bracket_ (waitQSem sem) (signalQSem sem) . parseFile) paths
    BL.putStr (encode asts <> "\n")
  where
    parseFile path = do
        src <- TIO.readFile (unpack path)
        case parseNix src of
            Left err -> die (ParseErr $ path <> ": " <> err)
            Right nixExpr -> pure (toExpr nixExpr)

execRender :: Maybe Text -> Maybe FilePath -> IO ()
execRender (Just _) (Just _) =
    die (UsageErr "--out-dir is not supported with --json; render a single AST to stdout")
execRender (Just json) Nothing = do
    expr <- dieLeft (DecodeErr . pack) (eitherDecode @Expr (BL.fromStrict . encodeUtf8 $ json))
    nixExpr <- dieLeft ConvErr (fromExpr expr)
    TIO.putStrLn (renderNix nixExpr)
execRender Nothing outDir = do
    asts <- getStdinJSON @Expr
    case outDir of
        Nothing -> do
            nixExprs <- traverse (dieLeft ConvErr . fromExpr) asts
            BL.putStr (encode (map renderNix nixExprs) <> "\n")
        Just dir ->
            forM_ (zip [(0 :: Int) ..] asts) $ \(i, ast) -> do
                nixExpr <- dieLeft ConvErr (fromExpr ast)
                TIO.writeFile (dir <> "/" <> show i <> ".nix") (renderNix nixExpr)

getStdinJSON :: forall a. (FromJSON a) => IO [a]
getStdinJSON = do
    bs <- BL.getContents
    dieLeft (DecodeErr . pack) (eitherDecode @[a] bs)
