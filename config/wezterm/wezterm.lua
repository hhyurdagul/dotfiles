-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Font configuration
config.font_size = 14
config.font = wezterm.font('DroidSansM Nerd Font', { weight = 'Bold' })
-- Enable font ligatures (if your font supports them)
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

-- Color and appearance
config.color_scheme = 'Catppuccin Mocha'
config.window_background_opacity = 0.85
config.window_decorations = "RESIZE"

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false

-- Cursor
config.default_cursor_style = 'SteadyBlock'

-- Other settings
config.enable_scroll_bar = false
config.audible_bell = "Disabled"

wezterm.on('gui-startup', function(cmd)
    local _, _, window = wezterm.mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

-- Keybindings
config.keys = {
    -- Reload configuration
    {
        key = 'r',
        mods = 'CMD|SHIFT',
        action = wezterm.action.ReloadConfiguration,
    },

    -- ToggleFullScreen
    {
        key = 'n',
        mods = 'CMD|SHIFT',
        action = wezterm.action.ToggleFullScreen,
    },

    -- Pane management
    {
        key = '"',
        mods = 'CMD',
        action = wezterm.action_callback(function(window, _)
            local panes = window:active_tab():panes()
            local last_pane = panes[#panes]
            local direction = #panes % 2 == 1 and 'Right' or 'Bottom'
            last_pane:split { direction = direction }
        end
        )
    },
    {
        key = 'f',
        mods = 'CMD|SHIFT',
        action = wezterm.action.TogglePaneZoomState,
    },
    {
        key = 'h',
        mods = 'CMD',
        action = wezterm.action.ActivatePaneDirection 'Left',
    },
    {
        key = 'l',
        mods = 'CMD',
        action = wezterm.action.ActivatePaneDirection 'Right',
    },
    {
        key = 'k',
        mods = 'CMD',
        action = wezterm.action.ActivatePaneDirection 'Up',
    },
    {
        key = 'j',
        mods = 'CMD',
        action = wezterm.action.ActivatePaneDirection 'Down',
    },
    -- Tab management
    {
        key = 'w',
        mods = 'CMD',
        action = wezterm.action.CloseCurrentTab { confirm = true },
    },
    { key = 'd', mods = 'CTRL|SHIFT', action = wezterm.action.ShowDebugOverlay },

}

-- Finally, return the configuration to wezterm:
return config
