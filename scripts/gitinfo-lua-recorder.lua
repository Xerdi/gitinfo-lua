-- gitinfo-lua-recorder.lua
-- Copyright 2024 E. Nijenhuis
--
-- This work may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3c
-- of this license or (at your option) any later version.
-- The latest version of this license is in
-- http://www.latex-project.org/lppl.txt
-- and version 1.3c or later is part of all distributions of LaTeX
-- version 2005/12/01 or later.
--
-- This work has the LPPL maintenance status ‘maintained’.
--
-- The Current Maintainer of this work is E. Nijenhuis.
--
-- This work consists of the files gitinfo-lua.sty gitinfo-lua.pdf
-- gitinfo-lua-cmd.lua, gitinfo-lua-recorder.lua and gitinfo-lua.lua

local kpse = kpse or require('kpse')
local texio = texio or require('texio')

local api = {
    record_list = {}
}

---record_head
---Records .git/HEAD and .git/refs/heads/<branch> respectively,
---in order to trigger a rebuild in LaTeX.
---@param git_directory string
function api.record_head(git_directory)
    local head_path = '.git/HEAD'
    if git_directory then
        head_path = git_directory .. '/' .. head_path
    end
    if not api.record_list[head_path] then
        api.record_list[head_path] = true
        if kpse.in_name_ok(head_path) then
            local head_file = io.open(head_path, 'rb')
            if not head_file then
                texio.write_nl('Warning: couldn\'t read HEAD from git project directory')
                return
            end
            kpse.record_input_file(head_path)
            texio.write_nl('Info: recording input file ' .. head_path)
            local head_info = head_file:read('*a')
            head_file:close()
            local i, j = string.find(head_info, '^ref: .+\n$')
            if i and j then
                local ref_path = string.sub(head_info, i + 5, j-1)
                if not ref_path then
                    texio.write_nl('Warning: couldn\'t find ref of HEAD')
                    return
                end
                ref_path = '.git/' .. ref_path
                if git_directory then
                    ref_path = git_directory .. '/' .. ref_path
                end
                if kpse.in_name_ok(ref_path) then
                    kpse.record_input_file(ref_path)
                    texio.write_nl('Info: recording input file ' .. ref_path)
                else
                    texio.write_nl('Warning: couldn\'t read ref file: ' .. ref_path)
                end
            else
                texio.write_nl('Warning: didn\'t find any ref in .git/HEAD')
            end
        else
            texio.write_nl('Couldn\'t open input file ' .. head_path)
        end
    end
end



local gitinfo_recorder = {}
local gitinfo_recorder_mt = {
    __index = api,
    __newindex = nil
}

setmetatable(gitinfo_recorder, gitinfo_recorder_mt)

return gitinfo_recorder
