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
runRequest req maps = do
  return $ jsonResponse "go fuck yourself"

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
                 | GetAllSchemata
  deriving (Eq)

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
      "get-schema" -> do 
         whichSchema <- v .: "schema"
         case (whichSchema :: Tl.Text) of                                   
           "input"      -> return GetInputSchema                           
           "output"     -> return GetOutputSchema                         
           "phraselist" -> return GetPhraselistSchema                 
           "all"        -> return GetAllSchemata
           _            -> mzero
      "censor"     -> CensorInput 
                        <$> v .:  "text"                      
                        <*> v .:? "eros-lists" .!= erosLists
                        <*> v .:? "pretty"     .!= False
      "ls"         -> GetLists 
                        <$> v .: "lists"
      _            -> mzero
  parseJSON _          = mzero
