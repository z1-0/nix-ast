module Main (main) where

import Data.ByteString.Lazy.Char8 qualified as BL
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import NixAST
import Options.Applicative
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdin, stdout, utf8)

data Command
    = Parse Input
    | Render Input

data Input
    = FromFile FilePath
    | FromStdin
    | FromExpr T.Text
    | FromJSON T.Text

parseCommand :: Parser Command
parseCommand =
    hsubparser
        ( command "parse" (info (Parse <$> parseOpt) (progDesc "Parse a Nix expression to JSON AST"))
            <> command "render" (info (Render <$> renderOpt) (progDesc "Generate Nix expression from JSON AST"))
        )

parseOpt :: Parser Input
parseOpt = exprOpt <|> fileOpt <|> pure FromStdin
  where
    fileOpt =
        FromFile
            <$> strOption
                ( long "file"
                    <> short 'f'
                    <> metavar "FILE"
                    <> help "Input file (default: stdin)"
                )
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
    fileOpt =
        FromFile
            <$> strOption
                ( long "file"
                    <> short 'f'
                    <> metavar "FILE"
                    <> help "Input file (default: stdin)"
                )
    jsonOpt =
        FromJSON
            <$> strOption
                ( long "json"
                    <> metavar "JSON"
                    <> help "JSON AST string"
                )

opts :: ParserInfo Command
opts =
    info
        (parseCommand <**> helper)
        ( fullDesc
            <> progDesc "nix-ast: Parse and generate Nix expressions via hnix"
            <> header "nix-ast - Nix AST tool"
        )

main :: IO ()
main = do
    hSetEncoding stdin utf8
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    cmd <- execParser opts
    case cmd of
        Parse input -> runParse input
        Render input -> runRender input

runParse :: Input -> IO ()
runParse input = do
    src <- readInput input
    case nixToJSON src of
        Left err -> die err
        Right json -> BL.putStrLn json

runRender :: Input -> IO ()
runRender input = do
    bs <- readInputBS input
    case jsonToNix bs of
        Left err -> die err
        Right nix -> TIO.putStrLn nix

die :: T.Text -> IO a
die err = TIO.hPutStrLn stderr ("Error: " <> err) >> exitFailure

readInput :: Input -> IO T.Text
readInput (FromFile path) = TIO.readFile path
readInput FromStdin = TIO.getContents
readInput (FromExpr expr) = pure expr
readInput (FromJSON json) = pure json

readInputBS :: Input -> IO BL.ByteString
readInputBS (FromFile path) = BL.readFile path
readInputBS FromStdin = BL.getContents
readInputBS (FromExpr _) = die (T.pack "--expr is only supported for parse")
readInputBS (FromJSON json) = pure (BL.pack (T.unpack json))
