module NixAST.Input
    ( Input
    , InputMode (..)
    , readBytes
    , inputMode
    , fromInput
    , fromStdin
    , fromExpr
    , fromJSON
    ) where

import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text.Encoding (encodeUtf8)
import System.IO (hIsTerminalDevice, stdin)

data InputMode = RawNix | JSON | ArrayInput

data Input = Input
    { readBytes :: IO BL.ByteString
    , inputMode :: InputMode
    }

fromInput :: FilePath -> Input
fromInput path =
    Input
        { readBytes = BL.readFile path
        , inputMode = ArrayInput
        }

fromStdin :: IO BL.ByteString -> Input
fromStdin onTty =
    Input
        { readBytes = checkTty onTty BL.getContents
        , inputMode = ArrayInput
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
