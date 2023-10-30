
if not modules then
    modules = {}
end

local module = {
    name = 'git-latex',
    info = {
        version = 0.001,
        comment = "Git LaTeX — Git integration with LaTeX",
        author = "Erik Nijenhuis",
        license = "free"
    },
    actions = {}
}

modules[module.name] = module.info

local api = {
    cur_tok = nil,
    cmd = require('git-cmd'),
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
local git_latex = {}
setmetatable(git_latex, mt)

local cache = {}
local cmds = {}
local directory

local function trim(s) -- deprecated
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function api.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function cmdline(cmd)
    -- deprecated
    local _cmd = string.gsub(cmd, 'git ', '')
    return api.cmd:exec(_cmd)
end

local function mk_action(name, func, output)
    local function _call_action(...)
        if output then
            tex.sprint(trim(func(...)))
        else
            func(...)
        end
    end
    api[name] = _call_action
end
local function register_cached_command(name, command)
    if not cache[command] then
        local function _call_cached_command()
            cache[command] = cache[command] or cmdline(command)
            return cache[command]
        end
        cmds[name] = _call_cached_command
    end
end
local function register_command_action(action, command)
    register_cached_command(action, command)
    mk_action(action, cmds[action], true)
end

-- Changelog actions
register_command_action('tag_list', 'git tag -l --sort=-v:refname')
register_cached_command('for_tag', 'git for-each-ref --format="{%(refname:short)}{%(taggername)}{%(taggeremail)}{%(taggerdate:short)}{%(subject)}{%(body)}" --sort=-committerdate refs/tags')
register_cached_command('for_commit', 'git log --no-merges --pretty=format:"{%h}{%an}{%ae}{%as}{%s}{%b}"')
register_cached_command('for_commit_tag', 'git for-each-ref --format="{%(refname:short)}{%(authorname)}{%(authoremail)}{%(authordate:shot)}" --sort=-committerdate refs/tags')

-- Custom actions
mk_action('set_date', function()
    local date = cmds.commit_date()
    local _, _, year, month, day = date:find('(%d+)/(%d+)/(%d+)')
    tex.year = tonumber(year)
    tex.month = tonumber(month)
    tex.day = tonumber(day)
end, false)


function api:escape_str(value)
    local buf = string.gsub(value, '\\', '\\textbackslash')
    for search, replace in pairs(self.escape_chars) do
        buf = string.gsub(buf, search, replace)
    end
    return buf
end

function api:get_tok()
    if self.cur_tok == nil then
        self.cur_tok = token.get_next()
    end
    return self.cur_tok
end

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

function api:parse_macro()
    --tex.print('\\noexpand')
    local tok = self:get_tok()
    if (tok.cmdname == 'call') or tok.cmdname == 'long_call' then
        self.cur_tok = nil
        return tok
    else
        print(tok.cmdname)
        tex.error("Expected Macro")
        for i = 1, 5 do
            local _tok = token.get_next()
            print('token', i, _tok.cmdname)
        end
    end
end

function api:dir(path)
    self.cmd.cwd = path
end

function api:version()
    return self.cmd:exec('describe --tags --always', true)
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
function api:is_dirty()
    local ok, _ = self.cmd:exec('describe --tags --exact-match')
    return ok == nil
end
-- todo: add write variant

function api:local_author()
    return self.cmd:exec('config user.name', true)
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
    return self.cmd:exec('config user.email', true)
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

function api:first_revision()
    return self.cmd:exec('git rev-list --max-parents=0 HEAD', true)
end

function api:cs_last_commit(csname, format)
    return self:cs_commit(csname, '-1', format)
end

function api:cs_for_commit(csname, rev_spec, format)
    if token.is_defined(csname) then
        local tok = token.create(csname)
        local log, err = self.cmd:log(format, rev_spec)
        for _, commit in ipairs(log) do
            tex.print(tok)
            for _, value in ipairs(commit) do
                tex.print('{' .. self:escape_str(value) .. '}')
            end
        end
    else
        tex.error('ERROR: \\' .. csname .. ' not defined')
    end
end

local tag_format = '{%(refname:short)}%(if)%(taggername)%(then){%(taggername)}{%(taggeremail)}{%(taggerdate:short)}%(else){%(authorname)}{%(authoremail)}{%(authordate:short)}%(end){%(subject)}{%(body)}'

local function for_tag(csname)
    local name = 'tag_' .. csname
    local cmd = 'git for-each-ref --format="\\' .. csname .. tag_format .. '" --sort=-authordate refs/tags'
    register_cached_command(name, cmd)
    return cmds[name]() or ''
end

api.for_tag = for_tag
--mk_action('for_tag', for_tag, true)

-- formatting one tag with --count=1 (to be tested)
mk_action('for_tag_and_commit', function(csname_tag, csname_commit, after_commits)
    local sequence = {}
    local tags_result = for_tag(csname_tag)
    local first_revision = cmds:first_revision()
    local tag_list = cmds.tag_list() .. first_revision
    for version_tag in tag_list:gmatch("(.-)\n") do
        table.insert(sequence, version_tag)
    end
    local cur_rev = sequence[1]
    for i = 2, #sequence do
        local match = string.match(tags_result, '\\[^{}]-{' .. cur_rev .. '}{[^{}]-}{[^{}]-}{[^{}]-}{[^{}]-}{[^{}]-}')
        if match then
            tex.print(match)
        end
        -- Appending commits
        local revspec = cur_rev .. '...' .. sequence[i]
        local commits = first_revision(csname_commit, revspec)
        for commit_line in commits:gmatch('\\[^{}]-{[^{}]-}{[^{}]-}{[^{}]-}{[^{}]-}{[^{}]-}{[^{}]-}') do
            tex.print(commit_line)
        end
        -- Add the very last commit
        if i == #sequence then
            local last = commit(csname_commit, first_revision)
            tex.print(last)
        end
        -- After every batch of commits
        if after_commits then
            tex.print(after_commits)
        end
        cur_rev = sequence[i]
    end
end, false)

return git_latex
