# eros-http

This is an HTTP front-end to the
[Eros library](https://github.com/pharpend/eros). Eros is a text censorship
library, that I wrote.

# Usage

If the server receives a GET request, it returns an plain-text representation of
this file.

It takes an input string via POST, and returns some data in JSON mapping each
phraselist to the score for the input string. The JSON is compressed.

I fed the server the GPL, here are the results.

```json
{"illegal-drugs":0,"upstream-filter":0,"gore":0,"news":0,"sport":30,"games":0,"drug-advocacy":0,"nudism":0,"secret-societies":0,"personals":0,"id-theft":0,"intolerance":0,"chat":0,"conspiracy":0,"pornography":20,"malware":0,"music":0,"webmail":0,"self-labeling":0,"warez-hacking":0,"proxies":0,"peer2peer":0,"gambling":0,"forums":0,"translation":0,"weapons":0,"violence":0,"legal-drugs":0}
```

