local context = require("amanoukihashi.context")

describe("context", function()
  describe("expand", function()
    local orig_buf_get_name
    local orig_buf_get_mark
    local orig_buf_get_text
    local orig_buf_get_lines
    local orig_fnamemodify

    local ctx = { win = 1, buf = 42, cwd = "/test", row = 1, col = 1 }

    before_each(function()
      orig_buf_get_name  = vim.api.nvim_buf_get_name
      orig_buf_get_mark  = vim.api.nvim_buf_get_mark
      orig_buf_get_text  = vim.api.nvim_buf_get_text
      orig_buf_get_lines = vim.api.nvim_buf_get_lines
      orig_fnamemodify   = vim.fn.fnamemodify
    end)

    after_each(function()
      vim.api.nvim_buf_get_name  = orig_buf_get_name
      vim.api.nvim_buf_get_mark  = orig_buf_get_mark
      vim.api.nvim_buf_get_text  = orig_buf_get_text
      vim.api.nvim_buf_get_lines = orig_buf_get_lines
      vim.fn.fnamemodify         = orig_fnamemodify
    end)

    it("{file} を ctx.buf のファイルパスに展開する", function()
      vim.api.nvim_buf_get_name = function(buf)
        assert.equal(42, buf)
        return "/project/lua/foo/bar.lua"
      end
      vim.fn.fnamemodify = function(name, mod)
        if mod == ":." then return "lua/foo/bar.lua" end
        return orig_fnamemodify(name, mod)
      end
      assert.equal("lua/foo/bar.lua", context.expand("{file}", ctx))
    end)

    it("{selection} を ctx.buf のビジュアル選択テキストに展開する", function()
      vim.api.nvim_buf_get_mark = function(buf, name)
        assert.equal(42, buf)
        if name == "<" then return { 1, 0 } end
        if name == ">" then return { 1, 5 } end
      end
      vim.api.nvim_buf_get_lines = function(buf, _, _, _)
        assert.equal(42, buf)
        return { "hello world" }
      end
      vim.api.nvim_buf_get_text = function(buf, sr, sc, er, ec, _)
        assert.equal(42, buf)
        assert.equal(0, sr)
        assert.equal(0, sc)
        assert.equal(0, er)
        assert.equal(6, ec)
        return { "hello " }
      end
      assert.equal("hello ", context.expand("{selection}", ctx))
    end)

    it("{selection} が複数行のとき改行で結合する", function()
      vim.api.nvim_buf_get_mark = function(_, name)
        if name == "<" then return { 1, 0 } end
        if name == ">" then return { 2, 4 } end
      end
      vim.api.nvim_buf_get_lines = function()
        return { "world" }
      end
      vim.api.nvim_buf_get_text = function()
        return { "foo", "bar" }
      end
      assert.equal("foo\nbar", context.expand("{selection}", ctx))
    end)

    it("未知の変数はそのまま残す", function()
      assert.equal("{unknown}", context.expand("{unknown}", ctx))
    end)

    it("変数が含まれない場合はそのまま返す", function()
      assert.equal("plain text", context.expand("plain text", ctx))
    end)

    it("{file} と {selection} を同時に展開する", function()
      vim.api.nvim_buf_get_name = function()
        return "/project/src/main.lua"
      end
      vim.fn.fnamemodify = function(_, mod)
        if mod == ":." then return "src/main.lua" end
        return orig_fnamemodify(_, mod)
      end
      vim.api.nvim_buf_get_mark = function(_, name)
        if name == "<" then return { 1, 0 } end
        if name == ">" then return { 1, 1 } end
      end
      vim.api.nvim_buf_get_lines = function()
        return { "hi" }
      end
      vim.api.nvim_buf_get_text = function()
        return { "hi" }
      end
      assert.equal("src/main.lua: hi", context.expand("{file}: {selection}", ctx))
    end)
  end)
end)
