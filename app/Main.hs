module Main (main) where

import NixAST.CLI (Command (..), opts, runEval, runParse, runRender)
import Options.Applicative (execParser)
import System.IO (hSetEncoding, stderr, stdin, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdin utf8
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    execParser opts >>= \case
        Eval input out -> runEval input out
        Parse input out -> runParse input out
        Render input out -> runRender input out
