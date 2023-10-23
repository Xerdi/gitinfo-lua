-- TODO: Expose simple macro's using token.set_macro (10.6.4)
-- TODO: always return tuple result, error

if not modules then
    modules = {}
end

local module = {
    name = 'git-latex',
    info = {
        version = 0.001,
        comment = "Git LaTeX — Git integration with LaTeX",
        author = "Erik Nijenhuis",
        license = "gplv3"
    },
    actions = {}
}

modules[module.name] = module.info

local api = {
    cur_tok = nil,
    cmd = require('git-cmd'),
    escape_chars = {
        ['&'] = '\\&',
        ['%%'] = '\\%',
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

local function trim(s)
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

-- Direct actions
register_command_action('version', 'git describe --tags --always')
register_command_action('author', 'git config user.name')
register_command_action('email', 'git config user.email')
register_command_action('commit_date', 'git log -1 --date=format:"%Y/%m/%d" --format="%ad"')

-- Multiple author actions
register_cached_command('authors_alpha', 'git shortlog -s HEAD')
register_cached_command('authors_alpha_with_emails', 'git shortlog -se HEAD')
register_cached_command('authors_contrib', 'git shortlog -sn HEAD')
register_cached_command('authors_contrib_with_emails', 'git shortlog -sne HEAD')

-- Changelog actions
register_cached_command('first_commit', 'git rev-list --max-parents=0 HEAD')
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

mk_action('for_author', function(csname, conj, append_email, sort)
    local _sort = sort or 'contrib'
    local cmd = 'authors_' .. _sort
    if append_email then
        cmd = cmd .. '_with_emails'
    end
    local data = cmds[cmd]()
    if data then
        if data:sub(-1) ~= '\n' then
            data = data .. '\n'
        end
        local authors = {}
        -- Convert to LaTeX lines into table authors
        for line in data:gmatch("(.-)\n") do
            if line then
                if append_email then
                    local author, email = line:match("^%s-%d+%s-(.-)<(.-)>%s-$")
                    if author and email then
                        table.insert(authors, '\\' .. csname .. '{' .. author .. '}{' .. email .. '}')
                    end
                else
                    local author = line:match("^%s-%d+%s+(.-)%s-$")
                    if author then
                        table.insert(authors, '\\' .. csname .. '{' .. author .. '}')
                    end
                end
            end
        end
        -- print to LaTeX with conjunctions
        local len = #authors
        local buffer = authors[1]
        for i = 2, len do
            buffer = buffer .. conj .. authors[i]
        end
        tex.print(buffer)
    else
        texio.write_nl('No response')
    end
end, false)


function api:escape_str(value)
    local buf = string.gsub(value, '\\', '\\textbackslash')
    for search, replace in pairs(self.escape_chars) do
        buf = string.gsub(buf, search, replace)
    end
    return buf
end

local commit_format = '{%h}{%an}{%ae}{%as}{%s}{%b}'

-- todo make method
function api.commit(csname, rev)
    local cmd = 'git log --pretty=format:"\\' .. csname .. commit_format .. '" ' .. rev
    return cmdline(cmd)
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

function api:test(csname, opts)
    print('CSNAME', csname)
    print('OPTS', opts)
    if csname == '' then
        local tok = self:get_tok()
        print('TRY', tok.cmdname)
    end
    --local opts = self:parse_opts()
    --print('OPTS', opts)
    --local tok = self:get_tok()
    --local csname
    --local macro
    --if tok.cmdname == 'left_brace' then
    --    csname = self:parse_arguments(1)
    --    print('CSNAME', csname)
    --else
    --    macro = self:parse_macro()
    --    print('MACRO', macro and 'true' or 'false')
    --end
    --local macro, csname, opts
    --local content_toks = {}
    --local first_tok = token.get_next();
    --if first_tok.cmdname == 'left_brace' then
    --    token.put_next(first_tok)
    --    csname = token.scan_string()
    --    print('CSNAME', csname)
    --elseif first_tok.cmdname == 'other_char' then
    --    token.put_next(first_tok)
    --    opts = token.scan_string()
    --    print('OPTS', opts)
    --else
    --    print('Unknown token', first_tok.cmdname)
    --end

    --print('TOKEN ' .. (first_tok.cmdname or 'nil'), (first_tok.mode or 'nil'))
    --token.put_next(first_tok)
    --print('STRING ' .. (token.scan_word() or 'nil'))
    --print('CS_NAME ' .. (token.scan_csname() or 'nil'))
    --print('STRING ' .. token.scan_word() or 'nil')

    --print('STRING ' .. (token.scan_string() or 'nil'))
    --local toks = token.scan_toks()
    --for _, tok in ipairs(toks) do
    --    print('TOK ' .. (tok.cmdname or 'nil') .. ' | ' .. (tok.command or 'nil'))
    --end
    --local list = token.scan_list()
    --print('LIST: ' .. type(list))
    --local tok = token.get_next()
    --texio.write_nl('attrs ' .. type(tok) .. ' ' .. (tok.cmdname or 'nil'))
    --token = token.get_next()
    --texio.write_nl('attrs ' .. type(tok) .. ' ' .. (tok.cmdname or 'nil'))
end

function api:for_commit(csname, revspec, format)
    if token.is_defined(csname) then
        local tok = token.create(csname)
        local log = self.cmd:log(format, revspec)
        for _, commit in ipairs(log) do
            tex.print(tok)
            for _, value in ipairs(commit) do
                texio.write_nl('value')
                texio.write_nl(self:escape_str(value))
                tex.print('{' .. self:escape_str(value) .. '}')
            end
        end
    else
        tex.error('ERROR: \\' .. csname .. ' not defined')
        return
    end
end
--mk_action('for_commit', for_commit, true)

local tag_format = '{%(refname:short)}%(if)%(taggername)%(then){%(taggername)}{%(taggeremail)}{%(taggerdate:short)}%(else){%(authorname)}{%(authoremail)}{%(authordate:short)}%(end){%(subject)}{%(body)}'

local function for_tag(csname)
    local name = 'tag_' .. csname
    local cmd = 'git for-each-ref --format="\\' .. csname .. tag_format .. '" --sort=-authordate refs/tags'
    register_cached_command(name, cmd)
    return cmds[name]() or ''
end

api.for_tag = for_tag
--mk_action('for_tag', for_tag, true)

mk_action('for_tag_and_commit', function(csname_tag, csname_commit, after_commits)
    local sequence = {}
    local tags_result = for_tag(csname_tag)
    local first_commit = cmds.first_commit()
    local tag_list = cmds.tag_list() .. first_commit
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
        local commits = for_commit(csname_commit, revspec)
        for commit_line in commits:gmatch('\\[^{}]-{[^{}]-}{[^{}]-}{[^{}]-}{[^{}]-}{[^{}]-}{[^{}]-}') do
            tex.print(commit_line)
        end
        -- Add the very last commit
        if i == #sequence then
            local last = commit(csname_commit, first_commit)
            tex.print(last)
        end
        -- After every batch of commits
        if after_commits then
            tex.print(after_commits)
        end
        cur_rev = sequence[i]
    end
end, false)

mk_action('directory', function(dir)
    cache = {}
    directory = dir
end, false)

return git_latex
