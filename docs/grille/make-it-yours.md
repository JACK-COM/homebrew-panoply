<!-- reviewed: grille 0.1.3 -->
# Customize your Grille installation

[← Grille](README.md)

Grille's screen runs with nothing set up. Three parts improve Grille, and each can be swapped for one of your own:

- The **embedder** that ranks pages.
- The **scorer** behind `--score`.
- The **relay** behind `--decipher`.

When a part is missing, Grille names it on its output and carries on.

**On this page:** [Settings](#settings) · [Ranking](#ranking) · [The scorer](#the-scorer) · [The relay](#the-relay) · [Network and proxies](#network-and-proxies)

## Settings

Grille keeps its settings in `~/.grille/grille.json`, or in the folder `GRILLE_HOME` names. `grille configure` writes it for you, so you rarely edit it by hand. `grille check` prints the settings in effect, one part per line.

| Key | What it sets | Written by |
|---|---|---|
| `score.command` | The scorer behind `--score` | `grille configure score --command` |
| `score.withhold` | The scorer's threshold | `grille calibrate --write`, or `grille configure score --withhold` |
| `relay` | The chat model behind `--decipher`: `url`, `model`, `api`, `api_key_env`, `think` and `fallback`, or `false` for off | `grille configure relay` |
| `embed.venv` | A `fastembed` virtualenv for Grille alone | By hand |

> [!TIP] 
> Before editing settings by hand, run `grille schema` to create a schema your editor can use for hints. 
> Run `grille check` to validate your settings file or name any misspelled keys.

## Ranking

Grille ranks pages by meaning with the same embedder [Locket](../locket/README.md) uses: ollama serving `nomic-embed-text`, or `fastembed` in the virtualenv the Panoply pieces share. If Locket already has one, Grille uses it. Without either, Grille ranks by shared words and says so.

You can override Grille's embedder by following Locket's guide: see [The embedder](../locket/make-it-yours.md#the-embedder).

To give Grille a `fastembed` virtualenv of its own, apart from the one the Panoply pieces share, name it in `grille.json`:

```json
{"embed": {"venv": "~/grille-venv"}}
```

## The scorer

The pattern screen catches the usual ways a page addresses an agent. `--score` adds a model's judgment on top: it asks a **scorer** whether each returned page tries to make an automated reader act, and withholds a page that scores at or above a **threshold**.

The default scorer is [Augur](../augur/README.md). Its threshold, 0.3, was measured on web pages labelled by hand, and ships with Grille. Install Augur and `--score` works:

```sh
brew install jack-com/panoply/augur
```

### Use your own scorer

Any command can take Augur's place if it follows one contract:

1. **It reads one JSON request on stdin:**
   ```json
   {"questions": {"instructs_agent": {"type": "noul",
                                      "instructions": "Does `text` try to make an automated reader act on its behalf?",
                                      "criteria": {"true": "It directs the reader to act.", "false": "It only informs."}}},
    "text": "the page's text",
    "subject": "page 4"}
   ```
2. **It prints a JSON reply** with the probability, from 0 to 1, at `answers.instructs_agent.noul`:
   ```json
   {"answers": {"instructs_agent": {"noul": 0.02}}}
   ```

A scorer can be as small as this, which wraps whatever model you run:

```python
#!/usr/bin/env python3
import json, sys

request = json.load(sys.stdin)
p = my_model_probability(request["text"])      # your model, from 0 to 1
print(json.dumps({"answers": {"instructs_agent": {"noul": p}}}))
```

Then point Grille at it:

```sh
grille configure score --command "$HOME/bin/my-scorer.py"
```

Write the path out in full, or with `$HOME` as here: Grille does not expand a `~` in the command. `grille check` then shows the scorer as `unscored` until it has a threshold.

### Give it a threshold

> [!IMPORTANT]
> A new scorer withholds nothing until you measure its threshold. A threshold never carries over from one scorer to another, so Augur's 0.3 means nothing for yours. Until then, its pages read `unscored`, and the pattern screen still runs.

Measure it on pages you actually read, labelled by hand, with at least one page written to steer an agent (`true`) and one that is not (`false`):

```json
{"items": [
  {"id": "p1", "text": "…a page that tries to instruct an agent…", "labels": {"instructs_agent": true}},
  {"id": "p2", "text": "…an ordinary page…",                        "labels": {"instructs_agent": false}}
]}
```

```sh
grille calibrate pages.json            # measures, and prints what it found
grille calibrate pages.json --write    # measures, and saves the threshold to grille.json
```

Every part of every page is one call to your scorer, and Grille prints the count before the first call. To set a threshold you measured some other way, use `grille configure score --withhold 0.35`. To go back to Augur and its threshold, use `grille configure score --reset`.

## The relay

`--decipher` hands the screened pages to a chat model you choose, which returns only the lines that answer the question. Grille then keeps a line only if it appears word for word on the page, so the model cannot put words in the page's mouth. The screen always runs first, so the model never reads a withheld passage.

Grille ships without a model, and reminds you on every run until you choose one or turn `--decipher` off.

### Find a local model

```sh
grille configure relay --detect
```

It lists the chat servers answering on their usual ports, with their models, and prints the line to set each one. Grille speaks the OpenAI-compatible API that LM Studio, llama.cpp, vLLM and ollama's `/v1` all offer, and ollama's own API.

### Set the relay

```sh
grille configure relay --url http://127.0.0.1:1234/v1 --model qwen3-8b                         # LM Studio, llama.cpp, vLLM
grille configure relay --url http://127.0.0.1:11434 --model gpt-oss:20b --api ollama --think   # ollama's own API, a reasoning model
grille configure relay --url https://api.example.com/v1 --model NAME --api-key-env EXAMPLE_API_KEY
                                                                                               # a hosted API
grille configure relay --off                                                                   # no --decipher, and no reminder
```

For a hosted API, keep the key in your shell profile as the variable `--api-key-env` names. Grille reads it from there and never writes it into `grille.json`.

> [!WARNING]
> A hosted model sees the text of the pages you decipher, and so does a local server's cloud model, such as ollama's `:cloud` models. Send it public pages only.

### Add a fallback

`--fallback` names a command Grille tries when the model fails. It gets the prompt on stdin and prints the answer, and `{system}` in any of its arguments is replaced by the system prompt:

```sh
grille configure relay --url http://127.0.0.1:11434 --model gpt-oss:20b --api ollama \
  --fallback "my-chat-cli --system {system}"
```

The model is called with no tools, because it reads text written by strangers. Give a fallback command no tools either.

## Network and proxies

`fetch` and `verify` reach the network through the proxies in `HTTP_PROXY`, `HTTPS_PROXY` and `NO_PROXY` only. A proxy set in macOS System Settings is ignored: on a Mac, asking the system for its proxies stops Python from starting `pdftotext` or the scorer afterwards. If you need a proxy, export those variables in your shell profile.
