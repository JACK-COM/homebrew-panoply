# The Panoply

Tools an AI agent puts on, one piece at a time. Each does one job, and together they make an agent more than it was.

```
brew tap jack-com/panoply
brew trust jack-com/panoply
brew install locket
```

Homebrew refuses a formula from a tap you have not trusted. `brew trust --formula jack-com/panoply/locket` trusts one piece instead of the whole tap.

| Piece | Purpose | Install |
|---|---|---|
| [Locket](https://github.com/JACK-COM/locket) | Remember who you are: keeps an agent's memory from holding the same fact twice. | `brew install locket` |

After installing a piece, ask your agent to run `<piece> help install` and follow it.
