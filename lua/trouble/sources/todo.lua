---@diagnostic disable: inject-field
local Config = require("todo-comments.config")
local Item = require("trouble.item")
local Search = require("todo-comments.search")

---@type trouble.Source
local M = {}

---@diagnostic disable-next-line: missing-fields
M.config = {
  formatters = {
    todo_icon = function(ctx)
      return {
        text = Config.options.keywords[ctx.item.tag].icon,
        hl = "TodoFg" .. ctx.item.tag,
      }
    end,
    days_remaining_str = function(ctx)
      return {
        text = ctx.item.days_remaining_str,
        hl = "TodoFg" .. "WARN"
      }
    end,
  },
  modes = {
    todo = {
      events = { "BufEnter", "BufWritePost" },
      source = "todo",
      groups = {
        { "tag", format = "{todo_icon} {tag}" },
        -- { "directory" },
        { "filename", format = "{file_icon} {filename} {count}" },
      },
      sort = { { buf = 0 }, "filename", "pos", "message" },
      format = "{todo_icon} {text} {pos} {days_remaining_str}",
    },
  },
}

function M.get(cb)
  Search.search(function(results)
    local items = {} ---@type trouble.Item[]
    for _, item in pairs(results) do
      local row = item.lnum
      local col = item.col - 1


      local days_remaining = 10000
      local date_str = string.match(item.text, "%[(%d%d%-%d%d%-%d%d%d%d)%]")
      if date_str then
        local day, month, year = date_str:match("(%d%d)%-(%d%d)%-(%d%d%d%d)")
        day = tonumber(day)
        month = tonumber(month)
        year = tonumber(year)
        if day and month and year then
          local due_date = os.time({year = year, month = month, day = day, hour = 0, min = 0, sec = 0})
          local now = os.time({year = os.date("%Y"), month = os.date("%m"), day = os.date("%d"), hour = 0, min = 0, sec = 0})
          local diff_in_seconds = due_date - now
          local remaining = math.ceil(diff_in_seconds / (24 * 3600))
          days_remaining = remaining
        end
      end

      local days_remaining_str = (days_remaining == 10000) and "" or "(" .. days_remaining .. " days remaining)"

      items[#items + 1] = Item.new({
        buf = vim.fn.bufadd(item.filename),
        pos = { row, col },
        end_pos = { row, col + #item.tag },
        text = item.text,
        filename = item.filename,
        item = item,
        source = "todo",
        days_remaining = days_remaining,
        days_remaining_str = days_remaining_str
      })
    end
    cb(items)
  end, {})
end

return M
