module NixAST.CLI (
    Command (..),
    opts,
    runParse,
    runRender,
    runEval,
) where

import Control.Monad (forM_)
import Data.Aeson (eitherDecode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text, pack, unpack)
import Data.Text.Encoding (decodeUtf8)
import Data.Text.IO qualified as TIO
import Data.Version (showVersion)
import NixAST
import NixAST.Eval (evalAST, evalASTs)
import NixAST.Input (Input, InputMode (..))
import NixAST.Input qualified as Input
import Options.Applicative
import Options.Applicative.Help (parserHelp, renderHelp)
import Paths_nix_ast (version)
import System.Exit (exitFailure)
import System.IO (stderr)

data Command
    = Eval Input
    | Parse Input
    | Render Input (Maybe FilePath)

parseInfo :: ParserInfo Command
parseInfo = info (Parse <$> parseOpt) (progDesc "Parse Nix expression to AST JSON")

renderInfo :: ParserInfo Command
renderInfo = info (Render <$> renderOpt <*> outDirOpt) (progDesc "Render AST JSON to Nix source")

evalInfo :: ParserInfo Command
evalInfo = info (Eval <$> evalOpt) (progDesc "Evaluate AST JSON and output result")

parseCommand :: Parser Command
parseCommand =
    hsubparser
        ( command "parse" parseInfo
            <> command "render" renderInfo
            <> command "eval" evalInfo
        )

parseOpt :: Parser Input
parseOpt = exprOpt <|> pure (Input.stdinInput showParseHelp)
  where
    exprOpt =
        Input.fromExpr
            <$> strOption
                ( long "expr"
                    <> metavar "EXPR"
                    <> help "Nix expression string"
                )

renderOpt :: Parser Input
renderOpt = jsonOpt <|> pure (Input.stdinInput showRenderHelp)
  where
    jsonOpt =
        Input.fromJSON
            <$> strOption
                ( long "json"
                    <> metavar "JSON"
                    <> help "AST in JSON format"
                )

evalOpt :: Parser Input
evalOpt = jsonOpt <|> pure (Input.stdinInput showEvalHelp)
  where
    jsonOpt =
        Input.fromJSON
            <$> strOption
                ( long "json"
                    <> metavar "JSON"
                    <> help "AST in JSON format"
                )

outDirOpt :: Parser (Maybe FilePath)
outDirOpt =
    optional $ strOption
        ( long "out-dir"
            <> metavar "DIR"
            <> help "Output directory for rendered files (default: stdout)"
        )

versionOpt :: Parser (a -> a)
versionOpt =
    infoOption
        (showVersion version)
        ( long "version"
            <> short 'v'
            <> help "Show version"
        )

opts :: ParserInfo Command
opts =
    info
        (parseCommand <**> helper <**> versionOpt)
        ( progDesc "nix-ast: Parse and generate Nix expressions via hnix"
            <> header "nix-ast - Nix AST tool"
        )

runParse :: Input -> IO ()
runParse input = case Input.inputMode input of
    RawNix -> do
        bs <- Input.readBytes input
        let txt = decodeUtf8 (BL.toStrict bs)
        case nixToJSON txt of
            Left err -> die ("Parse error: " <> err)
            Right json -> BL.putStr (json <> "\n")
    BatchJSON -> do
        bs <- Input.readBytes input
        case eitherDecode @[Text] bs of
            Left err -> die (pack err)
            Right paths -> do
                asts <- traverse parseFile paths
                BL.putStr (encode asts <> "\n")
    _ -> die "parse expects --expr EXPR or stdin with JSON array of file paths"
  where
    parseFile path = do
        src <- TIO.readFile (unpack path)
        case parseNix src of
            Left err -> die ("Parse error (" <> path <> "): " <> err)
            Right nExpr -> pure (toExpr nExpr)

runRender :: Input -> Maybe FilePath -> IO ()
runRender input outDir = do
    bs <- Input.readBytes input
    case (Input.inputMode input, outDir) of
        (JSON, Nothing) -> do
            case eitherDecode @Expr bs of
                Left err -> die (pack err)
                Right expr -> case fromExpr expr of
                    Left err -> die err
                    Right nExpr -> TIO.putStrLn (renderNix nExpr)
        (JSON, Just _) -> die "--out-dir is not supported with --json; use --json to render a single AST to stdout"
        (BatchJSON, Nothing) -> do
            case eitherDecode @[Expr] bs of
                Left err -> die (pack err)
                Right asts -> do
                    results <- traverse (pure . fromExpr) asts
                    case sequence results of
                        Left err -> die err
                        Right nExprs -> BL.putStr (encode (map renderNix nExprs) <> "\n")
        (BatchJSON, Just dir) -> do
            case eitherDecode @[Expr] bs of
                Left err -> die (pack err)
                Right asts ->
                    forM_ (zip [(0 :: Int) ..] asts) $ \(i, ast) ->
                        case fromExpr ast of
                            Left err -> die err
                            Right nExpr -> TIO.writeFile (dir <> "/" <> show i <> ".nix") (renderNix nExpr)
        _ -> die "render expects --json JSON or stdin with JSON array of ASTs"

runEval :: Input -> IO ()
runEval input = case Input.inputMode input of
    JSON -> do
        bs <- Input.readBytes input
        case eitherDecode @Expr bs of
            Left err -> die (pack err)
            Right expr -> do
                result <- evalAST expr
                case result of
                    Left err -> die err
                    Right json -> BL.putStr (json <> "\n")
    BatchJSON -> do
        bs <- Input.readBytes input
        case eitherDecode @[Expr] bs of
            Left err -> die (pack err)
            Right exprs -> do
                result <- evalASTs exprs
                case result of
                    Left err -> die err
                    Right json -> BL.putStr (json <> "\n")
    _ -> die "eval expects --json JSON or stdin with JSON array of ASTs"

die :: Text -> IO a
die err = TIO.hPutStrLn stderr ("Error: " <> err) >> exitFailure

showParseHelp :: IO a
showParseHelp = showSubcommandHelp parseInfo

showRenderHelp :: IO a
showRenderHelp = showSubcommandHelp renderInfo

showEvalHelp :: IO a
showEvalHelp = showSubcommandHelp evalInfo

showSubcommandHelp :: ParserInfo Command -> IO a
showSubcommandHelp p = do
    TIO.hPutStrLn stderr $ pack $ renderHelp 80 (parserHelp defaultPrefs (infoParser p))
    exitFailure
