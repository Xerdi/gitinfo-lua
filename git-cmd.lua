-- Part of git-latex

local api = {
    cwd = nil,
    executable = 'git',
    default_sort = '',
    attribute_separator = '\\pop',
    record_separator = '\\end'
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

function api:exec(command, do_caching, target_dir)
    local cmd = self.executable .. ' ' .. command
    local cwd = target_dir or self.cwd
    if cwd then
        cmd = 'cd ' .. cwd .. ';' .. cmd
    end
    if do_caching then
        local found, result = cache:seek(cmd)
        if found then
            return result
        end
    end
    local f = io.popen(cmd)
    if f == nil then
        return nil, "Couldn't execute git command.\n\tIs option '-shell-escape' turned on?"
    end
    local s = f:read('*a')
    if f:close() then
        if do_caching then
            cache[cmd] = s
        end
        return s
    else
        return nil, 'Error executing git command'
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

function api:format_attribute(attribute, no_separator)
    if string.find(attribute, '%w:%w') then
        attribute = '%(' .. attribute .. ')'
    else
        attribute = '%' .. attribute
    end
    if not no_separator then
        attribute = attribute .. self.attribute_separator
    end
    return attribute
end

function api:_parse_format_spec(spec, idx)
    local format = ''
    local above_limit = #spec + 1
    while idx and idx < #spec do
        local attr_idx, attr_size, attr = string.find(spec, '([a-z:]+)', idx)
        local if_idx, if_size, if_block, if_then, if_else = string.find(spec, '%((.-)%)%((.-)%)%((.-)%)', idx)
        if if_idx or attr_idx then
            if (if_idx or above_limit) > (attr_idx or above_limit) then
                format = format .. self:format_attribute(attr)
                idx = attr_size and (attr_size + 1)
            else
                local if_token = self:format_attribute(if_block, true)
                local then_result = self:parse_format_spec(if_then, idx)
                local else_result = self:parse_format_spec(if_else, idx)
                format = format .. '%(if)' .. if_token .. '%(then)' .. then_result
                format = format .. '%(else)' .. else_result .. '%(end)'
                idx = if_size and (if_size + 1)
            end
        end
    end
    return format
end

function api:parse_format_spec(spec)
    local format = self:_parse_format_spec(spec, 1)
    return format .. self.record_separator
end

function api:parse_log(buffer)
    local results = {}
    for record_buffer in string.gmatch(buffer, '(.-)' .. self.record_separator) do
        local record = {}
        for attr in string.gmatch(record_buffer, '(.-)' .. self.attribute_separator) do
            table.insert(record, attr)
        end
        table.insert(results, record)
    end
    return results
end

function api:log(format_spec, revision, options, git_dir)
    if type(format_spec) ~= 'string' then
        return nil, 'Pass the attribute format spec separated by "," in a string en enclosed in three parentheses for if statements'
    end
    local format = self:parse_format_spec(format_spec)
    local cmd = 'log --pretty=format:"' .. format .. '"'
    if options then
        for idx, opt in ipairs(options) do
            options[idx] = '--' .. opt
        end
        cmd = cmd .. ' ' .. table.concat(options, ' ')
    end
    if revision and revision ~= '' then
        cmd = cmd .. ' ' .. revision
    end
    local cmd_response, err = self:exec(cmd, true, git_dir)
    if not cmd_response then
        return cmd_response, err
    end
    return self:parse_log(cmd_response)
end

function api:parse_for_each_ref(result, attrs)
    local _, comma_count = string.gsub(attrs, ',', '')
    local parse_string = string.rep('(.-)' .. self.attribute_separator, comma_count + 1) .. self.record_separator
    return string.gmatch(result, parse_string .. '%s-')
end

function api:for_each_ref(format, revision_type, options, git_dir)
    if not format or type(format) then end -- find out splitting characters
    local cmd = 'for-each-ref --pretty=format:"' .. format '"'

end

local git_cmd = {}
local git_cmd_mt = {
    __index = api,
    __newindex = nil
}

setmetatable(git_cmd, git_cmd_mt)

return git_cmd
