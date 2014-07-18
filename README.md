# eros-http

This is an HTTP front-end to the
[Eros library](https://github.com/pharpend/eros). Eros is a text censorship
library, that I wrote

The server takes POST data in JSON, and then sends back some JSON data, or an
Aeson error message if there's invalid data (Aeson is the JSON library I used).

If the server receives a GET request, it returns an plain-text representation of
this file.

# JSON input

I'm too lazy and incompetent to write a proper input schema. Here's the Haskell
code that decodes the input.

```haskell
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
```

The output schema is different depending on the value of `action`. Here's the
input → output function.

```haskell
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
```
