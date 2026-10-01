<!-- reviewed: augur 0.6.0 -->
# Customize your Augur installation

[← Augur](README.md)

Augur's defaults use `jev`, which works once your TypeSafe key is stored. This page is for changing them: a model Ollama serves on your machine, the local `laya` backend or a model of your own instead, a live check that asks your own questions, measuring a question before you trust it, and calling Augur from your own Python.

**On this page:** [Settings](#settings) · [Backends](#backends) · [Your own live check](#your-own-live-check) · [Calibration](#calibration) · [Use it from Python](#use-it-from-python)

## Settings

Augur keeps its files in `~/.augur`, or in the folder `AUGUR_HOME` names:

- **`augur.json`**, the settings. It holds only what differs from the defaults, so a new install has none. `augur configure backend` writes it, and you can edit it by hand.
- **`check.json`**, your own live check, once you make one.
- **`usage.csv`**, one row per call: when, which backend, which caller, which model, how many questions, the input tokens and the cost.

Run `augur schema` to write a schema your editor can use for hints. `augur check` names any key that is misspelled or has the wrong type.

## Backends

A **backend** is a decision model Augur can ask. Add one with:

```sh
augur configure backend
```

It asks where the model runs (Ollama on this machine, a hosted System One API, Laya, or a script of your own), then which model, and asks that model one real question before it saves anything. A model that does not answer is not saved, and the question shows in `usage.csv` under the caller `configure`. The same command manages what you have:

```sh
augur configure backend --list            # every backend, its type, and which is the default
augur configure backend nimble --default  # make one the default
augur configure backend --remove nimble   # remove yours; a shipped name gets its shipped settings back
```

Every prompt has a flag, so a script or an agent can do the same without a terminal. `augur configure backend -h` lists them, and the sections below give each kind of backend's command.

### What it writes

Each backend is a named entry under `backends` in `augur.json`, and its `type` is how Augur talks to it:

- **`systemone`** is the System One API, which TypeSafe built for Jev and Ollama now serves for local models. Any model behind it works with a URL and a model name. See [A model behind the System One API](#a-model-behind-the-system-one-api).
- **`laya`** is Convai's open-weight model, run on your machine by a worker Augur starts. See [Set up `laya`](#set-up-laya).
- **`command`** is any other model, through a short script you write. See [Bring your own model](#bring-your-own-model).

Augur ships two entries of its own, `jev` and `laya`, in a `defaults.json` of the same shape as your `augur.json`. Abridged:

```json
{"backend": "jev",
 "backends": {
   "jev":  {"type": "systemone", "url": "https://api.typesafe.ai/v1/systemone", "model": "jev-1.13.0",
            "keychain_service": "TYPESAFE_API_KEY", "env_key": "TYPESAFE_API_KEY"},
   "laya": {"type": "laya", "checkpoint": "convaiinnovations/laya"}}}
```

Your `augur.json` merges over them by one rule. An entry with a shipped name changes only the keys you set, and an entry with a new name is a new backend. An entry that names a different `type` from the shipped one replaces it whole. `augur configure backend` follows the same rule: `augur configure backend nimble --timeout 120` changes one key and keeps the rest.

### Choose a backend

The following backend overrides are listed by ascending priority:

1. **`augur.json`** sets the default for every call. `augur configure backend nimble --default` writes it:
   ```json
   {"backend": "nimble"}
   ```
2. **`AUGUR_BACKEND`** overrides it for one shell, or one process:
   ```sh
   export AUGUR_BACKEND=nimble
   ```
3. **`--backend`** overrides both for one call:
   ```sh
   augur ask --backend nimble -q rule.json -t "some text"
   ```

### A model behind the System One API

A `systemone` entry needs a `url` and a `model`. What differs between one host and the next is whether it needs a key.

#### Hosted, with a key

`jev` is ready once your TypeSafe key is stored:

```sh
augur configure backend jev --store-key
```

On macOS, `security` asks for the key itself, so it never appears as an argument, in your shell history or in Augur's output. Elsewhere, the command prints the `export` line to add to your shell profile.

For another hosted System One model, run `augur configure backend` and choose a hosted API, or give the same answers as flags:

```sh
augur configure backend acme --type systemone --url https://api.acme.example/v1/systemone --model acme-2.1 \
  --key-service ACME_API_KEY --key-env ACME_API_KEY --price 0.05 --store-key
```

That stores the key, asks one question, and writes:

```json
{"backends": {"acme": {"type": "systemone", "url": "https://api.acme.example/v1/systemone", "model": "acme-2.1",
                       "keychain_service": "ACME_API_KEY", "env_key": "ACME_API_KEY", "price_per_mtok": 0.05}}}
```

Augur looks for the key in the macOS keychain service first, then in the environment variable. Give each host names of its own, so one host's key is never sent to another.

#### Local, with Ollama

Ollama 0.35 and later serves decision models over the same API, on your machine, with no key and no bill. Run `augur configure backend` and choose Ollama. It lists the decision models you have pulled, pulls another by name, and saves the exact tag, such as `nimble:9b-q8_0` over `nimble:latest`, because `latest` moves when the library updates and a threshold you measured moves with it. By flags:

```sh
ollama pull nimble:9b-q8_0
augur configure backend nimble --type systemone --url http://localhost:11434/v1/systemone --model nimble:9b-q8_0 --price 0
```

That writes:

```json
{"backends": {"nimble": {"type": "systemone", "url": "http://localhost:11434/v1/systemone", "model": "nimble:9b-q8_0",
                         "price_per_mtok": 0}}}
```

An entry that names neither `keychain_service` nor `env_key` sends no key, which is what Ollama expects. The `model` is the only value that changes from one Ollama decision model to the next, so a second one is a second entry with another name. Ollama refuses a model that is not a decision model, with `HTTP 400` and `not supported by System One`, so `configure` does not save it.

The first call after Ollama starts, or after it has unloaded an idle model, waits for the model to load. If calls time out, raise the wait with `augur configure backend nimble --timeout 120`. `OLLAMA_KEEP_ALIVE` on the Ollama server keeps a model loaded for longer.

### Set up `laya`

`laya` needs its own virtualenv with `laya` and `torch` installed:

> [!NOTE]
> `torch` and the model it loads can run to gigabytes of disk. Laya gets a virtualenv of its own so that neither its size nor its dependencies reach the one the other Panoply pieces share: installing, upgrading or removing Laya never breaks Locket or Grille, and removing them never breaks Laya.

```sh
uv venv --python 3.12 ~/.augur-laya
uv pip install --python ~/.augur-laya/bin/python laya torch
```

Then tell Augur where it is, which checkpoint to load if you trained your own, and, if `laya` is your only backend, to use it by default:

```sh
augur configure backend laya --python ~/.augur-laya/bin/python --checkpoint you/your-fine-tune --device mps --default
```

That writes:

```json
{
  "backend": "laya",
  "backends": {
    "laya": {"python": "~/.augur-laya/bin/python", "checkpoint": "you/your-fine-tune", "device": "mps"}
  }
}
```

`device` is `cuda`, `mps` or `cpu`: without it, Laya picks the first one that works.

### Bring your own model

A decision model that does not speak System One can still answer for Augur through a **command backend**: a script that takes Augur's question on stdin and prints the answer. The script is where your model lives, so it can call a local model, a server on your network or another hosted API.

1. **The script reads one JSON request on stdin.** It is the same object `augur ask --request -` takes:
   ```json
   {"questions": {"likes_fruit": {"type": "noul",
                                  "instructions": "Does `text` say the writer likes a fruit?",
                                  "criteria": {"true": "A named fruit is liked.", "false": "No fruit, or no liking."}}},
    "state": {"text": "I could eat mangoes every day."}}
   ```
   `model` is added when you set one. `state` may also carry a `subject`, `siblings` and a `uid`.
2. **It prints Augur's reply**, one answer per question, in the [shapes Augur returns](README.md#everyday-use):
   ```json
   {"answers": {"likes_fruit": {"type": "noul", "noul": 0.96}},
    "model": "my-model-1", "usage": {"input_tokens": 120}}
   ```
   `model` and `usage` are optional. With `usage`, the ledger counts your tokens.
3. **It exits 0.** On any other exit, Augur reports the last line the script wrote to stderr and returns no answer.

A script can be as small as this:

```python
#!/usr/bin/env python3
import json, sys

request = json.load(sys.stdin)
text = request["state"]["text"]
answers = {}
for name, question in request["questions"].items():
    p = my_model_probability(question, text)      # your model, from 0 to 1
    answers[name] = {"type": "noul", "noul": p}
print(json.dumps({"answers": answers}))
```

Add it under a name of your choosing, and make it the default if you like:

```sh
augur configure backend mine --type command --command /Users/you/bin/my-augur-model --price 0 --default
```

That asks the script one real question, then writes:

```json
{
  "backend": "mine",
  "backends": {
    "mine": {"type": "command", "command": "/Users/you/bin/my-augur-model", "price_per_mtok": 0}
  }
}
```

`command` may also be a list of arguments, written by hand. `augur check --live --backend mine` asks it the known questions and checks the answers.

You can name several, one per model, and compare them on the same examples with `augur calibrate --compare`.

> [!IMPORTANT]
> Augur checks that every answer is a real probability, and refuses one that is not. It cannot check that your model's probabilities mean anything. A chat model asked for a number returns a number, but not a calibrated one, so run `augur calibrate` on your own examples before you trust a threshold.

### Settings each type takes

Every entry takes `type` (`--type`) and `price_per_mtok` (`--price`), the price per million input tokens the usage ledger records.

| Type | Key (flag) | What it changes |
|---|---|---|
| `systemone` | `url` (`--url`) | The System One endpoint. Required. |
| `systemone` | `model` (`--model`) | The model to ask. Pin a version, as `jev` does. |
| `systemone` | `keychain_service` (`--key-service`), `env_key` (`--key-env`) | Where to find the API key: the macOS keychain entry, then the environment variable. Leave both out for a host that takes no key. |
| `systemone` | `timeout` (`--timeout`) | Seconds to wait for an answer. Defaults to 60. |
| `laya` | `python` (`--python`) | The virtualenv's Python. Without it, `laya` is unavailable. |
| `laya` | `checkpoint` (`--checkpoint`) | The model to load, such as your own fine-tune. |
| `laya` | `device` (`--device`) | `cuda`, `mps` or `cpu`. |
| `laya` | `head_max_len` | The longest text, in tokens, the model reads. |
| `command` | `command` (`--command`) | The script to run, as a list of arguments or one string. Required. |
| `command` | `model` (`--model`) | Sent to the script as `model` in every request. |
| `command` | `timeout` (`--timeout`) | Seconds to wait for an answer. Defaults to 60. |

`--model` on a single call overrides `model` or `checkpoint` for that call. `augur check` names any key that does not belong to an entry's type.

> [!IMPORTANT]
> Augur pins `jev` to one version, because a threshold you measured on one model does not carry over to the next. When you change `model`, `checkpoint` or backend, run `augur calibrate` again before you trust the old threshold. A published benchmark is no substitute: it measures someone else's questions.

## Your own live check

`augur check --live` asks two built-in questions with known answers. To make it ask the questions you actually rely on, copy up to ten items from a calibration file:

```sh
augur configure check my-items.json                  # copies them to ~/.augur/check.json
augur configure check my-items.json --threshold 0.3  # "true" must score 0.3 or more, "false" less
augur configure check                                # shows what the live check asks now
augur configure check --reset                        # back to the built-in pair
```

The file is copied, so changing the original changes nothing until you run `configure` again. On `jev` each item is one billed call every time `check --live` runs, so a handful is enough.

## Calibration

A probability means little until you know how it behaves on your own examples. `augur calibrate` asks every question about every example you labelled, and reports how well the answers separate the true ones from the false.

### Write an items file

```json
{
  "questions": {
    "likes_fruit": {"type": "noul",
                    "instructions": "Does `text` say the writer likes a fruit?",
                    "criteria": {"true": "A named fruit is liked.", "false": "No fruit, or no liking."}}
  },
  "items": [
    {"id": "a", "text": "I could eat mangoes every day.", "labels": {"likes_fruit": true}},
    {"id": "b", "text": "Pears are my favourite snack.",  "labels": {"likes_fruit": true}},
    {"id": "c", "text": "The bus was late again.",        "labels": {"likes_fruit": false}},
    {"id": "d", "text": "I cannot stand bananas.",        "labels": {"likes_fruit": false}}
  ]
}
```

An item may also carry a `class` to group results by, a `subject` and `siblings` to name what the text is about, and a label of `null` for an example you have not decided. Use real examples, including the close calls: four easy ones prove only that the setup works.

### Read the result

```sh
augur calibrate items.json --out run-a/
```

```
calibration on backend jev: 4 items x 1 run(s), 1 question(s), 1,428 input tokens, $0.0001, 0s

[likes_fruit]
  AUROC 1.000   positives n=2 min 0.96 mean 0.97   negatives n=2 max 0.02 mean 0.01
```

- **AUROC** is how often a true example scores above a false one. 1.0 is perfect separation, and 0.5 is a coin toss.
- **positives min** is the lowest score any true example got, and **negatives max** the highest any false one got. A threshold between the two gets every labelled example right. Where they overlap, a threshold trades one kind of mistake for the other, and choosing where is your call.

`--runs 3` asks each item three times and averages, which shows how steady the answers are. `--limit` and `--questions` run a quick subset.

### Compare two runs

After changing a question, a model or a backend, compare against the run before:

```sh
augur calibrate items.json --backend laya --out run-b/ --compare run-a/means-jev.json
```

It shows how far each item moved, so you can see which examples the change helped and which it broke.

## Use it from Python

Homebrew installs Augur as a command, which your own Python cannot import. To call it from a program, install it into that program's environment:

```sh
pip install git+https://github.com/JACK-COM/augur
```

```python
from augur import ask, noul, AugurUnavailable

rule = {"likes_fruit": noul("Does `text` say the writer likes a fruit?",
                            true="A named fruit is liked.",
                            false="No fruit is named, or no liking is stated.")}
try:
    r = ask("I could eat mangoes every day.", rule, caller="my-script")
    print(r["answers"]["likes_fruit"]["noul"])    # about 0.9
except AugurUnavailable as e:
    print("no answer:", e)                        # carry on without it
```

- **`choice(instructions, options)`** and **`score(instructions, levels)`** build the other two shapes.
- **`batch(items, make_questions, threshold=...)`** asks about up to 20 texts in one call, and asks again, one text at a time, about any answer that lands close to your threshold.
- **`AugurUnavailable`** is raised whenever there is no answer. Catch it: nothing that must succeed may depend on Augur.

A program that cannot import Python can run `augur ask --request -` instead, with the whole call as JSON on stdin. `augur ask -h` shows the fields.
