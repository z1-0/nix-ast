{-# LANGUAGE OverloadedStrings #-}

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
    | Gen Input

data Input
    = FromFile FilePath
    | FromStdin

parseCommand :: Parser Command
parseCommand =
    hsubparser
        ( command "parse" (info (Parse <$> inputOpt) (progDesc "Parse a Nix expression to JSON AST"))
            <> command "gen" (info (Gen <$> inputOpt) (progDesc "Generate Nix expression from JSON AST"))
        )

inputOpt :: Parser Input
inputOpt = fromFile <|> pure FromStdin
  where
    fromFile =
        FromFile
            <$> strOption
                ( long "file"
                    <> short 'f'
                    <> metavar "FILE"
                    <> help "Input file (default: stdin)"
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
        Gen input -> runGen input

runParse :: Input -> IO ()
runParse input = do
    src <- readInput input
    case nixToJSON src of
        Left err -> die err
        Right json -> BL.putStrLn json

runGen :: Input -> IO ()
runGen input = do
    bs <- readInputBS input
    case jsonToNix bs of
        Left err -> die err
        Right nix -> TIO.putStrLn nix

die :: T.Text -> IO a
die err = TIO.hPutStrLn stderr ("Error: " <> err) >> exitFailure

readInput :: Input -> IO T.Text
readInput (FromFile path) = TIO.readFile path
readInput FromStdin = TIO.getContents

readInputBS :: Input -> IO BL.ByteString
readInputBS (FromFile path) = BL.readFile path
readInputBS FromStdin = BL.getContents
