-- Global texconfig should already be available when executed with lualatex
local texconfig = texconfig or require('texconfig')

-- Use restricted shell_escape with git as only command.
-- Add others where needed, separated with a comma (no spaces in between)
texconfig.shell_escape = 'p'
texconfig.shell_escape_commands = 'git'
