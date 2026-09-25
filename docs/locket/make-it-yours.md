<!-- reviewed: locket 0.4.0 -->
# Customize your Locket installation

[← Locket](README.md)

Locket works out of the box on Claude Code and Hermes. This page is for everything else: your own memory folders, a different embedder, lessons you want put to the agent, and usage kept somewhere unusual. Each section shows one worked example and points to the command that lists every option, so this page never has to keep up with a changing list.

**On this page:** [Stores](#stores) · [The embedder](#the-embedder) · [Trigger rows](#trigger-rows) · [Where usage reads from](#configure-where-usage-reads-from) · [Council stores](#council-stores)

## Stores

A **store** is a folder of markdown your agent writes memory into. Locket checks each store against itself.

- **Claude Code** is found without setup. 
  - `~/.claude` is one store (its memory, rules, skills, agents and the markdown at the top).
  - Each project's memory folder under `~/.claude/projects/` is a store of its own.
- **Hermes** is found without setup too: `~/.hermes`, with `memories/` and `SOUL.md`.
- **For any other folder**, run the following command:

  ```sh
  locket init <path/to/folder>
  ```

  Replace `<path/to/folder>` with a path to the target folder.

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

Run `locket forget <folder>` to drop a store.


### The manifest: `locket.json`

A store's `locket.json` holds its exceptions. Every key is optional, and a store without one uses the defaults.
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

- **`excluded_files`** and **`excluded_dirs`**: files and folders that are not memory.
- **`ledger_surfaces`**: files that grow by adding entries on purpose, such as a log, so repeats there are not flagged.
- **`holding_spaces`**: scratch or inbox files whose entries should each be unique, and which are checked only against themselves.
- **`sources`**: CSV files whose rows `find` should rank beside your markdown.

Run `locket help scan` for an explanation of every key. 
To manually edit a manifest in a code editor, `locket schema` writes a schema your editor can use for hints, and `locket schema <folder>` checks a store's manifest.

## The embedder

An **embedder** turns a sentence into a position in meaning, so that "*we ship from main*" and "*deploys happen off the main branch*" land close together.
Without one, `locket find` compares words only, and a fact written in new words can silently cause divergence.

Locket uses the first of these that responds:

1. **[ollama](https://ollama.com)** serving `nomic-embed-text`. If ollama is installed, `ollama pull nomic-embed-text` is all it takes; Locket starts the server when it needs it.
2. **`fastembed`**, which runs inside Python with no server. It lives in the virtualenv every Panoply piece shares:
   ```sh
   python3 -m venv ~/.panoply/venv
   ~/.panoply/venv/bin/python -m pip install fastembed
   ```
   The model downloads on first use, about 130 MB.
3. **Word overlap**, when neither answers. Locket says so on its output.

`locket embedder` shows which one answers on this machine. After any change, run `locket index all` to read your stores again.

### Use a different embedder

Locket reads these environment variables every time it runs, and has no settings file for them. For a single command, put the variable in front of it:

```sh
OLLAMA_HOST=http://gpu-box.local:11434 locket find "we ship from main"
```

To make a change permanent, set the variable everywhere Locket runs. Your agent runs Locket too, through its hooks, and a hook sees the agent's environment, not your terminal's:

- **Your terminal:** add `export MEMFIND_MODEL=...` to your shell profile, such as `~/.zshrc`.
- **Claude Code:** add it to the `env` block in `~/.claude/settings.json`, which every session and hook inherits:
  ```json
  { "env": { "MEMFIND_MODEL": "mxbai-embed-large" } }
  ```
- **Hermes:** set it in the environment you start Hermes from.
- **Claude Desktop:** add an `env` block to the `locket` entry under `mcpServers`.

Keep the model the same in all of them. The index records which model built it, and a run with a different model builds it again from scratch, so a model set in your terminal but not in the hooks rebuilds the index back and forth. `OLLAMA_HOST` does not have this problem, because it moves the server and not the model.

| Variable | What it changes | Default |
|---|---|---|
| `OLLAMA_HOST` | Where ollama is served, for example another machine | `http://127.0.0.1:11434` |
| `MEMFIND_MODEL` | The ollama model | `nomic-embed-text` |
| `MEMFIND_FASTEMBED_MODEL` | The fastembed model | `nomic-ai/nomic-embed-text-v1.5` |
| `PANOPLY_VENV` | Where the shared virtualenv lives | `~/.panoply/venv` |
| `MEMFIND_NO_AUTOSTART=1` | Stops Locket starting ollama itself | unset |

Locket is tested with `nomic-embed-text`. Another model changes what a score means, so read the rankings with fresh eyes after a switch.

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

Rows in Claude Code's `~/.claude` fire everywhere. Rows in any other store fire only when the agent is working inside that store's folder.

Keep the list short. A file runs 12 rows at most by default, because a question the agent sees on every call is a question it learns to skim. Write a row for a mistake that has already happened, not for one you can imagine.

```sh
locket trigger check      # checks your rows for mistakes, and that each owner file exists
locket trigger schema     # every key a row can take, with what it does
locket help trigger       # how triggers work
```

Trigger rows fire on Claude Code. On Hermes they do not fire yet.

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

Each host's home folder is its **council store**: `~/.claude` for Claude Code, named `council`, and `~/.hermes` for Hermes, named `hermes`. Its rules, skills and memory are checked as one store, so a rule that restates a memory fact is caught like a second memory file would be. Trigger rows in `~/.claude` fire in every project, which makes it the place for lessons that apply everywhere. There is one council store per host, and Locket always looks for it in the default location.
