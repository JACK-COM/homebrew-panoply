<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/marks/panoply-dark.svg">
  <img src="docs/marks/panoply-light.svg" alt="The Panoply" width="112">
</picture>
</p>

# The Panoply

*Carry all you need.* Tools an AI agent puts on, one piece at a time. Each does one job, and together they make an agent more than it was.

```
brew tap jack-com/panoply
brew trust jack-com/panoply
brew install locket
```

Homebrew refuses a formula from a tap you have not trusted. `brew trust --formula jack-com/panoply/locket` trusts one piece instead of the whole tap.

| | Piece | Purpose | Install |
|---|---|---|---|
| <picture><source media="(prefers-color-scheme: dark)" srcset="docs/marks/locket-dark.svg"><img src="docs/marks/locket-light.svg" alt="Locket" width="40"></picture> | [Locket](https://github.com/JACK-COM/locket) | Remember who you are: keeps an agent's memory from holding the same fact twice. | `brew install locket` |

After installing a piece, ask your agent to run `<piece> help install` and follow it.
