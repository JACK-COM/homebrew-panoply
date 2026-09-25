<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="marks/panoply-dark.svg">
  <img src="marks/panoply-light.svg" alt="The Panoply" width="112">
</picture>
</p>

# The Panoply

A panoply is a full suit of armor, put on one piece at a time. Each piece guards one place, and a knight wears the pieces the day ahead calls for.

The Panoply does that for an AI agent: Claude Code, Hermes, or any agent that can run a command. An agent working for you runs into the same few troubles again and again. It writes a fact into its memory that its memory already holds. It makes a judgment call and cannot tell you how often that kind of call is right. It reads a long document whole, including the passages someone planted to steer it. Each piece of the Panoply takes one of those troubles off your hands.

## Which piece do you need?

| If your agent… | Put on | What it does |
|---|---|---|
| keeps notes in markdown files and repeats itself across them | [Locket](locket/README.md) | Tells the agent which file already holds a fact before it writes the fact again. It also asks a question at the moment a known mistake is about to repeat, and counts the tokens your agents spend. |
| makes yes-or-no calls about text that you want measured | [Augur](augur/README.md) | Asks a decision model a typed question about a text and returns a probability, then checks that probability against examples you labelled yourself. |
| reads PDFs, saved pages or websites | [Grille](grille/README.md) | Hands the agent only the pages that answer its question, and withholds any passage written to steer the agent instead of inform it. |

Most people start with the piece that matches the trouble they already have. If your agent keeps memory files, that is Locket. If it reads the web or long manuals, that is Grille. Augur is the piece you reach for when you have a rule you want to check with numbers, and Grille uses it on its own when you let it.

## Getting the pieces

```
brew tap jack-com/panoply
brew trust jack-com/panoply
```

Then install the pieces you want, and ask your agent to run `<piece> help install`. Each guide walks through that step and the manual route beside it.

## The pieces are built to work together

Every piece stands on its own, and none of them needs another to run. They are still one set, made by the same hands, and they share what they can instead of each bringing its own copy.

- **Grille asks Augur.** When Grille is unsure whether a page is trying to steer your agent, it can ask Augur, and it uses the threshold Augur's measurements set.
- **Locket and Grille read by meaning with the same tools.** Both rank text by what it means, not only by the words it uses, and they share the software that does it. Install it once and both pieces use it.
- **Removing one piece leaves the others working.** The shared parts go only when the last piece that uses them goes.

<details>
<summary>The technical details</summary>

- **Python.** Every piece runs on Python 3.9 or later using only the standard library. Homebrew installs the Python it needs.
- **The embedder.** Ranking by meaning uses the `nomic-embed-text` model, served by [ollama](https://ollama.com) or run in-process by `fastembed`. Without either, Locket and Grille fall back to shared words and say so on their output.
- **The shared virtualenv.** `fastembed` lives in one virtualenv every piece uses: `~/.panoply/venv`, or an older `~/.locket/venv` when that exists, or wherever `PANOPLY_VENV` points. `uninstall` removes it only with the last piece.
- **Grille's scorer.** Grille runs `augur ask --request - --caller grille` by default. Any command that speaks the same JSON can take Augur's place; the [Grille guide](grille/README.md) shows how.
- **Where each piece keeps its files.** Locket in `~/.locket`, Augur in `~/.augur` (or `$AUGUR_HOME`), Grille in `~/.grille` (or `$GRILLE_HOME`).
- **Hosts.** Locket plugs into Claude Code and Hermes through their hooks, and into any MCP client through `locket mcp`. Augur and Grille are commands any agent with a shell can run.
- **Platforms.** Tested on macOS and Linux (Debian). On Windows, run them under WSL.

</details>

## The guides

- [Locket](locket/README.md): keep an agent's memory from holding the same fact twice.
- [Augur](augur/README.md): ask typed questions about a text and measure the answers.
- [Grille](grille/README.md): read only the pages that matter, and none of the passages written to steer.
