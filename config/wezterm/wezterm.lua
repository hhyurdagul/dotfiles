-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- or, changing the font size and color scheme.
config.font_size = 14
config.color_scheme = 'Catppuccin Mocha'

config.font = wezterm.font('DroidSansM Nerd Font', { weight = 'Bold' })

config.keys = {
    {
        key = 'r',
        mods = 'CMD|SHIFT',
        action = wezterm.action.ReloadConfiguration,
    },
}



-- Finally, return the configuration to wezterm:
return config
