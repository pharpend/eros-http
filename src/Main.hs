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
import           Control.Monad (mzero)
import           Data.Aeson
import qualified Data.ByteString.Lazy as Bl
import           Data.ByteString.Lazy.Char8 (pack)
import           Data.Monoid
import qualified Data.Text      as Ts
import qualified Data.Text.Lazy as Tl
import           Data.Text.Lazy.Encoding
import           Network.HTTP.Types
import           Network.Wai
import           Network.Wai.Handler.Warp
import qualified Paths_eros_http as Peh
import           Text.Eros

instance FromJSON ErosList where
  parseJSON (String v) = do
    case (erosListByName $ Tl.fromStrict v) of
      Just l  -> return l
      Nothing -> mzero
  parseJSON _          = mzero

instance FromJSON ServerInput where
  parseJSON (Object v) = do
    action <- v .: "action"
    case (action :: Tl.Text) of
      "censor"     -> CensorInput 
                        <$> v .:  "text"                      
                        <*> v .:? "lists" .!= erosLists
      "ls"         -> GetList 
                        <$> v .: "list"
      a            -> return . BadInput $ "Invalid action: " <> a
  parseJSON _          = return . BadInput $ "I need an object, dumbass."

data ServerInput = CensorInput { text   :: Tl.Text
                               , elists :: [ErosList]
                               }
                 | GetList { elist :: ErosList
                           }
                 | BadInput { errorMessage :: Tl.Text
                            }
  deriving (Eq)

-- |Run everything
main :: IO ()
main = do
  let app req recieveResponse = recieveResponse =<< runRequest req
  run 8000 app

-- |Take the request, generate a response
runRequest :: Request -> IO Response
runRequest req = do
      case requestMethod req of
        "GET" -> do
          readmeText <- Bl.readFile =<< Peh.getDataFileName "res/readme.html"
          return $ htmlResponse readmeText
        "POST" -> do
          noio <- Bl.fromStrict <$> requestBody req
          case eitherDecode noio of
            Left emsg ->
              return . responseLBS status400 [(hContentType, "text/plain")] . pack $ emsg <> "\n"
            Right ipt ->
              jsonResponse <$> runSI ipt
        _ -> do
          return $ responseLBS status405 [(hContentType, "text/plain")] "Method not supported"
    where
      jsonResponse :: Bl.ByteString -> Response
      jsonResponse = responseLBS status200 [(hContentType, "application/json")]
      htmlResponse :: Bl.ByteString -> Response
      htmlResponse = responseLBS status200 [(hContentType, "text/html")]
      plainResponse :: Bl.ByteString -> Response
      plainResponse = responseLBS status200 [(hContentType, "text/plain")]

runSI :: ServerInput -> IO Bl.ByteString
runSI (CensorInput txt els) = do
  maps <- mapM readPhraseMap els
  let noms        = [probably el | el <- els]
      scores      = [messageScore txt pmap | pmap <- maps]
      nomScoreMap = zip noms scores
      nomScorejs  = object [nom .= tx | (nom, tx) <- nomScoreMap]
  return $ encode nomScorejs

runSI (GetList el) = do
  tfPath <- phraselistPath el
  Bl.readFile tfPath

runSI (BadInput emsg) = return $ encodeUtf8 emsg

probably :: ErosList -> Ts.Text
probably el =
  case erosNameByList el of
    Just s -> Tl.toStrict s
    -- No idea how we would get here, but nonetheless, we're doing
    -- a table lookup, so things can go wrong.
    Nothing -> "unknown"
