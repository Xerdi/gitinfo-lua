-- gitinfo-lua-cmd.lua
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

local api = {
    cwd = nil,
    executable = 'git',
    default_sort = '',
    attribute_separator = '\\pop',
    record_separator = '\\end',
    recorder = require('gitinfo-lua-recorder')
}
local cache = {}
function cache:seek(_key)
    for key, value in pairs(self) do
        if key == _key then
            return true, value
        end
    end
    return false, nil
end

function api.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function api:exec(command, do_caching, target_dir, no_recording, path_spec)
    local cwd = target_dir or self.cwd
    local cmd = self.executable
    if cwd then
        cmd = cmd .. ' -C ' .. cwd
    end
    cmd = cmd .. ' ' .. command
    if not no_recording then
        api.recorder.record_head(cwd)
    end
    if path_spec then
    	if type(path_spec) == 'table' then
    	    cmd = cmd .. ' --'
    	    for _,path in ipairs(path_spec) do
    	        cmd = cmd .. ' ' .. path
    	    end
        elseif type(path_spec) == 'string' then
            cmd = cmd .. ' -- ' .. path_spec
    	end
    end
    if do_caching then
        local found, result = cache:seek(cmd)
        if found then
            return result
        end
    end
    local f = io.popen(cmd)
    if f == nil then
        return nil, "Couldn't execute git command.\n\tIs option '--shell-escape' turned on?"
    end
    local s = f:read('*a')
    if f:close() then
        if do_caching then
            cache[cmd] = s
        end
        return s
    else
        return nil, 'Error executing git command\n\t"' .. cmd .. '"'
    end
end

function api:shortlog(sort_by_contrib, include_email, target_dir)
    local cmd = 'shortlog -s'
    if sort_by_contrib then
        cmd = cmd .. 'n'
    end
    if include_email then
        cmd = cmd .. 'e'
    end
    cmd = cmd .. ' HEAD'
    return self:exec(cmd, true, target_dir)
end

function api:parse_opts(options)
    if options then
        for idx, opt in ipairs(options) do
            options[idx] = '--' .. opt
        end
        return table.concat(options, ' ')
    end
end

function api:format_attribute(attribute, no_separator, with_parenthesis)
    if with_parenthesis then
        attribute = '%(' .. attribute .. ')'
    else
        attribute = '%' .. attribute
    end
    if not no_separator then
        attribute = attribute .. self.attribute_separator
    end
    return attribute
end

function api:_parse_format_spec(spec, idx, with_parenthesis)
    local format = ''
    local above_limit = #spec + 1
    while idx and idx <= #spec do
        local attr_idx, attr_size, attr = string.find(spec, '([a-z:]+)', idx)
        local if_idx, if_size, if_block, if_then, if_else = string.find(spec, '%((.-)%)%((.-)%)%((.-)%)', idx)
        if if_idx or attr_idx then
            if (if_idx or above_limit) > (attr_idx or above_limit) then
                format = format .. self:format_attribute(attr, false, with_parenthesis)
                idx = attr_size and (attr_size + 1)
            else
                local if_token = self:format_attribute(if_block, true, with_parenthesis)
                local then_result = self:_parse_format_spec(if_then, idx, with_parenthesis)
                local else_result = self:_parse_format_spec(if_else, idx, with_parenthesis)
                format = format .. '%(if)' .. if_token .. '%(then)' .. then_result
                format = format .. '%(else)' .. else_result .. '%(end)'
                idx = if_size and (if_size + 1)
            end
        end
    end
    return format
end

function api:parse_format_spec(spec, with_parenthesis)
    if type(spec) ~= 'string' then
        return nil, 'Pass the attribute format spec separated by "," in a string en enclosed in three parentheses for if statements'
    end
    local format = self:_parse_format_spec(spec, 1, with_parenthesis)
    return format .. self.record_separator
end

function api:parse_response(buffer)
    local results = {}
    for record_buffer in string.gmatch(buffer, '(.-)' .. self.record_separator) do
        local record = {}
        for attr in string.gmatch(record_buffer, '(.-)' .. self.attribute_separator) do
            table.insert(record, self.trim(attr))
        end
        table.insert(results, record)
    end
    return results
end

function api:log(format_spec, revision, options, target_dir, path_spec)
    local format, err = self:parse_format_spec(format_spec)
    if err then
        return nil, err
    end
    local cmd = 'log --pretty=format:"' .. format .. '"'
    local opts = self:parse_opts(options)
    if opts then
        cmd = cmd .. ' ' .. opts
    end
    if revision and revision ~= '' then
        cmd = cmd .. ' ' .. revision
    end
    local response, err = self:exec(cmd, true, target_dir, false, path_spec)
    if not response then
        return nil, err
    end
    return self:parse_response(response)
end

function api:for_each_ref(format_spec, revision_type, options, target_dir)
    local err, format, response
    format, err = self:parse_format_spec(format_spec, true)
    if err then return nil, err end
    local cmd = 'for-each-ref --format="' .. format .. '"'
    local opts = self:parse_opts(options)
    if opts then
        cmd = cmd .. ' ' .. opts
    end
    cmd = cmd .. ' ' .. revision_type
    response, err = self:exec(cmd, true, target_dir)
    if err then return nil, err end
    return self:parse_response(response)
end

local gitinfo_cmd = {}
local gitinfo_cmd_mt = {
    __index = api,
    __newindex = nil
}

setmetatable(gitinfo_cmd, gitinfo_cmd_mt)

return gitinfo_cmd
