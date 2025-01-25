local M = {}

M.setup = function(opts)
    opts = opts or {}
end

local function create_floating_window(buf, opts)
    opts = opts or {}

    -- Get or create new buffer
    if not vim.api.nvim_buf_is_valid(buf) then
        buf = vim.api.nvim_create_buf(false, true)
    end

    -- Define window configuration
    local win_config = opts

    -- Create the floating window
    local win = vim.api.nvim_open_win(buf, true, win_config)

    return { buf = buf, win = win }
end

---The main terminal background could be darker than the editor background
---@param opts table
local set_term_bg_hi = function(opts)
    local factor = opts.factor or 0.6
    local color

    if opts.bg_color then
        color = opts.bg_color
    else
        -- Try to guess a good background color for the main terminal window.
        local normal_bg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Normal", create = false }).bg)

        local red = tonumber("0x" .. string.sub(normal_bg, 2, 3))
        local green = tonumber("0x" .. string.sub(normal_bg, 4, 5))
        local blue = tonumber("0x" .. string.sub(normal_bg, 6, 7))

        local hex_red = string.format("%02x", red * factor)
        local hex_green = string.format("%02x", green * factor)
        local hex_blue = string.format("%02x", blue * factor)

        color = "#" .. hex_red .. hex_green .. hex_blue
    end

    vim.cmd.highlight("MainTerminalNormal guibg=" .. color)
end

M.start_zenmode = function()
    local presentation_width = math.floor(vim.o.columns * 0.6)

    local windows = {
        background = {
            relative = "editor",
            width = vim.o.columns,
            height = vim.o.lines,
            style = "minimal",
            col = 0,
            row = 0,
            zindex = 1,
        },
        zen = {
            relative = "editor",
            width = presentation_width,
            height = vim.o.lines,
            -- style = "minimal",
            row = 0,
            col = math.floor((vim.o.columns - presentation_width) / 2),
            zindex = 2,
        },
    }

    set_term_bg_hi {}
    vim.api.nvim_create_autocmd("ColorScheme", {
        desc = "Update terminal background color",
        group = vim.api.nvim_create_augroup("one_term_setup_augroup", { clear = true }),
        callback = function()
            set_term_bg_hi {}
        end,
    })

    local current_buf = vim.api.nvim_get_current_buf()
    local background = create_floating_window(-1, windows.background)
    local zen = create_floating_window(current_buf, windows.zen)
    vim.api.nvim_set_option_value("winhighlight", "Normal:MainTerminalNormal", { win = background.win })
    vim.api.nvim_set_option_value("signcolumn", "yes", { win = zen.win })

    local plugin_options = {
        cmdheight = {
            original = vim.o.cmdheight,
            plugin = 0,
        },
    }

    -- global options to restore
    for option, config in pairs(plugin_options) do
        vim.opt[option] = config.plugin
    end

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = zen.buf,
        callback = function()
            for option, config in pairs(plugin_options) do
                vim.opt[option] = config.original
            end
            vim.api.nvim_win_close(background.win, true)
        end,
    })

end

M.start_zenmode()

return M
