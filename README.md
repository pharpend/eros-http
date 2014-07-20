# eros-http

This is an HTTP front-end to the
[Eros library](https://github.com/pharpend/eros). Eros is a text censorship
library, that I wrote.

# Usage

If the server receives a GET request, it returns an HTML representation of this
file.

It takes an input string via POST, and returns some data in JSON mapping each
phraselist to the score for the input string. The JSON is compressed.

I fed the server the GPL, here are the results, which have been prettified, and
alphabetized by key.

```json
{
  "chat": 0,
  "conspiracy": 0,
  "drug-advocacy": 0,
  "forums": 0,
  "gambling": 0,
  "games": 0,
  "gore": 0,
  "id-theft": 0,
  "illegal-drugs": 0,
  "intolerance": 0,
  "legal-drugs": 0,
  "malware": 0,
  "music": 0,
  "news": 0,
  "nudism": 0,
  "peer2peer": 0,
  "personals": 0,
  "pornography": 20,
  "proxies": 0,
  "secret-societies": 0,
  "self-labeling": 0,
  "sport": 30,
  "translation": 0,
  "upstream-filter": 0,
  "violence": 0,
  "warez-hacking": 0,
  "weapons": 0,
  "webmail": 0
}
```
