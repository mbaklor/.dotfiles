local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local sep = "/"
if wezterm.target_triple:find("windows") ~= nil then
    sep = "\\"
end

local rootPath = wezterm.home_dir .. "/development"

M.toggle_dev = function(window, pane)
    local projects = {}

    local success, stdout, stderr = wezterm.run_child_process({
        "fd",
        "-t",
        "d",
        "-d",
        "1",
        "-u",
        ".",
        rootPath,
        rootPath .. "/alerts-server"
        -- add more paths here
    })

    if not success then
        wezterm.log_error("Failed to run fd: " .. stderr)
        return
    end

    for line in stdout:gmatch("([^\n]*)\n?") do
        local project = line:gsub(sep .. "$", "")
        local label = project
        local id = project:gsub(".*" .. sep, "")
        table.insert(projects, { label = tostring(label), id = tostring(id) })
    end

    window:perform_action(
        act.InputSelector({
            action = wezterm.action_callback(function(win, _, id, label)
                if not id and not label then
                    wezterm.log_info("Cancelled")
                else
                    wezterm.log_info("Selected " .. label)
                    win:perform_action(
                        act.SwitchToWorkspace({ name = id, spawn = { cwd = label } }),
                        pane
                    )
                end
            end),
            fuzzy = true,
            title = "Select project",
            choices = projects,
        }),
        pane
    )
end

return M
