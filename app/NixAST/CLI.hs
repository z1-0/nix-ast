module NixAST.CLI (
    Command (..),
    opts,
    runParse,
    runRender,
    runEval,
) where

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
    = Eval Input (Maybe FilePath)
    | Parse Input (Maybe FilePath)
    | Render Input (Maybe FilePath)

parseInfo :: ParserInfo Command
parseInfo = info (Parse <$> parseOpt <*> outputOpt) (progDesc "Parse Nix expression(s) to AST JSON")

renderInfo :: ParserInfo Command
renderInfo = info (Render <$> renderOpt <*> outputOpt) (progDesc "Render AST JSON to Nix source")

evalInfo :: ParserInfo Command
evalInfo = info (Eval <$> evalOpt <*> outputOpt) (progDesc "Evaluate AST JSON and output result")

parseCommand :: Parser Command
parseCommand =
    hsubparser
        ( command "parse" parseInfo
            <> command "render" renderInfo
            <> command "eval" evalInfo
        )

parseOpt :: Parser Input
parseOpt = exprOpt <|> inputOpt <|> pure (Input.fromStdin showParseHelp)
  where
    exprOpt =
        Input.fromExpr
            <$> strOption
                ( long "expr"
                    <> metavar "EXPR"
                    <> help "Nix expression string"
                )
    inputOpt =
        Input.fromInput
            <$> strOption
                ( long "input"
                    <> short 'i'
                    <> metavar "FILE"
                    <> help "JSON file containing array of Nix source file paths"
                )

renderOpt :: Parser Input
renderOpt = jsonOpt <|> inputOpt <|> pure (Input.fromStdin showRenderHelp)
  where
    jsonOpt =
        Input.fromJSON
            <$> strOption
                ( long "json"
                    <> metavar "JSON"
                    <> help "AST in JSON format"
                )
    inputOpt =
        Input.fromInput
            <$> strOption
                ( long "input"
                    <> short 'i'
                    <> metavar "FILE"
                    <> help "JSON file containing array of ASTs"
                )

evalOpt :: Parser Input
evalOpt = jsonOpt <|> inputOpt <|> pure (Input.fromStdin showEvalHelp)
  where
    jsonOpt =
        Input.fromJSON
            <$> strOption
                ( long "json"
                    <> metavar "JSON"
                    <> help "AST in JSON format"
                )
    inputOpt =
        Input.fromInput
            <$> strOption
                ( long "input"
                    <> short 'i'
                    <> metavar "FILE"
                    <> help "JSON file containing array of ASTs"
                )

outputOpt :: Parser (Maybe FilePath)
outputOpt =
    optional $ strOption
        ( long "output"
            <> short 'o'
            <> metavar "FILE"
            <> help "Output file (default: stdout)"
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

runParse :: Input -> Maybe FilePath -> IO ()
runParse input out = case Input.inputMode input of
    RawNix -> do
        bs <- Input.readBytes input
        let txt = decodeUtf8 (BL.toStrict bs)
        case nixToJSON txt of
            Left err -> die ("Parse error: " <> err)
            Right json -> writeBytes out json
    ArrayInput -> do
        bs <- Input.readBytes input
        case eitherDecode @[Text] bs of
            Left err -> die ("JSON decode error: " <> pack err)
            Right paths -> do
                asts <- traverse parseFile paths
                writeBytes out (encode asts)
    _ -> die "parse --expr accepts a Nix expression; --input accepts a JSON array of paths"
  where
    parseFile path = do
        src <- TIO.readFile (unpack path)
        case parseNix src of
            Left err -> die ("Parse error (" <> path <> "): " <> err)
            Right nExpr -> pure (toExpr nExpr)

runRender :: Input -> Maybe FilePath -> IO ()
runRender input out = case Input.inputMode input of
    JSON -> do
        bs <- Input.readBytes input
        case jsonToNix bs of
            Left err -> die err
            Right nix -> writeText out nix
    ArrayInput -> do
        bs <- Input.readBytes input
        case renderBatch bs of
            Left err -> die err
            Right nixSrcs -> writeBytes out (encode nixSrcs)
    _ -> die "render --json accepts a single AST; --input accepts a JSON array of ASTs"

runEval :: Input -> Maybe FilePath -> IO ()
runEval input out = case Input.inputMode input of
    JSON -> do
        bs <- Input.readBytes input
        case eitherDecode @Expr bs of
            Left err -> die (pack err)
            Right expr -> do
                result <- evalAST expr
                case result of
                    Left err -> die err
                    Right json -> writeBytes out json
    ArrayInput -> do
        bs <- Input.readBytes input
        case eitherDecode @[Expr] bs of
            Left err -> die (pack err)
            Right exprs -> do
                result <- evalASTs exprs
                case result of
                    Left err -> die err
                    Right json -> writeBytes out json
    _ -> die "eval --json accepts a single AST; --input accepts a JSON array of ASTs"

writeBytes :: Maybe FilePath -> BL.ByteString -> IO ()
writeBytes Nothing  bs = BL.putStr (bs <> "\n")
writeBytes (Just p) bs = BL.writeFile p bs

writeText :: Maybe FilePath -> Text -> IO ()
writeText Nothing  t = TIO.putStrLn t
writeText (Just p) t = TIO.writeFile p t

die :: Text -> IO a
die err = TIO.hPutStrLn stderr ("Error: " <> err) >> exitFailure

showParseHelp :: IO a
showParseHelp = showSubcommandHelp (Parse <$> parseOpt <*> outputOpt)

showRenderHelp :: IO a
showRenderHelp = showSubcommandHelp (Render <$> renderOpt <*> outputOpt)

showEvalHelp :: IO a
showEvalHelp = showSubcommandHelp (Eval <$> evalOpt <*> outputOpt)

showSubcommandHelp :: Parser Command -> IO a
showSubcommandHelp p = do
    TIO.hPutStrLn stderr $ pack $ renderHelp 80 (parserHelp defaultPrefs p)
    exitFailure
