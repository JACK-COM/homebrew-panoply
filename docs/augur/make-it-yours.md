<!-- reviewed: augur 0.3.0 -->
# Customize your Augur installation

[← Augur](README.md)

Augur's defaults use `jev`, which works once your TypeSafe key is stored. This page is for changing them: the local `laya` backend instead, a live check that asks your own questions, measuring a question before you trust it, and calling Augur from your own Python.

**On this page:** [Settings](#settings) · [Backends](#backends) · [Your own live check](#your-own-live-check) · [Calibration](#calibration) · [Use it from Python](#use-it-from-python)

## Settings

Augur keeps its files in `~/.augur`, or in the folder `AUGUR_HOME` names:

- **`augur.json`**, the settings. It holds only what differs from the defaults, so a new install has none.
- **`check.json`**, your own live check, once you make one.
- **`usage.csv`**, one row per call: when, which backend, which caller, which model, how many questions, the input tokens and the cost.

Run `augur schema` to write a schema your editor can use for hints. `augur check` names any key that is misspelled or has the wrong type.

## Backends

A **backend** is the decision model that answers. Augur supports exactly two, and a model outside them cannot be plugged in by a setting today:

- **`jev`** (the default) is TypeSafe's hosted model. It needs a TypeSafe key and a network connection, and it is billed per input token.
- **`laya`** is Convai's open-weight model, which runs on your machine for free. Out of the box it answers our test questions barely better than chance, because it is a base to train further. Use it once you have fine-tuned it on your own examples.

### Choose a backend

The following backend overrides are listed by ascending priority:

1. **`augur.json`** sets the default for every call:
   ```json
   {"backend": "laya"}
   ```
2. **`AUGUR_BACKEND`** overrides it for one shell, or one process:
   ```sh
   export AUGUR_BACKEND=laya
   ```
3. **`--backend`** overrides both for one call:
   ```sh
   augur ask --backend laya -q rule.json -t "some text"
   ```

### Set up `laya`

`laya` needs its own virtualenv with `laya` and `torch` installed:

```sh
uv venv --python 3.12 ~/.augur-laya
uv pip install --python ~/.augur-laya/bin/python laya torch
```

Then tell Augur in `~/.augur/augur.json` where it is, which checkpoint to load if you trained your own, and, if `laya` is your only backend, to use it by default:

```json
{
  "backend": "laya",
  "backends": {
    "laya": {"python": "~/.augur-laya/bin/python", "checkpoint": "you/your-fine-tune", "device": "mps"}
  }
}
```

`device` is `cuda`, `mps` or `cpu`: without it, Laya picks the first one that works. Run `augur check --backend laya` to prove it loads.

### Settings each backend takes

| Backend | Key | What it changes |
|---|---|---|
| `jev` | `model` | The model version. Augur pins one on purpose, see below. |
| `jev` | `keychain_service`, `env_key` | Where to find your key: the macOS keychain entry, then the environment variable. Both default to `TYPESAFE_API_KEY`. |
| `jev` | `price_per_mtok` | The price per million input tokens the usage ledger records. |
| `laya` | `python` | The virtualenv's Python. Without it, `laya` is unavailable. |
| `laya` | `checkpoint` | The model to load, such as your own fine-tune. |
| `laya` | `device` | `cuda`, `mps` or `cpu`. |
| `laya` | `head_max_len` | The longest text, in tokens, the model reads. |

`--model` on a single call overrides `model` or `checkpoint` for that call.

> [!IMPORTANT]
> Augur pins `jev` to one version, because a threshold you measured on one model does not carry over to the next. When you change `model`, `checkpoint` or backend, run `augur calibrate` again before you trust the old threshold.

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
