module NixAST.CLI (
    Command (..),
    checkTty,
    opts,
    runParse,
    runRender,
    runEval,
) where

import Control.Monad (forM_, when)
import Data.Aeson (eitherDecode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text, pack, unpack)

import Data.Text.IO qualified as TIO
import Data.Version (showVersion)
import NixAST
import NixAST.Eval (evalAST, evalASTs)
import NixAST.Input (Input (..), InputMode (..), readInput)
import Options.Applicative
import Options.Applicative.Help (parserHelp, renderHelp)
import Paths_nix_ast (version)
import System.Exit (exitFailure)
import System.IO (hIsTerminalDevice, stdin, stderr)

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
parseOpt = exprOpt <|> pure (FromStdin BatchJSON)
  where
    exprOpt =
        FromArg RawNix
            <$> strOption
                ( long "expr"
                    <> metavar "EXPR"
                    <> help "Nix expression string"
                )

renderOpt :: Parser Input
renderOpt = jsonOpt <|> pure (FromStdin BatchJSON)
  where
    jsonOpt =
        FromArg JSON
            <$> strOption
                ( long "json"
                    <> metavar "JSON"
                    <> help "AST in JSON format"
                )

evalOpt :: Parser Input
evalOpt = jsonOpt <|> pure (FromStdin BatchJSON)
  where
    jsonOpt =
        FromArg JSON
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

checkTty :: Command -> IO ()
checkTty cmd = do
    isTty <- hIsTerminalDevice stdin
    when isTty $ case cmd of
        Parse (FromStdin _) -> showSubcommandHelp parseInfo
        Render (FromStdin _) _ -> showSubcommandHelp renderInfo
        Eval (FromStdin _) -> showSubcommandHelp evalInfo
        _ -> pure ()

showSubcommandHelp :: ParserInfo a -> IO b
showSubcommandHelp p = do
    TIO.hPutStrLn stderr $ pack $ renderHelp 80 (parserHelp defaultPrefs (infoParser p))
    exitFailure

runParse :: Input -> IO ()
runParse input = case input of
    FromArg RawNix txt -> case nixToJSON txt of
        Left err -> die ("Parse error: " <> err)
        Right json -> BL.putStr (json <> "\n")
    FromStdin _ -> do
        bs <- BL.getContents
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
    bs <- readInput input
    case (input, outDir) of
        (FromArg JSON _, Nothing) -> do
            case eitherDecode @Expr bs of
                Left err -> die (pack err)
                Right expr -> case fromExpr expr of
                    Left err -> die err
                    Right nExpr -> TIO.putStrLn (renderNix nExpr)
        (FromArg JSON _, Just _) ->
            die "--out-dir is not supported with --json; use --json to render a single AST to stdout"
        (FromStdin _, Nothing) -> do
            case eitherDecode @[Expr] bs of
                Left err -> die (pack err)
                Right asts -> do
                    results <- traverse (pure . fromExpr) asts
                    case sequence results of
                        Left err -> die err
                        Right nExprs -> BL.putStr (encode (map renderNix nExprs) <> "\n")
        (FromStdin _, Just dir) -> do
            case eitherDecode @[Expr] bs of
                Left err -> die (pack err)
                Right asts ->
                    forM_ (zip [(0 :: Int) ..] asts) $ \(i, ast) ->
                        case fromExpr ast of
                            Left err -> die err
                            Right nExpr -> TIO.writeFile (dir <> "/" <> show i <> ".nix") (renderNix nExpr)
        _ -> die "render expects --json JSON or stdin with JSON array of ASTs"

runEval :: Input -> IO ()
runEval input = do
    bs <- readInput input
    case input of
        FromArg JSON _ -> do
            case eitherDecode @Expr bs of
                Left err -> die (pack err)
                Right expr -> do
                    result <- evalAST expr
                    case result of
                        Left err -> die err
                        Right json -> BL.putStr (json <> "\n")
        FromStdin _ -> do
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
