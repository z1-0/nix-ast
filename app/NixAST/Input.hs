module NixAST.Input
    ( Input
    , InputMode (..)
    , readBytes
    , inputMode
    , stdinInput
    , fromExpr
    , fromJSON
    ) where

import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text.Encoding (encodeUtf8)
import System.IO (hIsTerminalDevice, stdin)

data InputMode = RawNix | JSON | BatchJSON

data Input = Input
    { readBytes :: IO BL.ByteString
    , inputMode :: InputMode
    }

stdinInput :: IO BL.ByteString -> Input
stdinInput onTty =
    Input
        { readBytes = checkTty onTty BL.getContents
        , inputMode = BatchJSON
        }
  where
    checkTty fallback action = do
        isTty <- hIsTerminalDevice stdin
        if isTty then fallback else action

fromExpr :: Text -> Input
fromExpr expr =
    Input
        { readBytes = pure (BL.fromStrict (encodeUtf8 expr))
        , inputMode = RawNix
        }

fromJSON :: Text -> Input
fromJSON json =
    Input
        { readBytes = pure (BL.fromStrict (encodeUtf8 json))
        , inputMode = JSON
        }
