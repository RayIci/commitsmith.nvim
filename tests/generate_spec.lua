local H = require("helpers")

---A git repository with one staged file, made the working directory, and a
---PATH holding only git, so no agent CLI is found.
local function staged_repo()
  local git = vim.fn.exepath("git")
  local bin = H.dir .. "/bin"
  vim.fn.mkdir(bin, "p")
  vim.uv.fs_symlink(git, bin .. "/git")
  for _, args in ipairs({
    { "init", "-q" },
    { "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "init" },
  }) do
    vim.system(vim.list_extend({ "git" }, args), { cwd = H.dir }):wait()
  end
  vim.fn.writefile({ "hello" }, H.dir .. "/a.txt")
  vim.system({ "git", "add", "a.txt" }, { cwd = H.dir }):wait()
  vim.env.PATH = bin
end

describe("generate", function()
  it("hands the fallback prompt to on_fallback outside a commit buffer", function()
    local received
    require("commitsmith").setup({
      on_fallback = function(prompt)
        received = prompt
      end,
    })
    H.buffer("lua")
    require("commitsmith").generate()
    eq(require("commitsmith").fallback_prompt(), received)
  end)

  it("reports that a commit buffer is required when there is no fallback", function()
    require("commitsmith").setup({})
    H.buffer("lua")
    local seen = H.notifications(function()
      vim.cmd("Commitsmith generate")
    end)
    eq("This requires a commit buffer", seen[1].msg)
    eq(vim.log.levels.WARN, seen[1].level)
  end)

  it("fails on a missing harness without substituting another or falling back", function()
    staged_repo()
    local fallback_called = false
    require("commitsmith").setup({
      harness = "claude",
      on_fallback = function()
        fallback_called = true
      end,
    })
    H.buffer("gitcommit")
    local seen = H.notifications(function()
      require("commitsmith").generate()
    end)
    local errors = vim.tbl_filter(function(n)
      return n.level == vim.log.levels.ERROR
    end, seen)
    eq(1, #errors, vim.inspect(seen))
    eq("`claude` is not installed. Pick another with :Commitsmith harness", errors[1].msg)
    eq(false, fallback_called)
    eq("claude", require("commitsmith.settings").harness())
  end)
end)

describe("subcommands", function()
  for _, name in ipairs({ "chat", "stop", "clear", "accept" }) do
    it(name .. " requires a commit buffer", function()
      require("commitsmith").setup({})
      H.buffer("lua")
      local seen = H.notifications(function()
        vim.cmd("Commitsmith " .. name)
      end)
      eq("This requires a commit buffer", seen[1] and seen[1].msg)
    end)
  end

  it("lean toggles and persists outside a commit buffer", function()
    require("commitsmith").setup({})
    H.buffer("lua")
    H.notifications(function()
      vim.cmd("Commitsmith lean")
    end)
    eq(true, require("commitsmith.settings").lean())
  end)
end)
