module NixAST.CLI (
    Command (..),
    checkTty,
    cliParser,
) where

import Control.Monad (when)
import Data.Text (Text, pack)
import Data.Text.IO qualified as TIO
import Data.Version (showVersion)
import Options.Applicative
import Options.Applicative.Help (parserHelp, renderHelp)
import Paths_nix_ast (version)
import System.Exit (exitFailure)
import System.IO (hIsTerminalDevice, stderr, stdin)

data Command
    = Parse (Maybe Text)
    | Render (Maybe Text) (Maybe FilePath)
    | Eval (Maybe Text)

parseCmd :: ParserInfo Command
parseCmd =
    info (Parse <$> exprOpt) (progDesc "Parse Nix expression to AST JSON")

renderCmd :: ParserInfo Command
renderCmd =
    info
        (Render <$> jsonOpt <*> outDirOpt)
        (progDesc "Render AST JSON to Nix source")

evalCmd :: ParserInfo Command
evalCmd =
    info (Eval <$> jsonOpt) (progDesc "Evaluate AST JSON and output result")

subcommandParser :: Parser Command
subcommandParser =
    hsubparser
        ( command "parse" parseCmd
            <> command "render" renderCmd
            <> command "eval" evalCmd
        )

exprOpt :: Parser (Maybe Text)
exprOpt =
    optional $
        strOption
            ( long "expr"
                <> metavar "EXPR"
                <> help "Nix expression string"
            )

jsonOpt :: Parser (Maybe Text)
jsonOpt =
    optional $
        strOption
            ( long "json"
                <> metavar "JSON"
                <> help "AST in JSON format"
            )

outDirOpt :: Parser (Maybe FilePath)
outDirOpt =
    optional $
        strOption
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

cliParser :: ParserInfo Command
cliParser =
    info
        (subcommandParser <**> helper <**> versionOpt)
        ( progDesc "nix-ast: Parse and generate Nix expressions via hnix"
            <> header "nix-ast - Nix AST tool"
        )

checkTty :: Command -> IO ()
checkTty cmd = do
    isTty <- hIsTerminalDevice stdin
    when isTty $ case cmd of
        Parse Nothing -> showSubcommandHelp parseCmd
        Render Nothing _ -> showSubcommandHelp renderCmd
        Eval Nothing -> showSubcommandHelp evalCmd
        _ -> pure ()

showSubcommandHelp :: ParserInfo a -> IO b
showSubcommandHelp p = do
    TIO.hPutStrLn stderr $
        pack $
            renderHelp 80 (parserHelp defaultPrefs (infoParser p))
    exitFailure
