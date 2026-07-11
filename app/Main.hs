module Main (main) where

import NixAST.CLI (Command (..), opts, runEval, runEvalBatch, runParse, runParseBatch, runRender, runRenderBatch)
import Options.Applicative (execParser)
import System.IO (hSetEncoding, stderr, stdin, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdin utf8
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    execParser opts >>= \case
        Eval input -> runEval input
        EvalBatch input -> runEvalBatch input
        Parse input -> runParse input
        ParseBatch input -> runParseBatch input
        Render input -> runRender input
        RenderBatch input -> runRenderBatch input
