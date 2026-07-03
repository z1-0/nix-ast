module NixAST.Input
    ( Input
    , readText
    , readBytes
    , fromFile
    , fromStdin
    , fromExpr
    , fromJSON
    ) where

import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text.Encoding (encodeUtf8)
import Data.Text.IO qualified as TIO
import System.IO (hIsTerminalDevice, stdin)

data Input = Input
    { readText :: IO Text
    , readBytes :: IO BL.ByteString
    }

fromFile :: FilePath -> Input
fromFile path =
    Input
        { readText = TIO.readFile path
        , readBytes = BL.readFile path
        }

-- | Create an Input from stdin. The onTtyText/onTtyBytes actions are run
-- when stdin is a terminal, for readText and readBytes respectively.
fromStdin :: IO Text -> IO BL.ByteString -> Input
fromStdin onTtyText onTtyBytes =
    Input
        { readText = checkTty onTtyText TIO.getContents
        , readBytes = checkTty onTtyBytes BL.getContents
        }
  where
    checkTty fallback action = do
        isTty <- hIsTerminalDevice stdin
        if isTty then fallback else action

-- | Create an Input from a Nix expression string. readBytes is not supported.
fromExpr :: Text -> Input
fromExpr expr =
    Input
        { readText = pure expr
        , readBytes = fail "--expr is only supported for parse"
        }

fromJSON :: Text -> Input
fromJSON json =
    Input
        { readText = pure json
        , readBytes = pure (BL.fromStrict (encodeUtf8 json))
        }
