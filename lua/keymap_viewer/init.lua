local M = {}

-- Function to get all key mappings for a specific leader key
function M.get_leader_keymaps()
    -- Get the current leader key
    local leader = vim.g.mapleader or '\\'

    -- Collect keymaps
    local keymaps = {}

    -- Check all modes: normal, insert, visual, etc.
    local modes = {'n', 'i', 'v', 'x', 't', 'c'}

    for _, mode in ipairs(modes) do
        local mode_keymaps = vim.api.nvim_get_keymap(mode)

        for _, keymap in ipairs(mode_keymaps) do
            -- Check if the keymap starts with the leader key
            if keymap.lhs:sub(1, #leader) == leader then
                table.insert(keymaps, {
                    mode = mode,
                    lhs = keymap.lhs,
                    rhs = keymap.rhs or '',
                    desc = keymap.desc or 'No description'
                })
            end
        end
    end

    return keymaps
end

-- Create a buffer and window to display keymaps
function M.open_keymap_viewer()
    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Define buffer options
    vim.api.nvim_set_option_value('buftype', 'nofile', {buf = buf})
    vim.api.nvim_set_option_value('swapfile', false, {buf = buf})
    vim.api.nvim_set_option_value('bufhidden', 'wipe', {buf = buf})

    -- Get leader key mappings
    local keymaps = M.get_leader_keymaps()

    -- Prepare buffer content
    local content = {"Leader Key Mappings:", ""}

    -- Group keymaps by mode
    local grouped_keymaps = {}
    for _, keymap in ipairs(keymaps) do
        if not grouped_keymaps[keymap.mode] then
            grouped_keymaps[keymap.mode] = {}
        end
        table.insert(grouped_keymaps[keymap.mode], keymap)
    end
    
    -- Mode display names
    local mode_names = {
        n = "Normal Mode",
        i = "Insert Mode", 
        v = "Visual Mode",
        x = "Select Mode",
        t = "Terminal Mode",
        c = "Command Mode"
    }

    -- Format and add keymaps to content
    for mode, mode_keymaps in pairs(grouped_keymaps) do
        table.insert(content, mode_names[mode] or mode)
        table.insert(content, string.rep("-", #(mode_names[mode] or mode)))

        for _, keymap in ipairs(mode_keymaps) do
            local line = string.format("%s: %s", keymap.lhs, keymap.desc)
            table.insert(content, line)
        end

        table.insert(content, "")
    end

    -- Set buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    -- Create floating window with modern Neovim API
    local width = vim.o.columns
    local height = vim.o.lines

    -- Window configuration
    local win_width = math.floor(width * 0.8)
    local win_height = math.floor(height * 0.8)

    local win_config = {
        relative = "editor",
        width = win_width,
        height = win_height,
        col = math.floor((width - win_width) / 2),
        row = math.floor((height - win_height) / 2),
        style = "minimal",
        border = "rounded",
        title = " Leader Key Mappings ",
        title_pos = "center"
    }

    -- Create the floating window
    local win = vim.api.nvim_open_win(buf, true, win_config)

    -- Set window-specific highlights
    vim.api.nvim_set_option_value('winhl', 'Normal:Normal,FloatBorder:FloatBorder,Title:Title', {win = win})

    -- Add close mapping
    vim.keymap.set('n', 'q', ':close<CR>', {buffer = buf, noremap = true, silent = true})

    -- Optional: Add syntax highlighting
    vim.api.nvim_buf_call(buf, function()
        vim.cmd([[
            syntax match LeaderKey /^<leader>/ contained
            syntax match KeyMapLine /^.*:/ contains=LeaderKey
            syntax match ModeHeader /^[A-Z].*Mode$/
            
            highlight def link LeaderKey Special
            highlight def link ModeHeader Title
            highlight def link KeyMapLine Normal
        ]])
    end)
end

-- Setup function to create user command
function M.setup()
    vim.api.nvim_create_user_command('LeaderKeymaps', M.open_keymap_viewer, {})
end


return {
    'local/keymap_viewer', -- you can use a local path or create a proper GitHub repo later
    config = function()
        require('plugins.keymap_viewer').setup()
    end,
    keys = {
        { 'n', '<cmd>LeaderKeymaps<cr>', desc = 'Open Leader Keymaps Viewer' }
    }
}

