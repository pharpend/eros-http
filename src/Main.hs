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

import           Control.Applicative
import           Data.Aeson
import qualified Data.ByteString.Lazy as Bl
import qualified Data.Text      as Ts
import qualified Data.Text.Lazy as Tl
import           Data.Text.Lazy.Encoding
import           Network.HTTP.Types
import           Network.Wai
import           Network.Wai.Handler.Warp
import qualified Paths_eros_http as Peh
import           Text.Blaze.Html.Renderer.Text
import           Text.Eros
import           Text.Markdown

-- |Run everything
main :: IO ()
main = do
    phraseMaps <- mapM getListPair erosLists
    readmePath <- Peh.getDataFileName "README.md"
    readmeBs   <- Bl.readFile readmePath
    let readmeText = decodeUtf8 readmeBs
        readmeHtml = renderHtml $ markdown def readmeText
        app req recieveResponse = recieveResponse =<< runRequest req phraseMaps readmeHtml
    run 8000 app
  where

    getListPair :: ErosList -> IO (ErosList, PhraseMap)
    getListPair list = do
      phraseMap <- readPhraseMap list
      return (list, phraseMap)

-- |Take the request, generate a response
runRequest :: Request -> [(ErosList, PhraseMap)] -> Tl.Text -> IO Response
runRequest req pmaps readmeText = do
      case requestMethod req of
        "GET" -> do
          return $ htmlResponse $ encodeUtf8 readmeText
        "POST" -> do
          serverInput <- decodeUtf8 <$> Bl.fromStrict <$> requestBody req
          jsonResponse <$> runInput serverInput pmaps
        _ -> do
           errorResponse405 "Method not supported"
    where
      jsonResponse :: Bl.ByteString -> Response
      jsonResponse = responseLBS status200 [(hContentType, "application/json")]
      htmlResponse :: Bl.ByteString -> Response
      htmlResponse = responseLBS status200 [(hContentType, "text/html")]
      errorResponse405 :: Bl.ByteString -> IO Response
      errorResponse405 = return . responseLBS status405 [(hContentType, "text/plain")]

runInput :: Message -> [(ErosList, PhraseMap)] -> IO Bl.ByteString
runInput txt listsMaps = return lsEncoded
  where lsEncoded      = encode listScoreAlist
        listScoreAlist = object [nom .= tx | (nom, tx) <- zip listNames scores]
        listNames      = map probably lists
        scores         = map (messageScore txt) maps
        lists          = [v | (v, _) <- listsMaps]
        maps           = [m | (_, m) <- listsMaps]

probably :: ErosList -> Ts.Text
probably el =
  case erosNameByList el of
    Just s -> Tl.toStrict s
    -- No idea how we would get here, but nonetheless, we're doing
    -- a table lookup, so things can go wrong.
    Nothing -> "unknown"
