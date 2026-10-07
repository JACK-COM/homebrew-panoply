<!-- reviewed: locket 0.11.1 -->
# Customize your Locket installation

[← Locket](README.md)

Locket works out of the box on Claude Code, Codex and Hermes. This page is for everything else: your own memory folders, a different embedder, lessons you want put to the agent, and usage kept somewhere unusual. Each section shows one worked example and points to the command that lists every option, so this page never has to keep up with a changing list.

**On this page:** [Stores](#stores) · [The embedder](#the-embedder) · [Trigger rows](#trigger-rows) · [Where usage reads from](#configure-where-usage-reads-from) · [Council stores](#council-stores)

## Stores

A **store** is a folder of markdown your agent writes memory into. Locket checks each store against itself.

- **Claude Code** is found without setup. 
  - `~/.claude` is one store (its memory, rules, skills, agents and the markdown at the top).
  - Each project's memory folder under `~/.claude/projects/` is a store of its own.
- **Hermes** is found without setup too: `~/.hermes`, with `memories/` and `SOUL.md`.
- **Codex** is found without setup too: `~/.codex`, or the folder `CODEX_HOME` names, with `memories/` and `AGENTS.md`. Codex writes `memories/` itself, between sessions, so no hook sees those writes; Locket checks what you and your agent write, and the audit reads what Codex wrote.
- **For any other folder**, run the following command:

  ```sh
  locket init <path/to/folder>
  ```

  Replace `<path/to/folder>` with a path to the target folder. Locket names the store after the folder and writes that name into the folder's `locket.json`; add `--name <label>` to choose another. A name another store already holds is refused.

  > [!IMPORTANT] 
  > Only `init` adds a store to the list. Locket does not search your disk, so a `locket.json` you write by hand in a folder you never ran `init` on is never read.

### Combine multiple stores

You may have two folders that are one thing, such as a project's documents and the agent's notes about that project.
In such cases, you can join both into one store. The following example adds the `~/work/myapp/docs` folder to an existing
`myapp-memory` store:

```sh
locket init ~/work/myapp/docs --parent myapp-memory
```

Now `locket find "some important fact" myapp-memory` searches both the agent's memories and the markdown in `~/work/myapp/docs`,
and a write into either folder is checked against both.

### List or remove stores

Run `locket corpora` to list every store Locket knows, including merged stores:

```
council                                            212 files
-Users-myname-ducks-and-flowers-game               23 files
myapp-memory                                       104 files + 30 csv rows  [1 joined store]
```

Any command that takes a store accepts a name from this list, or any part of one: `ducks` finds the game's store. A name that matches a store exactly always picks that store, even when a longer name contains it; a part that matches two stores is refused, and the list is printed.

Run `locket forget <folder>` to drop a store.


### The manifest: `locket.json`

A store's `locket.json` holds its name and its exceptions. `init` writes the name alone, and every key you leave out uses the default.
The following example skips backup files, keeps a log from being scored as if it were facts, and lets `find` rank the rows of a spreadsheet of decisions:

```json
{
  "excluded_files": ["*.bak*"],
  "ledger_surfaces": ["CHANGELOG.md"],
  "sources": [
    {"path": "RULINGS.csv", "text": "Ruling", "label": "Area"}
  ]
}
```

The keys used:

- **`excluded_files`** and **`excluded_dirs`**: files and folders that are not memory, so Locket never reads them. Use them for a draft, or a template whose copies hold the facts. Dependency and build folders (`node_modules`, `vendor`, `Pods`, `venv`, `build`, `dist` and their kin) are skipped in every store, whatever this list says.
- **`ledger_surfaces`**: markdown files that grow by adding entries on purpose, such as a log, so repeats there are not flagged. These have nothing to do with the CSV ledgers below.
- **`holding_spaces`**: scratch or inbox files whose entries should each be unique. Locket still reads and searches them, but checks each only against itself.
- **`sources`**: CSV files whose rows `find` should rank beside your markdown.

`locket help manifest` lists every key, grouped by the question it answers.

A CSV named `RULINGS*.csv`, `CLAIMS*.csv` or `HISTORY-*-Sessions.csv` is also checked row by row against a built-in schema: a row that breaks it is refused at write time, and `locket ledgers` checks every such file in a store. `locket help scan` prints each schema.

### Ledgers: the writes Locket can refuse

Locket can tell whether a row fits its columns, but not whether a sentence is new. So the more of your memory that lives in rows, the more of it Locket can check before it lands. One command sets the ledgers up:

```sh
locket init <your memory folder> --ledgers
```

It writes three files at the folder's root, each holding only its header row, and keeps any that already exist:

- **`RULINGS-<name>.csv`**: decisions you have made, one per row, so a later session finds the decision instead of making it again.
- **`CLAIMS-<name>.csv`**: facts your agent found the hard way, each with its source, so a later session finds the fact instead of hunting for it again.
- **`HISTORY-<name>-Sessions.csv`**: one row per working session, saying what it did. A dated note like "updated on the 3rd" belongs here, not in a memory file, and Locket's note about it names this file.

The first two are added to `sources`, so `find` ranks their rows beside your markdown. `<name>` is the store's name; `--ledgers=<Name>` picks another. Point at a row by file and filter (`RULINGS-notes.csv`, query `Area=billing`) rather than copying it into prose.

Run `locket help scan` for an explanation of every key. 
To manually edit a manifest in a code editor, `locket schema` writes a schema your editor can use for hints, and `locket schema <folder>` checks a store's manifest.

## The embedder

An **embedder** turns a sentence into a position in meaning, so that "*we ship from main*" and "*deploys happen off the main branch*" land close together.
Without one, `locket find` compares words only, and a fact written in new words can silently cause divergence.

Locket uses the first of these that responds:

1. **[ollama](https://ollama.com)** 0.36 or later, serving `embeddinggemma-2:270m`. If ollama is installed, `ollama pull embeddinggemma-2:270m` is all it takes; Locket starts the server when it needs it. An older ollama refuses the pull and asks for an upgrade.
2. **onnxruntime**, which runs the same model inside Python with no server. It lives in the virtualenv every Panoply piece shares:
   ```sh
   python3 -m venv ~/.panoply/venv
   ~/.panoply/venv/bin/python -m pip install onnxruntime tokenizers
   ```
   The model downloads into the virtualenv on first use, about 314 MB. A virtualenv made for `fastembed` already holds both packages.
3. **Word overlap**, when neither answers. Locket says so on its output.

`locket embedder` shows which one answers on this machine. After any change, run `locket index all` to read your stores again.

### Use a different embedder

The embedder settings live in `~/.panoply/config.json`, the one settings file every Panoply piece reads. Every way Locket runs reads it: your terminal, your agent's hooks, the Claude Desktop server. One command changes all of them:

```sh
locket configure embedder --model nomic-embed-text
```

That sets Locket's own model. To set it for every Panoply piece that does not set its own, add `--global`:

```sh
locket configure embedder --model nomic-embed-text --global
```

Locket reads its own section first, then the global settings, then the shipped default. If Grille sets its own model, a `--global` change does not reach Grille, and the command says so.

The model must already be pulled (`ollama pull nomic-embed-text`). Locket asks ollama before writing and refuses a model it does not have, or one that is not an embedding model.

The change is instant, but every store's index still belongs to the old model. `locket find` and `locket index` rebuild a store when they next run it, and your agent's hooks stay silent for that store until then. To rebuild every store as part of the change, add `--index`:

```sh
locket configure embedder --model nomic-embed-text --index
```

`locket configure` on its own shows each setting, where its value comes from, and which stores are behind. `locket configure embedder -h` explains every option:

| Option | What it changes | Default |
|---|---|---|
| `--model NAME` | The ollama model | `embeddinggemma-2:270m` |
| `--ollama-host URL` | Where ollama answers, for example another machine | `http://127.0.0.1:11434` |
| `--autostart`, `--no-autostart` | Whether Locket starts ollama when it is not running | on |
| `--venv PATH` | The virtualenv for the in-process rung | `~/.panoply/venv` |
| `--global` | The settings every piece shares, instead of Locket's own | |
| `--reset` | Removes every setting from the section being written | |

Pass `default` as a value to remove one setting: `locket configure embedder --model default`. Locket then follows the global value, or the shipped default if none is set. The in-process rung always runs EmbeddingGemma 2, so a machine set to another model ranks with Gemma whenever ollama is down, and keeps a second index for it.

An environment variable still wins over the file, for one command or one test:

```sh
OLLAMA_HOST=http://gpu-box.local:11434 locket find "we ship from main"
```

| Variable | Overrides | 
|---|---|
| `MEMFIND_MODEL` | `--model` |
| `OLLAMA_HOST` | `--ollama-host` |
| `MEMFIND_NO_AUTOSTART=1` | `--autostart` |
| `PANOPLY_VENV` | `--venv` |
| `MEMFIND_ONNX_MODEL`, `MEMFIND_ONNX_REVISION` | The in-process model itself, which has no option |

A variable set in one place and not another is how your terminal and your hooks come to use different models, rebuilding the index back and forth, so `locket configure` and `locket doctor` name any variable that is overriding the file.

Locket is tested with EmbeddingGemma 2. Another model changes what a score means, so read the rankings with fresh eyes after a switch.

## Trigger rows

Some mistakes are not about memory at all: an agent runs `git reset --hard` and loses an hour of work it had not committed, and next month it does it again.
Write that lesson once in a **trigger row**, and Locket puts it to the agent at the moment it is about to run the command again.

A trigger row is not a hook you write yourself. Locket registers one hook, `locket trigger`, and that hook reads your rows. A hook of your own is a script, an entry in each host's settings, and the host's input and output format to get right. A row is a few lines of JSON: `locket trigger check` tells you when one is wrong, and its `owner` keeps the full lesson in the file that already holds it.

Rows live in a `triggers.json` at the root of a store. This row asks a question before any shell command that throws away uncommitted work:

```json
{
  "rows": [
    {
      "id": "git-discards-uncommitted",
      "tools": "Bash",
      "content": "git\\s+(?:checkout\\s+--|restore\\b|reset\\s+--hard)",
      "question": "This discards every uncommitted edit in the file, not only the experiment. Copy the file first if any of it is worth keeping.",
      "owner": "memory/git-lessons.md"
    }
  ]
}
```

- **`id`** is a short name you give the row, shown in brackets before the question.
- **`tools`** names the tools the row watches. Use `UserPromptSubmit` to watch your own prompts instead.
- **`content`** is what must appear in the call, as a regular expression.
- **`question`** is what the agent reads.
- **`owner`** is the file that holds the full lesson. The row points there; it does not repeat it.
- **`block: true`** refuses the call outright instead of asking. Say in the question how the agent gets past it.

Rows in Claude Code's `~/.claude`, Codex's `~/.codex` or Hermes's `~/.hermes` fire everywhere on that host. Rows in any other store fire only when the agent is working inside that store's folder.

Keep the list short. A file runs 12 rows at most by default, because a question the agent sees on every call is a question it learns to skim. Write a row for a mistake that has already happened, not for one you can imagine.

```sh
locket trigger check      # checks your rows for mistakes, and that each owner file exists
locket trigger schema     # every key a row can take, with what it does
locket help trigger       # how triggers work
```

Rows name Claude Code's tools, and Hermes's tools count as their Claude Code twins: `Bash` also watches `terminal`, `Write` and `Edit` watch `write_file` and `patch`, and `Read` watches `read_file`. A Hermes tool with no twin is named as itself. On Codex a file edit is a patch, and Locket reads it as the `Write` or `Edit` it amounts to; a row can also name `apply_patch`.

On Hermes a hook cannot add a question to a call, so a row without `block` refuses the call once instead. The agent reads the question and can repeat the same call to go ahead.

## Configure where usage reads from

`locket usage` reads the token counts Claude Code and Hermes already keep, and copies them into its own ledger at `~/.locket/usage.csv`. Claude Code deletes a transcript after 30 days and Hermes prunes a session after 90, so the ledger is the only place older days survive. Back it up with the rest of your files.

It finds both hosts where they usually live: Claude Code's `~/.claude/projects`, or the folder `CLAUDE_CONFIG_DIR` names, and Hermes's `~/.hermes/state.db`, or the one under `HERMES_HOME`. If yours are somewhere else, point at the Claude Code `projects` folder and the Hermes database file:

```sh
locket usage --claude /Volumes/work/claude-config/projects --hermes ~/other-hermes/state.db
```

Or set it once in your shell profile:

```sh
export LOCKET_USAGE_CLAUDE=/Volumes/work/claude-config/projects
export LOCKET_USAGE_HERMES=~/other-hermes/state.db
```

When Locket cannot find a source, it skips with a line saying so.

- **`locket usage today`**, **`week`** (the default) and **`month`** pick the period.
- **`--by project`**, **`--by model`** and **`--by day`** pick how it is broken down.
- **`--json`** prints it for another program.
- **`locket usage record`** updates the ledger without printing a report. It is safe to run as often as you like.

It counts tokens and nothing else. Prices go stale, a subscription is not billed per token, and neither host publishes its plan limits in a place Locket can check. For more on Claude Code alone, [ccusage](https://github.com/ccusage/ccusage) goes further.

## Council stores

Each host's home folder is its **council store**: `~/.claude` for Claude Code, named `council`, `~/.codex` for Codex, named `codex`, and `~/.hermes` for Hermes, named `hermes`. Its rules, skills and memory are checked as one store, so a rule that restates a memory fact is caught like a second memory file would be. Trigger rows in `~/.claude` fire in every project, which makes it the place for lessons that apply everywhere. There is one council store per host, and Locket always looks for it in the default location.
