-- Global texconfig should already be available when executed with lualtex
local texconfig = texconfig or require('texconfig')

-- Use restricted shell_escape with git as only command
texconfig.shell_escape = 'p'
texconfig.shell_escape_commands = 'git'
