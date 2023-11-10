-- gitinfo-lua.lua
-- Copyright 2023 E. Nijenhuis
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
-- gitinfo-cmd.lua and gitinfo-lua.lua

if not modules then
    modules = {}
end

local module = {
    name = 'gitinfo-lua',
    info = {
        version = 1.0,
        comment = "Git info Lua — Git integration with LaTeX",
        author = "Erik Nijenhuis",
        license = "free"
    }
}

modules[module.name] = module.info

local api = {
    cur_tok = nil,
    cmd = require('gitinfo-lua-cmd'),
    escape_chars = {
        ['&'] = '\\&',
        ['%%'] = '\\%%',
        ['%$'] = '\\$',
        ['#'] = '\\#',
        ['_'] = '\\_',
        ['{'] = '\\{',
        ['}'] = '\\}',
        ['~'] = '\\textasciitilde',
        ['%^'] = '\\textasciicircum'
    }
}
local mt = {
    __index = api,
    __newindex = nil
}
local gitinfo = {}
setmetatable(gitinfo, mt)

function api.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function api:set_date()
    local date, err = self.cmd:log('cs', '-1', {'max-count=1'})
    if date and #date == 1 then
        local _, _, year, month, day = date[1][1]:find('(%d+)[-/](%d+)[-/](%d+)')
        tex.year = tonumber(year)
        tex.month = tonumber(month)
        tex.day = tonumber(day)
    else
        return nil, (err or 'Length of output doesn\'t match one (attempt to set git date)')
    end
end

function api:escape_str(value)
    local buf = string.gsub(value, '\\', '\\textbackslash')
    for search, replace in pairs(self.escape_chars) do
        buf = string.gsub(buf, search, replace)
    end
    return buf
end

-- experimental
function api:get_tok()
    if self.cur_tok == nil then
        self.cur_tok = token.get_next()
    end
    return self.cur_tok
end

-- experimental
function api:parse_opts()
    local tok = self:get_tok()
    if tok.cmdname == 'other_char' then
        --token.put_next(tok)
        local opts = token.scan_word()
        self.cur_tok = nil
        -- todo: parse []
        return opts
    end
end

-- experimental
function api:parse_arguments(argc)
    local result_list = {}
    for _ = 1, argc do
        local tok = self:get_tok()
        if tok.cmdname == 'left_brace' then
            token.put_next(tok)
            table.insert(result_list, token.scan_argument())
            self.cur_tok = nil
        else
            tex.error("Expected left brace")
            return
        end
    end
    return table.unpack(result_list)
end

-- experimental
function api:parse_macro()
    --tex.print('\\noexpand')
    local tok = self:get_tok()
    if (tok.cmdname == 'call') or tok.cmdname == 'long_call' then
        self.cur_tok = nil
        return tok
    else
        tex.error("Expected Macro")
        for i = 1, 5 do
            local _tok = token.get_next()
        end
    end
end

function api:dir(path)
    self.cmd.cwd = path
end

function api:version()
    return self.trim(self.cmd:exec('describe --tags --always', true))
end

function api:write_version()
    local version, err = self:version()
    if version then
        tex.write(version)
    else
        tex.error(err)
    end
end

-- todo: prevent output to stderr
-- todo: add write variant
-- experimental
function api:is_dirty()
    local ok, _ = self.cmd:exec('describe --tags --exact-match')
    return ok == nil
end

function api:local_author()
    return self.trim(self.cmd:exec('config user.name', true))
end

function api:write_local_author()
    local name, err = self:local_author()
    if name then
        tex.write(name)
    else
        tex.error(err)
    end
end

function api:local_email()
    return self.trim(self.cmd:exec('config user.email', true))
end

function api:write_local_email()
    local name, err = self:local_email()
    if name then
        tex.write(name)
    else
        tex.error(err)
    end
end

function api:authors(sort_by_contrib)
    local authors, err = self.cmd:shortlog(sort_by_contrib, true)
    if authors then
        local author_list = {}
        for line in authors:gmatch('(.-)\n') do
            local contributions, name, email = line:match("^%s-(%d+)%s-(.-)%s-<(.-)>%s-$")
            table.insert(author_list, {
                contributions = contributions,
                name = name,
                email = email
            })
        end
        return author_list
    else
        return nil, err
    end
end

function api:cs_for_authors(csname, conjunction, sort_by_contrib)
    if token.is_defined(csname) then
        local tok = token.create(csname)
        local authors, err = self:authors(sort_by_contrib)
        if authors then
            local next_conj
            for _, author in ipairs(authors) do
                if next_conj then
                    tex.print(next_conj)
                end
                next_conj = conjunction
                tex.print(tok, '{' .. self:escape_str(self.trim(author.name)) .. '}', '{' .. self:escape_str(self.trim(author.email)) .. '}')
            end
        else
            tex.error(err)
        end
    else
        tex.error('ERROR: \\' .. csname .. ' not defined')
    end
end

function api:cs_commit(csname, rev, format)
    if token.is_defined(csname) then
        local tok = token.create(csname)
        local log, err = self.cmd:log(format, rev, {'max-count=1'})
        if log then
            if #log == 1 then
                tex.print(tok)
                for _, value in ipairs(log[1]) do
                    tex.print('{' .. self:escape_str(value) .. '}')
                end
            else
                texio.write_nl('Warning: commit returned none')
            end
        else
            tex.error('ERROR: ' .. (err or 'nil'))
        end
    else
        tex.error('ERROR: \\' .. csname .. ' not defined')
    end
end

function api:cs_last_commit(csname, format)
    return self:cs_commit(csname, '-1', format)
end

function api:cs_for_commit(csname, rev_spec, format)
    if token.is_defined(csname) then
        local tok = token.create(csname)
        local log, err = self.cmd:log(format, rev_spec)
        if log then
            for _, commit in ipairs(log) do
                tex.print(tok)
                for _, value in ipairs(commit) do
                    tex.print('{' .. self:escape_str(value) .. '}')
                end
            end
        else
            tex.error('ERROR:\\' .. err)
        end
    else
        tex.error('ERROR: \\' .. csname .. ' not defined')
    end
end

function api:tag_info(format_spec, tag, target_dir)
    local err, info
    info, err = self.cmd:for_each_ref(format_spec, 'refs/tags', {'count=1', 'contains=' .. tag}, target_dir)
    if info and #info == 1 then
        return info[1]
    else
        tex.error(err or 'Result count didn\'t match. (in tag_info)')
    end
end

function api:tags(target_dir)
    local tag_list = {}
    local tags, err = self.cmd:exec('tag -l --sort=-v:refname', true, target_dir)
    if tags then
        for tag in tags:gmatch('(.-)\n') do
            table.insert(tag_list, self.trim(tag))
        end
    else
        return nil, err
    end
    return tag_list
end

function api:cs_tag(csname, format_spec, tag, target_dir)
    if token.is_defined(csname) then
        local tok = token.create(csname)
        local info = self:tag_info(format_spec, tag, target_dir)
        if info then
            tex.print(tok)
            for _, value in ipairs(info) do
                tex.print('{' .. self:escape_str(value) .. '}')
            end
        end
    else
        tex.error('ERROR:\\' .. csname .. ' not defined')
    end
end

function api:cs_for_tag(csname, format_spec, target_dir)
    if token.is_defined(csname) then
        local tok = token.create(csname)
        local tags, err = self.cmd:for_each_ref(format_spec, 'refs/tags', {'sort=-authordate'}, target_dir)
        if tags then
            for _, info in ipairs(tags) do
                tex.print(tok)
                for _, value in ipairs(info) do
                    tex.print('{' .. self:escape_str(value) .. '}')
                end
            end
        else
            tex.error('ERROR:\\' .. err)
        end
    else
        tex.error('ERROR:\\' .. csname .. ' not defined')
    end
end

function api:cs_for_tag_sequence(csname, target_dir)
    if token.is_defined(csname) then
        local tok = token.create(csname)
        local seq, err = self:tags(target_dir)
        if seq then
            for idx, tag in ipairs(seq) do
                if idx < #seq then
                    local next = seq[idx + 1]
                    tex.print(tok, '{' .. tag .. '}{' .. next .. '}{' .. tag .. '...' .. next .. '}')
                else
                    tex.print(tok, '{' .. tag .. '}{}{' .. tag .. '}')
                end
            end
        else
            tex.error('ERROR:\\' .. (err or 'Unknown error'))
        end
    else
        tex.error('ERROR:\\' .. csname .. ' not defined')
    end
end

return gitinfo
