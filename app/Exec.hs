module Exec (exec) where

import Command                     (Command (..))
import Control.Concurrent          (newQSem, signalQSem, waitQSem)
import Control.Concurrent.Async    (mapConcurrently)
import Control.Exception           (IOException, bracket_, try)
import System.IO.Error             (isDoesNotExistError)
import Control.Monad               (forM_)
import Data.Aeson                  (FromJSON, eitherDecode, encode)
import Data.ByteString             qualified as BS
import Data.ByteString.Lazy        qualified as BL
import Data.Text                   (Text, pack, unpack)
import Data.Text.Encoding          (decodeUtf8', encodeUtf8)
import NixAST
import NixAST.Eval                 (evalAST, evalASTs)
import System.Exit                 (exitFailure)
import System.IO                   (stderr)

data AppError
    = ConvErr   Text
    | DecodeErr Text
    | EvalErr   Text
    | IOErr     Text
    | ParseErr  Text
    | UsageErr  Text

displayError :: AppError -> Text
displayError = \case
    ConvErr   t -> "Conversion error: " <> t
    DecodeErr t -> "Decode error: "     <> t
    EvalErr   t -> "Eval error: "       <> t
    IOErr     t -> "I/O error: "        <> t
    ParseErr  t -> "Parse error: "      <> t
    UsageErr  t -> t

die :: AppError -> IO a
die err = BL.hPutStr stderr (BL.fromStrict (encodeUtf8 (displayError err)) <> "\n") >> exitFailure

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
    expr <- decodeExpr json
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
        bs <- readFileOrDie (unpack path)
        src <- dieLeft (const (ParseErr $ path <> ": invalid UTF-8")) (decodeUtf8' bs)
        case parseNix src of
            Left err -> die (ParseErr $ path <> ": " <> err)
            Right nixExpr -> pure (toExpr nixExpr)

execRender :: Maybe Text -> Maybe FilePath -> IO ()
execRender (Just _) (Just _) =
    die (UsageErr "--out-dir is not supported with --json; render a single AST to stdout")
execRender (Just json) Nothing = do
    expr <- decodeExpr json
    nixExpr <- dieLeft ConvErr (fromExpr expr)
    BL.putStr (BL.fromStrict (encodeUtf8 (renderNix nixExpr)) <> "\n")
execRender Nothing outDir = do
    asts <- getStdinJSON @Expr
    case outDir of
        Nothing -> do
            nixExprs <- traverse (dieLeft ConvErr . fromExpr) asts
            BL.putStr (encode (map renderNix nixExprs) <> "\n")
        Just dir ->
            forM_ (zip [(0 :: Int) ..] asts) $ \(i, ast) -> do
                nixExpr <- dieLeft ConvErr (fromExpr ast)
                writeFileOrDie (dir <> "/" <> show i <> ".nix") (encodeUtf8 (renderNix nixExpr) <> "\n")

readFileOrDie :: FilePath -> IO BS.ByteString
readFileOrDie p = do
    result <- try @IOException (BS.readFile p)
    case result of
        Left e | isDoesNotExistError e -> die (IOErr (pack p <> ": no such file"))
        Left e -> die (IOErr (pack p <> ": " <> pack (show e)))
        Right bs -> pure bs

writeFileOrDie :: FilePath -> BS.ByteString -> IO ()
writeFileOrDie p bs = do
    result <- try @IOException (BS.writeFile p bs)
    case result of
        Left e | isDoesNotExistError e -> die (IOErr (pack p <> ": no such directory"))
        Left e -> die (IOErr (pack p <> ": " <> pack (show e)))
        Right () -> pure ()

decodeExpr :: Text -> IO Expr
decodeExpr json = dieLeft (DecodeErr . pack) (eitherDecode @Expr (BL.fromStrict (encodeUtf8 json)))

getStdinJSON :: forall a. (FromJSON a) => IO [a]
getStdinJSON = do
    bs <- BL.getContents
    dieLeft (DecodeErr . pack) (eitherDecode @[a] bs)
