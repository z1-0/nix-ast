module Main (main) where

import Exec (exec)
import Parser (appInfo, warnOnTty)
import Options.Applicative (execParser)
import System.IO (hSetEncoding, stderr, stdin, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdin utf8
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    execParser appInfo >>= \cmd -> warnOnTty cmd >> exec cmd
