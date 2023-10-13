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

local mt = {
    __index = module.actions,
    __newindex = nil
}
local api = {}
setmetatable(api, mt)

modules[module.name] = module.info

local cache = {}
local cmds = {}
local directory

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function cmdline(cmd)
    if directory then
        cmd = 'cd ' .. directory .. '; ' .. cmd
    end
    local f = io.popen(cmd)
    if f == nil then
        tex.error("ERROR: Couldn't execute git command.\n\tIs option '-shell-escape' turned on?")
        return ''
    end
    local s = f:read('*a')
    if f:close() then
        return s
    else
        texio.write_nl('Error executing git command')
        return nil
    end
end

local function mk_action(name, func, output)
    local function _call_action(...)
        if output then
            tex.sprint(trim(func(...)))
        else
            func(...)
        end
    end
    module.actions[name] = _call_action
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

mk_action('for_commit', function(csname, revspec)
    local name = 'commit_' .. csname
    local cmd = 'git log --no-merges --pretty=format:"\\' .. csname .. '{%h}{%an}{%ae}{%as}{%s}{%b}"'
    if revspec then
        cmd = cmd .. ' ' .. revspec
    end
    register_cached_command(name, cmd)
    tex.print(cmds[name]() or '')

end, false)

mk_action('directory', function(dir)
    cache = {}
    directory = dir
end, false)

return api
