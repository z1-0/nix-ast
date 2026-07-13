module NixAST.Input
    ( Input (..)
    , InputMode (..)
    , readInput
    ) where

import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text.Encoding (encodeUtf8)

data InputMode = RawNix | JSON | BatchJSON

data Input
    = FromArg InputMode Text
    | FromStdin InputMode

readInput :: Input -> IO BL.ByteString
readInput (FromArg _ t) = pure (BL.fromStrict (encodeUtf8 t))
readInput (FromStdin _) = BL.getContents
