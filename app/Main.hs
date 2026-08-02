module Main (main) where

import Exec (exec)
import GHC.IO.Encoding (setFileSystemEncoding, setLocaleEncoding)
import Options.Applicative (execParser)
import Parser (appInfo, warnOnTty)
import System.IO (utf8)

main :: IO ()
main = do
    setLocaleEncoding utf8
    setFileSystemEncoding utf8
    execParser appInfo >>= \cmd -> warnOnTty cmd >> exec cmd
