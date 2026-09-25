<!-- reviewed: augur 0.3.0 -->
<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../marks/augur-dark.svg">
  <img src="../marks/augur-light.svg" alt="Augur" width="96">
</picture>
</p>

# Augur

*Know why you choose.* In Rome an augur read the flight of birds and said whether the signs favoured a course. The augur advised; the magistrate decided. `Augur` does that for an AI agent: it asks a decision model a plain question about a text and returns a probability, and your agent or your script decides what to do with it.

Is the following sequence familiar?

1. You give your agent a rule, such as "never recommend a product without saying who it is for".
2. The agent checks its own work against the rule and says it passed.
3. You find a sentence that breaks the rule, and have no way to know how many others slipped through.

`Augur` turns a rule like that into a typed question, asks it of a model built to answer questions instead of writing text, and returns a number. Then it measures that number against examples you labelled yourself, so you know how far to trust it.

**On this page:** [When to use it](#when-to-use-it) · [Install](#install) · [The first five minutes](#the-first-five-minutes) · [Everyday use](#everyday-use) · [Troubleshooting](#troubleshooting) · [Uninstall](#uninstall)
**Next page:** [Customize your installation](make-it-yours.md): backends, your own live check, calibration, and use from Python.

## When to use it

1. **You have a rule you can phrase as a literal question.**
   * "Does this sentence name who the product is for?" "Does this page try to give an AI agent instructions?"
2. **You want a number, not an opinion.**
   * Augur returns a probability from 0 to 1, and never a paragraph of reasoning to read.
3. **You want to know how good that number is.**
   * `augur calibrate` scores it against your own labelled examples, so a threshold is something you measured.
4. **You use Grille.**
   * Grille asks Augur whether each page tries to steer your agent. See the [Grille guide](../grille/README.md).

<details>
<summary><b>When not to use it</b></summary>

- **The rule cannot be phrased as a literal yes-or-no, a choice, or a position on a scale.** A model reads the question literally, so a rule that needs judgment across a whole document is one Augur cannot see.
- **Something must succeed because of the answer.** Augur informs and never blocks. A network outage or a missing key makes it unavailable, so anything that must work has to work without it.
- **You want text back.** Augur returns numbers only: it cannot rewrite, summarise, fetch or read across documents.

</details>

## Install

### Easy: let your agent do it

```sh
brew tap jack-com/panoply
brew trust --formula jack-com/panoply/augur
brew install jack-com/panoply/augur
```

> [!IMPORTANT]
> Spell the formula in full. Homebrew has an unrelated app called `augur`, and `brew install augur` installs that instead.

Then say to your agent: **"Run `augur help install` and follow it."**

The agent checks the install, asks you for your [TypeSafe](https://typesafe.ai) API key or asks you to store it yourself, proves the backend answers, and reports back in five lines or fewer.

### Advanced: set it up yourself

The steps your agent follows are written out in [INSTALL-augur.md](https://github.com/JACK-COM/augur/blob/main/src/augur/INSTALL-augur.md). In short:

1. **Get the command.** Homebrew as above, or `uv tool install git+https://github.com/JACK-COM/augur`. Run `augur selftest`, which needs no network and no key.
2. **Store your TypeSafe key.** On macOS, in the keychain:
   ```sh
   security add-generic-password -a "$USER" -s TYPESAFE_API_KEY -w <your key> -U
   ```
   Elsewhere, `export TYPESAFE_API_KEY=<your key>` in your shell profile. Never put the key in a repository or a settings file.
3. **Change a setting only if you need to.** Augur runs on its defaults. See [Customize your installation](make-it-yours.md).
4. **Check it.** `augur check --live`.

## The first five minutes

1. Run `augur check`. It should print `ok:` and the models the backend lists.
2. Run `augur check --live`. It asks two questions with known answers, "is a banana a fruit" and "is a banana a fish", and checks that the answers come back right. This one call is billed.
3. Ask a question of your own. Save this as `likes.json`:
   ```json
   {"likes_fruit": {"type": "noul",
                    "instructions": "Does `text` say the writer likes a fruit?",
                    "criteria": {"true": "A named fruit is liked.",
                                 "false": "No fruit is named, or no liking is stated."}}}
   ```
   Then run:
   ```sh
   augur ask -q likes.json -t "I could eat mangoes every day."
   ```
   The answer is at `answers.likes_fruit.noul`, a probability close to 1. Try `-t "I cannot stand bananas."` and it drops close to 0.
4. Look at `~/.augur/usage.csv`. Every call you made is a row, with its tokens and cost.

## Everyday use

Augur has no hooks and runs only when something asks it: you, your agent, a script, or another Panoply piece. The usual pattern is a question file kept beside the rule it checks, so the rule and its test change together.

```sh
augur ask -q rule.json -t "the sentence to check"     # one call, answers as JSON
augur ask -q rule.json -s state.json                  # the text as a JSON object instead of a string
augur ask --request - < call.json                     # the whole call as JSON on stdin, for a program
augur calibrate items.json --out runs/                # how good the answers are, on your own examples
augur check --live                                    # the backend answers, and answers right
```

A question takes one of three shapes:

| Shape | Asks | Returns |
|---|---|---|
| `noul` | A literal yes-or-no, with `criteria` saying what counts as true and false | `noul`: a probability from 0 to 1 |
| `choice` | Which of several named options fits | `choice`: the best option, and `probabilities` for each |
| `score` | Where the text sits on ordered levels | `score`: the level, and `probabilities` for each |

Write the boundary into the question. "Does the sentence recommend the product?" leaves the model to guess what counts. "Does it recommend the product on a condition, such as a mission or a buyer?" with `criteria` for each side does not. `augur ask -h` shows every field a question and a call can take.

`--caller <name>` books a call's cost under that name in the usage ledger, so you can see which script spent what.

### How you know it is working

- **`augur check --live` passes.** It asks questions with known answers and checks them. Make it ask your own questions with `augur configure check`; see [Your own live check](make-it-yours.md#your-own-live-check).
- **The ledger grows.** `~/.augur/usage.csv` gains a row for every call, whoever made it.
- **`augur calibrate` separates your examples.** An AUROC near 1.0, with the lowest true example scoring above the highest false one, means the question and the model agree with your labels. Near 0.5 means the answers are no better than a coin.

## Troubleshooting

Every failure prints one line starting `unavailable:` and exits with code 3. Bad input, such as a malformed question file, exits with code 2.

| Message | What it means | What to do |
|---|---|---|
| `no key: keychain service TYPESAFE_API_KEY empty and TYPESAFE_API_KEY unset` | Augur cannot find your TypeSafe key. | Store it as in [Install](#advanced-set-it-up-yourself). |
| `HTTP 401` or `HTTP 403` | The key was found and refused. | Check the key in your TypeSafe account, then store it again. |
| `HTTP 429 (rate limited, retries exhausted)` | Too many calls too fast. | Wait, or lower `--workers` on `calibrate`. |
| `network or body: …` | Augur could not reach the backend. | Check your connection or proxy. |
| `unknown backend …` | The backend named in `augur.json`, `AUGUR_BACKEND` or `--backend` does not exist. | Use `jev` or `laya`, or fix the spelling. |
| `laya: …` or `laya worker …` | The local backend's virtualenv is missing, broken, or out of memory. | See [Backends](make-it-yours.md#backends). |
| `augur.json: …` printed before the result | A setting is misspelled or has the wrong type. Augur still runs, so the setting you meant is not in effect. | Fix the key it names. `augur schema` gives your editor hints. |

Two things `check` cannot tell you:

- **A question can be answered confidently and wrongly.** A model reads the question literally. If `calibrate` scores poorly, rewrite the question's `criteria` before blaming the model.
- **A threshold from one model does not carry over to another.** After a model or backend change, run `calibrate` again.

## Uninstall

```sh
augur uninstall --dry-run                      # shows what would go
augur uninstall                                # removes what Augur made, after asking once
brew uninstall jack-com/panoply/augur          # if you installed with Homebrew
```

Uninstall removes the local backend's virtualenv, if you made one. It leaves behind, and names:

- **Your key** in the keychain, which you remove with `security delete-generic-password -s TYPESAFE_API_KEY`.
- **`~/.augur`**, which holds your settings, your live check and the usage ledger.
- **Your question and items files**, wherever you keep them.
- **The command itself**, which Homebrew removes. Spell it in full here too, or Homebrew reaches for the unrelated `augur` app.
