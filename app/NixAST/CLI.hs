module NixAST.CLI (
    Command (..),
    opts,
    runParse,
    runRender,
    runEval,
    runEvalBatch,
    runParseBatch,
    runRenderBatch,
) where

import Control.Concurrent (newQSem, signalQSem, waitQSem)
import Control.Concurrent.Async (mapConcurrently)
import Control.Exception (bracket_)
import Data.Aeson (eitherDecode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text, pack, unpack)
import Data.Text.IO qualified as TIO
import Data.Version (showVersion)
import NixAST
import NixAST.Eval (evalAST, evalASTs)
import NixAST.Input (Input)
import NixAST.Input qualified as Input
import Options.Applicative
import Options.Applicative.Help (parserHelp, renderHelp)
import Paths_nix_ast (version)
import System.Exit (exitFailure)
import System.IO (stderr)

data Command
    = Eval Input
    | EvalBatch Input
    | Parse Input
    | ParseBatch Input
    | Render Input
    | RenderBatch Input

parseInfo :: ParserInfo Command
parseInfo = info (Parse <$> parseOpt) (progDesc "Parse a Nix expression to AST")

renderInfo :: ParserInfo Command
renderInfo = info (Render <$> renderOpt) (progDesc "Generate Nix expression from AST")

evalInfo :: ParserInfo Command
evalInfo = info (Eval <$> renderOpt) (progDesc "Evaluate an AST and output JSON result")

evalBatchInfo :: ParserInfo Command
evalBatchInfo = info (EvalBatch <$> renderOpt) (progDesc "Evaluate ASTs from a JSON array and output JSON array result")

parseBatchInfo :: ParserInfo Command
parseBatchInfo = info (ParseBatch <$> renderOpt) (progDesc "Parse Nix files listed in a JSON array, output JSON array of ASTs")

renderBatchInfo :: ParserInfo Command
renderBatchInfo = info (RenderBatch <$> renderOpt) (progDesc "Render ASTs from a JSON array, output JSON array of Nix sources")

parseCommand :: Parser Command
parseCommand =
    hsubparser
        ( command "parse" parseInfo
            <> command "render" renderInfo
            <> command "eval" evalInfo
            <> command "eval-batch" evalBatchInfo
            <> command "parse-batch" parseBatchInfo
            <> command "render-batch" renderBatchInfo
        )

parseOpt :: Parser Input
parseOpt = exprOpt <|> fileOpt <|> pure (Input.fromStdin showParseHelp showParseHelp)
  where
    exprOpt =
        Input.fromExpr
            <$> strOption
                ( long "expr"
                    <> metavar "EXPR"
                    <> help "Nix expression string"
                )

renderOpt :: Parser Input
renderOpt = jsonOpt <|> fileOpt <|> pure (Input.fromStdin showRenderHelp showRenderHelp)
  where
    jsonOpt =
        Input.fromJSON
            <$> strOption
                ( long "json"
                    <> metavar "JSON"
                    <> help "AST in JSON format"
                )

fileOpt :: Parser Input
fileOpt =
    Input.fromFile
        <$> strOption
            ( long "file"
                <> short 'f'
                <> metavar "FILE"
                <> help "Input file (default: stdin)"
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
runParse input = do
    src <- Input.readText input
    case nixToJSON src of
        Left err -> die err
        Right json -> BL.putStr (json <> "\n")

runRender :: Input -> IO ()
runRender input = do
    bs <- Input.readBytes input
    case jsonToNix bs of
        Left err -> die err
        Right nix -> TIO.putStrLn nix

runEval :: Input -> IO ()
runEval input = do
    bs <- Input.readBytes input
    case eitherDecode @Expr bs of
        Left err -> die (pack err)
        Right expr -> do
            result <- evalAST expr
            case result of
                Left err -> die err
                Right json -> BL.putStr (json <> "\n")

runEvalBatch :: Input -> IO ()
runEvalBatch input = do
    bs <- Input.readBytes input
    case eitherDecode @[Expr] bs of
        Left err -> die (pack err)
        Right exprs -> do
            result <- evalASTs exprs
            case result of
                Left err -> die err
                Right json -> BL.putStr (json <> "\n")

runParseBatch :: Input -> IO ()
runParseBatch input = do
    bs <- Input.readBytes input
    case eitherDecode @[Text] bs of
        Left err -> die (pack err)
        Right paths -> do
            sem <- newQSem 50
            srcs <- mapConcurrently (bracket_ (waitQSem sem) (signalQSem sem) . TIO.readFile . unpack) paths
            case parseBatch srcs of
                Left err -> die err
                Right json -> BL.putStr (json <> "\n")

runRenderBatch :: Input -> IO ()
runRenderBatch input = do
    bs <- Input.readBytes input
    case renderBatch bs of
        Left err -> die err
        Right nixSrcs -> BL.putStr (encode nixSrcs <> "\n")

die :: Text -> IO a
die err = TIO.hPutStrLn stderr ("Error: " <> err) >> exitFailure

showParseHelp :: IO a
showParseHelp = showSubcommandHelp (Parse <$> parseOpt)

showRenderHelp :: IO a
showRenderHelp = showSubcommandHelp (Render <$> renderOpt)

showSubcommandHelp :: Parser Command -> IO a
showSubcommandHelp p = do
    TIO.hPutStrLn stderr $ pack $ renderHelp 80 (parserHelp defaultPrefs p)
    exitFailure
