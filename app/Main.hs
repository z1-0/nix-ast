module Main (main) where

import NixAST.CLI (Command (..), opts, runParse, runRender)
import Options.Applicative (execParser)
import System.IO (hSetEncoding, stderr, stdin, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdin utf8
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    execParser opts >>= \case
        Parse input -> runParse input
        Render input -> runRender input
