{-# LANGUAGE OverloadedStrings #-}

-- |
-- Module       : Main
-- Description  : Runs the Eros HTTP server.
-- Copyright    : 2014, Peter Harpending.
-- License      : BSD3
-- Maintainer   : Peter Harpending <pharpend2@gmail.com>
-- Stability    : experimental
-- Portability  : archlinux
--

module Main where

import qualified Data.ByteString.Lazy as Bl
import qualified Data.Text.Lazy as Tl
import           Network.HTTP.Types
import           Network.Wai
import           Network.Wai.Handler.Warp
import           Text.Eros

main :: IO ()
main = do
  erosMaps <- mapM readPhraseMap erosLists
  let app req recieveResponse = recieveResponse =<< runRequest req erosMaps
  run 8000 app

runRequest :: Request -> [PhraseMap] -> IO Response
runRequest _ _ = do
  return nullResponse

jsonResponse :: Bl.ByteString -> Response
jsonResponse = responseLBS status200 [(hContentType, "application/json")]

nullResponse :: Response
nullResponse = responseLBS status200 [] ""

data ServerInput = CensorInput { text   :: Tl.Text
                               , elists :: [ErosList]
                               , pretty :: Bool
                               }
                 | GetLists { elists :: [ErosList]
                            }
                 | GetInputSchema
                 | GetPhraselistSchema
                 | GetOutputSchema
                 | Help
  deriving (Eq)
