module Command (Command (..)) where

import Data.Text (Text)

data Command
    = Eval   (Maybe Text)
    | Parse  (Maybe Text)
    | Render (Maybe Text) (Maybe FilePath)
