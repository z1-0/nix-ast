module Main (main) where

import NixAST.CLI (checkTty, cliParser)
import NixAST.Run (runCommand)
import Options.Applicative (execParser)
import System.IO (hSetEncoding, stderr, stdin, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdin utf8
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    execParser cliParser >>= \cmd -> checkTty cmd >> runCommand cmd
