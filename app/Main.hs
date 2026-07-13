module Main (main) where

import NixAST.CLI (Command (..), checkTty, opts, runEval, runParse, runRender)
import Options.Applicative (execParser)
import System.IO (hSetEncoding, stderr, stdin, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdin utf8
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    execParser opts >>= \cmd -> do
        checkTty cmd
        case cmd of
            Eval input -> runEval input
            Parse input -> runParse input
            Render input outDir -> runRender input outDir
