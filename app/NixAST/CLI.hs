module NixAST.CLI (
    Command (..),
    Input (..),
    opts,
    runParse,
    runRender,
) where

import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text.Encoding (encodeUtf8)
import Data.Text.IO qualified as TIO
import Data.Version (showVersion)
import NixAST
import Options.Applicative
import Paths_nix_ast (version)
import System.Exit (exitFailure)
import System.IO (stderr)

data Command
    = Parse Input
    | Render Input

data Input
    = FromFile FilePath
    | FromStdin
    | FromExpr Text
    | FromJSON Text

parseCommand :: Parser Command
parseCommand =
    hsubparser
        ( command "parse" (info (Parse <$> parseOpt) (progDesc "Parse a Nix expression to JSON AST"))
            <> command "render" (info (Render <$> renderOpt) (progDesc "Generate Nix expression from JSON AST"))
        )

parseOpt :: Parser Input
parseOpt = exprOpt <|> fileOpt <|> pure FromStdin
  where
    exprOpt =
        FromExpr
            <$> strOption
                ( long "expr"
                    <> metavar "EXPR"
                    <> help "Nix expression string"
                )

renderOpt :: Parser Input
renderOpt = jsonOpt <|> fileOpt <|> pure FromStdin
  where
    jsonOpt =
        FromJSON
            <$> strOption
                ( long "json"
                    <> metavar "JSON"
                    <> help "JSON AST string"
                )

fileOpt :: Parser Input
fileOpt =
    FromFile
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
    src <- readInput input
    case nixToJSON src of
        Left err -> die err
        Right json -> BL.putStr (json <> "\n")

runRender :: Input -> IO ()
runRender input = do
    bs <- readInputBS input
    case jsonToNix bs of
        Left err -> die err
        Right nix -> TIO.putStrLn nix

die :: Text -> IO a
die err = TIO.hPutStrLn stderr ("Error: " <> err) >> exitFailure

readInput :: Input -> IO Text
readInput (FromFile path) = TIO.readFile path
readInput FromStdin = TIO.getContents
readInput (FromExpr expr) = pure expr
readInput (FromJSON json) = pure json

readInputBS :: Input -> IO BL.ByteString
readInputBS (FromFile path) = BL.readFile path
readInputBS FromStdin = BL.getContents
readInputBS (FromExpr _) = die "--expr is only supported for parse"
readInputBS (FromJSON json) = pure (BL.fromStrict (encodeUtf8 json))
