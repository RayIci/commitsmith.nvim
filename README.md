# commitsmith.nvim

AI commit messages for Neovim, refined in conversation. From inside the `gitcommit`
buffer, commitsmith sends the staged diff to an agent CLI (Claude Code, Codex or GitHub
Copilot CLI) in headless mode and writes back a Conventional Commits message. A
conversation window lets you refine it ("shorter", "more detail", your own words) until
it is right; each revision replaces the message in the buffer.

## Requirements

- Neovim ≥ 0.12 and `git`
- At least one agent CLI on `PATH`: `claude`, `codex` or `copilot`
- No other plugins

## Install

With `vim.pack`:

```lua
vim.pack.add({ "https://github.com/RayIci/commitsmith.nvim" })
require("commitsmith").setup({})
```

## Setup

```lua
require("commitsmith").setup({
  harness = "copilot",          -- used until you pick one with :Commitsmith harness
  output = "stream",            -- or "batch"
  conversation = "auto",        -- "session" | "replay"
  apply = "auto",               -- "manual" waits for :Commitsmith accept
  window = { layout = "right", width = 84, height = 20, border = "rounded" },
  -- Outside a gitcommit buffer, hand a prompt to an interactive agent instead:
  on_fallback = function(prompt)
    require("sidekick.cli").send({ prompt = prompt })
  end,
})

local commitsmith = require("commitsmith")
vim.keymap.set("n", "<leader>am", commitsmith.generate, { desc = "Draft commit message" })
vim.keymap.set("n", "<leader>ac", commitsmith.chat, { desc = "Commit message chat" })
vim.keymap.set("n", "<leader>aM", commitsmith.harness, { desc = "Configure commit AI" })
```

`setup()` maps no keys. See `:help commitsmith` for every option.
`require("commitsmith").fallback_prompt()` returns the prompt `on_fallback` receives, for
sending the same request to an interactive agent yourself.

## Usage

Everything runs through `:Commitsmith <subcommand>`:

| Subcommand | What it does |
|---|---|
| `generate` | Read the staged diff and write a message into the commit buffer. Outside a `gitcommit` buffer it calls `on_fallback`. |
| `chat` | Toggle the conversation window. |
| `harness` | Pick the agent CLI, then a model for it. |
| `model` | Pick a model for the current harness, including a free-text custom id. |
| `lean` | Toggle invoking the harness with no tools and no MCP servers. |
| `stop` | Cancel an in-flight generation. |
| `clear` | Empty the conversation and start over. |
| `accept` | Write the latest revision to the buffer (only with `apply = "manual"`). |

In the conversation window: `i` to type a refinement, `s`/`d`/`t` for canned ones
(shorter, more detail, fix type/scope), `r` to regenerate, `<Tab>` to expand the staged
diff, `a` accept, `x` stop, `c` clear, `q` close.

The harness, its model and the lean flag are global, persisted to
`stdpath("data")/commitsmith/settings.json` and re-read on every access, so several
Neovim instances stay in step. A persisted harness that is not installed is an error; no
other harness is silently used instead. `codex` emits no incremental output, so its
replies arrive whole.

## Development

```sh
make test        # headless test suite, no dependencies
make fmt-check   # stylua
make helptags
```

## License

MIT
