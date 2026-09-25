<!-- reviewed: locket 0.4.0 -->
# Make Locket yours

[← Locket](README.md)

Locket works out of the box on Claude Code and Hermes. This page is for everything else: your own memory folders, a different embedder, lessons you want put to the agent, and usage kept somewhere unusual. Each section shows one worked example and points to the command that lists every option, so this page never has to keep up with a changing list.

**On this page:** [Stores](#stores) · [The embedder](#the-embedder) · [Trigger rows](#trigger-rows) · [Where usage reads from](#where-usage-reads-from)

## Stores

A **store** is a folder of markdown your agent writes memory into. Locket checks each store against itself.

- **Claude Code** is found without setup. `~/.claude` is one store (its memory, rules, skills, agents and the markdown at the top), and each project's memory folder under `~/.claude/projects/` is a store of its own.
- **Hermes** is found without setup too: `~/.hermes`, with `memories/` and `SOUL.md`.
- **Any other folder** needs one command:

  ```
  locket init ~/notes/agent-memory
  ```

  Only `init` adds a store to the list. A `locket.json` you write by hand is not enough on its own, because Locket never searches your disk for one.

Two folders that are really one memory, such as a project's documents and the agent's notes about that project, can join:

```
locket init ~/work/myapp/docs --parent myapp-memory
```

`locket corpora` lists every store Locket knows. `locket forget <folder>` drops one.

### The manifest: `locket.json`

A store's `locket.json` holds its exceptions. Every key is optional, and a store without one uses the defaults. This one skips backup files, keeps a log from being scored as if it were facts, and lets `find` rank the rows of a spreadsheet of decisions:

```json
{
  "excluded_files": ["*.bak*"],
  "ledger_surfaces": ["CHANGELOG.md"],
  "sources": [
    {"path": "RULINGS.csv", "text": "Ruling", "label": "Area"}
  ]
}
```

- **`excluded_files`** and **`excluded_dirs`**: files and folders that are not memory.
- **`ledger_surfaces`**: files that grow by adding entries on purpose, such as a log, so repeats there are not flagged.
- **`holding_spaces`**: scratch or inbox files whose entries should each be unique, and which are checked only against themselves.
- **`sources`**: CSV files whose rows `find` should rank beside your markdown.

`locket help scan` explains every key. `locket schema` writes a schema your editor can use for hints, and `locket schema <folder>` checks a store's manifest.

## The embedder

An **embedder** turns a sentence into a position in meaning, so "we ship from main" and "deploys happen off the main branch" land close together. Without one, `find` compares words, and a fact written in new words slips past.

Locket uses the first of these that answers:

1. **[ollama](https://ollama.com)** serving `nomic-embed-text`. If ollama is installed, `ollama pull nomic-embed-text` is all it takes; Locket starts the server when it needs it.
2. **`fastembed`**, which runs inside Python with no server. It lives in the virtualenv every Panoply piece shares:
   ```
   python3 -m venv ~/.panoply/venv
   ~/.panoply/venv/bin/python -m pip install fastembed
   ```
   The model downloads on first use, about 130 MB.
3. **Word overlap**, when neither answers. Locket says so on its output.

`locket embedder` shows which one answers on this machine. After any change, run `locket index all` to read your stores again.

<details>
<summary>Pointing Locket at a different embedder</summary>

| Variable | What it changes | Default |
|---|---|---|
| `OLLAMA_HOST` | Where ollama is served, for example another machine | `http://127.0.0.1:11434` |
| `MEMFIND_MODEL` | The ollama model | `nomic-embed-text` |
| `MEMFIND_FASTEMBED_MODEL` | The fastembed model | `nomic-ai/nomic-embed-text-v1.5` |
| `PANOPLY_VENV` | Where the shared virtualenv lives | `~/.panoply/venv` |
| `MEMFIND_NO_AUTOSTART=1` | Stops Locket starting ollama itself | unset |

Locket is tested with `nomic-embed-text`. Another model changes what a score means, so read the rankings with fresh eyes after a switch.

</details>

## Trigger rows

Some mistakes are not about memory at all. An agent runs `git reset --hard` and loses an hour of work it had not committed, and next month it does it again. A **trigger row** is that lesson written once, and put to the agent at the moment it is about to run the command again.

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

- **`tools`** names the tools the row watches. Use `UserPromptSubmit` to watch your own prompts instead.
- **`content`** is what must appear in the call, as a regular expression.
- **`question`** is what the agent reads.
- **`owner`** is the file that holds the full lesson. The row points there; it does not repeat it.
- **`block: true`** refuses the call outright instead of asking. Say in the question how the agent gets past it.

Rows in Claude Code's `~/.claude` fire everywhere. Rows in any other store fire only when the agent is working inside that store's folder.

Keep the list short. A file runs 12 rows at most by default, because a question the agent sees on every call is a question it learns to skim. Write a row for a mistake that has already happened, not for one you can imagine.

```
locket trigger check      checks your rows for mistakes, and that each owner file exists
locket trigger schema     every key a row can take, with what it does
locket help trigger       how triggers work
```

Trigger rows fire on Claude Code. On Hermes they do not fire yet.

## Where usage reads from

`locket usage` reads the token counts Claude Code and Hermes already keep, and copies them into its own ledger at `~/.locket/usage.csv`. Claude Code deletes a transcript after 30 days and Hermes prunes a session after 90, so the ledger is the only place older days survive. Back it up with the rest of your files.

It finds both hosts where they usually live: Claude Code's `~/.claude/projects`, or the folder `CLAUDE_CONFIG_DIR` names, and Hermes's `~/.hermes/state.db`, or the one under `HERMES_HOME`. If yours are somewhere else, point at the Claude Code `projects` folder and the Hermes database file:

```
locket usage --claude /Volumes/work/claude-config/projects --hermes ~/other-hermes/state.db
```

Or set it once in your shell profile:

```
export LOCKET_USAGE_CLAUDE=/Volumes/work/claude-config/projects
export LOCKET_USAGE_HERMES=~/other-hermes/state.db
```

A source Locket cannot find is skipped, with a line saying so.

- **`locket usage today`**, **`week`** (the default) and **`month`** pick the period.
- **`--by project`**, **`--by model`** and **`--by day`** pick how it is broken down.
- **`--json`** prints it for another program.
- **`locket usage record`** updates the ledger without printing a report. It is safe to run as often as you like.

It counts tokens and nothing else. Prices go stale, a subscription is not billed per token, and neither host publishes its plan limits in a place Locket can check. For more on Claude Code alone, [ccusage](https://github.com/ccusage/ccusage) goes further.
