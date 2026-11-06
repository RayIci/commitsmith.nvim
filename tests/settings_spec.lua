local function settings_file()
  return require("commitsmith.settings").path()
end

local function write_file(value)
  local path = settings_file()
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ vim.json.encode(value) }, path)
end

local function read_file()
  return vim.json.decode(table.concat(vim.fn.readfile(settings_file()), "\n"))
end

describe("settings", function()
  it("live under stdpath('data')/commitsmith", function()
    eq(vim.fs.joinpath(vim.fn.stdpath("data"), "commitsmith", "settings.json"), settings_file())
  end)

  it("fall back to the configured harness and the adapter's default model", function()
    require("commitsmith").setup({ harness = "codex" })
    local settings = require("commitsmith.settings")
    ok(settings.is_empty())
    eq("codex", settings.harness())
    eq(require("commitsmith.harness").get("codex").default_model, settings.model("codex"))
    eq(false, settings.lean())
  end)

  it("are re-read from disk on every access", function()
    require("commitsmith").setup({})
    local settings = require("commitsmith.settings")
    write_file({ harness = "claude" })
    eq("claude", settings.harness())
    -- another Neovim instance changes the file
    write_file({ harness = "codex", lean = true })
    eq("codex", settings.harness())
    eq(true, settings.lean())
  end)

  it("keep keys written by another instance when one key changes", function()
    require("commitsmith").setup({})
    local settings = require("commitsmith.settings")
    write_file({ models = { claude = "opus" }, lean = true })
    settings.set_harness("claude")
    eq({ harness = "claude", models = { claude = "opus" }, lean = true }, read_file())
    eq("opus", settings.model("claude"))
  end)

  it("ignore an unknown persisted harness", function()
    require("commitsmith").setup({ harness = "copilot" })
    write_file({ harness = "nope" })
    eq("copilot", require("commitsmith.settings").harness())
  end)

  it("no longer accept a seed option", function()
    require("commitsmith").setup({
      seed = function() ---@diagnostic disable-line: missing-fields
        return { harness = "claude" }
      end,
    })
    ok(require("commitsmith.settings").is_empty(), "nothing was seeded")
    eq(nil, require("commitsmith.settings").seed)
  end)
end)
