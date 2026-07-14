module Parser (appInfo, warnOnTty) where

import Command (Command (..))
import Control.Monad (when)
import Data.Text (Text, pack)
import Data.Text.IO qualified as TIO
import Data.Version (showVersion)
import Options.Applicative
import Options.Applicative.Help (parserHelp, renderHelp)
import Paths_nix_ast (version)
import System.Exit (exitFailure)
import System.IO (hIsTerminalDevice, stderr, stdin)

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

versionInfo :: Parser (a -> a)
versionInfo =
    infoOption
        (showVersion version)
        ( long "version"
            <> short 'v'
            <> help "Show version"
        )

evalInfo :: ParserInfo Command
evalInfo =
    info (Eval <$> jsonOpt) (progDesc "Evaluate AST JSON and output result")

parseInfo :: ParserInfo Command
parseInfo =
    info (Parse <$> exprOpt) (progDesc "Parse Nix expression to AST JSON")

renderInfo :: ParserInfo Command
renderInfo =
    info
        (Render <$> jsonOpt <*> outDirOpt)
        (progDesc "Render AST JSON to Nix source")

subcommands :: Parser Command
subcommands =
    hsubparser
        ( command "eval" evalInfo
            <> command "parse" parseInfo
            <> command "render" renderInfo
        )

appInfo :: ParserInfo Command
appInfo =
    info
        (subcommands <**> helper <**> versionInfo)
        ( progDesc "nix-ast: Parse and generate Nix expressions"
            <> header "nix-ast - Nix AST tool"
        )

showSubcommandHelp :: ParserInfo a -> IO b
showSubcommandHelp p = do
    TIO.hPutStrLn stderr $ pack $ renderHelp 80 (parserHelp defaultPrefs (infoParser p))
    exitFailure

warnOnTty :: Command -> IO ()
warnOnTty cmd = do
    isTty <- hIsTerminalDevice stdin
    when isTty $ case cmd of
        Eval Nothing -> showSubcommandHelp evalInfo
        Parse Nothing -> showSubcommandHelp parseInfo
        Render Nothing _ -> showSubcommandHelp renderInfo
        _ -> pure ()
