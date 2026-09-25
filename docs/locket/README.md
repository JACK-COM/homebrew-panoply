<!-- reviewed: locket 0.4.0 -->
<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../marks/locket-dark.svg">
  <img src="../marks/locket-light.svg" alt="Locket" width="96">
</picture>
</p>

# Locket

*Remember who you are.* A locket is a small keepsake that preserves a memory. `Locket` keeps an AI agent's memory that way: small, and holding each thing once.

Is the following sequence familiar?

1. After learning something new/important, your agent "remembers it" in a markdown file.
2. Some time later, the agent needs the info from (1). However, it doesn't remember doing (1), so it "re-learns" the solution again... *in a different markdown file*.
3. *Repeat Step (2)*

`Locket` catches the second copy while it is being written, and names the file that already holds the fact so the agent edits that file instead.

`Locket` can also put a question to your agent at the moment a known mistake is about to repeat. It also includes a convenience helper for counting your Claude Code and/or Hermes token spend.

**On this page:** [When to use it](#when-to-use-it) · [Install](#install) · [The first five minutes](#the-first-five-minutes) · [Everyday use](#everyday-use) · [Troubleshooting](#troubleshooting) · [Uninstall](#uninstall)
**Next page:** [Customize your installation](make-it-yours.md): stores, the embedder, trigger rows, and where usage reads from.

## When to use it

1. **Your agent keeps its memory, rules or notes as markdown files on disk.** 
   * This includes: Claude Code's `~/.claude` and its per-project memory; Hermes's `~/.hermes`; any markdown folder you point an agent at.

2. **Your agent keeps repeating the same mistake.** 
   * A trigger row lets you write the lesson once and have it put to the agent every time the risky command comes up.

3. **You're on a mad quest for optimization**
   * `locket usage` shows what your agents spend, day by day and project by project. All derived and stored locally.

<details>
<summary><b>When not to use it</b></summary>

- **Your agent's memory is not markdown files on disk**, such as a vector database or a hosted memory service.
- You want to know whether a stored fact is still **true**. Locket checks structure: *where* a fact lives and how many times. It cannot tell a true fact from a stale one, and it cannot find two files that contradict each other.
- You want prices or plan limits. `locket usage` counts tokens only.

</details>

## Install

### Easy: let your agent do it

```
brew tap jack-com/panoply
brew trust --formula jack-com/panoply/locket
brew install locket
```

Then say to your agent: **"Run `locket help install` and follow it."**

The agent finds your memory folders, sets up reading by meaning, asks you before it registers any hooks, and reports back in under ten lines. Claude Code and Hermes each ask you once to approve the new hooks. Say yes, or read what they do first; the agent will tell you.

### Advanced: set it up yourself

The steps your agent follows are written out in [INSTALL-locket.md](https://github.com/JACK-COM/locket/blob/main/src/locket/INSTALL-locket.md), and you can follow them by hand. In short:

1. **Get the command.** Homebrew as above, or `uv tool install git+https://github.com/JACK-COM/locket`, or copy the scripts and run `python3 locket.py install`.
2. **Tell Locket where your memory is.** Claude Code's and Hermes's folders are found on their own. For any other folder, run `locket init <folder>`. See [Stores](make-it-yours.md#stores).
3. **Give it an embedder**, so it can match a fact written in new words. See [The embedder](make-it-yours.md#the-embedder).
4. **Register the hooks.** 
   * On Claude Code, `locket install --hooks`. 
   * On Claude Desktop, `locket install --desktop`. Another MCP client takes `locket mcp` as a server entry you add by hand.
   * On Hermes, paste the lines [INSTALL-locket.md](https://github.com/JACK-COM/locket/blob/main/src/locket/INSTALL-locket.md#step-4-register-the-hooks) gives into `~/.hermes/config.yaml`. 
5. **Check it.** `locket doctor`.

## The first five minutes

1. Run `locket doctor`. Every row should read `ok`. 
   * A `warn` names something Locket works without.
   * A `fail` names the command that fixes it.
2. Ask it about a fact you know your agent has written down.\
   The following example checks whether a deployment fact is saved:
   ```sh
   locket find "the project deploys from the main branch"
   ```
   The top of the list is the file most likely to hold that fact already, with a score. Try a different wording of the same fact; with an embedder, the same file should still come first.
3. Run `locket audit`. It lists **sentence pairs that say the same thing in two different files**.
   * Read a few. Some will be real copies to merge, and some will be an index line pointing at the file it describes, which is fine.
   * You can work through the results with your agent, or ignore them for now.
4. Run `locket usage`. You should see this week's tokens for Claude Code and Hermes, whichever you use.

## Everyday use

Mostly, you do nothing. The hooks run while your agent works:

- **Before the agent writes a fact into memory**, Locket checks whether another file already holds it. If one does, the agent is told which file, and rewrites that file instead of adding a second copy.
- **Before the agent searches your memory with plain text search**, Locket adds the files most likely to hold the idea by meaning, since a text search misses the same fact in other words.
- **Before the agent writes into memory through the shell**, Locket stops it and asks it to use its file tools, which the other hooks can see.
- **When a Claude Code session ends**, Locket copies that session's token counts into its own ledger.

A few commands are worth running yourself, or asking your agent to run at the end of a working session:

```sh
locket find "a fact you are about to write"    # which file already holds the fact to be written
locket audit                                   # find any facts stated in two files
locket graduated                               # notes a permanent file already holds, ready to clear
locket links                                   # links that point at nothing
locket usage                                   # tokens this week, against a typical day
locket usage month --by project                # 30 days, per project
```

`locket -h` lists every command, and `locket <command> -h` gives you help for a single command.

### How you know it is working

- **`locket doctor` proves the Claude Code hooks fire.** 
  - After checking they are registered, it hands the write hook a known copy and checks that the hook catches it. `ok claude hooks  registered, and the write hook fires on a known fork` is that proof.
- **You see it in the session.** 
  - When your agent goes to write a fact its memory already holds, a note from Locket appears in the conversation naming the file that holds it, and the agent edits that file instead.
  - On Hermes the note reaches the agent on its next turn.
- **`locket usage` has today in it.** 
  - The usage row in `doctor` says when the ledger last recorded.
- **Silence is normal.** 
  - Most writes are new facts, and a new fact passes without a note. If you have gone a week without seeing one, run `locket doctor`.

## Troubleshooting

Start with `locket doctor`. Each row is one part of the install, and each `fail` or `warn` ends with the command that fixes it.

| Row | What it means | What to do |
|---|---|---|
| `command` fails | `locket` is not on your `PATH`. | `locket install`, or open a new terminal after `brew install`. |
| `stores` fails | Locket found no memory folder. | `locket init <your memory folder>`. |
| `embedder` warns | Nothing can read by meaning, so `find` matches words only and misses a fact written differently. | [The embedder](make-it-yours.md#the-embedder). |
| `index` warns | A store has not been read yet. | `locket index all`. |
| `claude hooks` fails, "not registered" | The hooks are missing from `~/.claude/settings.json`. | `locket install --hooks`. |
| `claude hooks` fails, "registered, but the write hook…" | Claude Code has not loaded the new hooks. | Run `/reload-plugins` in Claude Code, or restart the session. |
| `claude hooks` or `usage` fails, "missing script" | The hooks point at an old copy of Locket, often after moving from scripts to Homebrew. | `locket install --hooks` again. |
| `triggers` fails | A `triggers.json` row has a mistake, or rows exist and the hook is not registered. | `locket trigger check` names the row. |
| `usage` warns | Nothing records usage as sessions end, so a day can age out before it is saved. | `locket install --hooks`. |
| `hermes hooks` warns | Some of the four Hermes hooks are missing from `config.yaml`. | Step 4 of `locket help install`. All four are needed. |
| `desktop server` fails | Claude Desktop points at a Locket that moved. | `locket install --desktop`, then restart the app. |

Two things `doctor` cannot see:

- **`find` ranks a file you did not expect first.** A score is a hint, never a verdict. Read the top two or three files; the owner is often one you would not have searched.
- **A hook message cites `prime-memory-discipline.md`.** That file holds the rules behind the checks where a setup carries it. Where it is absent, read the reference as Step 6 of `locket help install`.

## Uninstall

```
locket uninstall --dry-run     shows what would go
locket uninstall               removes it, after asking once
brew uninstall locket          if you installed with Homebrew
```

Uninstall removes the `locket` command link, everything in `~/.locket` except the usage ledger, every cache, the Claude Code hook entries and the Claude Desktop server entry. It keeps a copy of each settings file it edits.

It leaves behind:

- **Your memory.** Locket never edits your markdown.
- **The usage ledger**, `~/.locket/usage.csv`, because it holds days the hosts have already deleted. `--purge` removes it, with each store's `locket.json`.
- **The Hermes hook lines** in `~/.hermes/config.yaml`, which you remove by hand.
- **The shared embedder virtualenv**, if another Panoply piece still uses it. It goes with the last piece.
