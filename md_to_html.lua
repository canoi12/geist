local function begin_meta(file)
    local meta = {}
    local line = file:read("*l")
    print(line)
    while line:sub(1, 3) ~= '---' do
        local st, en = line:find(':')
        -- print(line, st, en)
        local name = line:sub(1, st-1)
        print(name, line:sub(en+1))
        meta[name] = line:sub(en+1)
        if meta[name] == '' then
            print(name)
        end
        line = file:read("*l")
    end
    print(meta['author'])
    return meta
end

--- @return string, integer
local function write_tag(line, symbol, tagname, s, e)
    local symlen = symbol:len()
    local str = '<' .. tagname .. '>'
    local find = string.find(line, symbol, s+symlen, true)
    print(find)
    print(tagname .. ' block', line:sub(s+symlen, find-1))
    local ss = 0
    ss = line:find(symbol, s+symlen, true)
    -- out:write(line:sub(s+symlen, ss-1))
    str = str .. line:sub(s+symlen, ss-1)
    -- out:write('</' .. tagname .. '>')
    str = str .. '</' .. tagname .. '>'
    if string.sub(line, ss+symlen, ss+symlen) == ' ' then
        str = str .. ' '
    end
    return str, ss
end

local function create_block(line, symbol, blocktype, s, e)
    local block = {}
    block.type = blocktype
    local symlen = symbol:len()
    local find = string.find(line, symbol, s+symlen, true)
    print(find)
    print(blocktype .. ' block', line:sub(s+symlen, find-1))
    local ss = 0
    ss = line:find(symbol, s+symlen, true)
    -- out:write(line:sub(s+symlen, ss-1))
    block.content = line:sub(s+symlen, ss-1)
    -- str = str .. line:sub(s+symlen, ss-1)
    -- out:write('</' .. tagname .. '>')
    -- str = str .. '</' .. tagname .. '>'
    --[[ if string.sub(line, ss+symlen, ss+symlen) == ' ' then
        str = str .. ' '
    end]]
    return block, ss
end

local function process_string(md)
    local content = {}
    if md.line == "" then return end
    local str = md.line
    local s, e = string.find(str, '%S+')
    print('str', str)
    -- print(string.sub(str, s, e), s, e)
    -- print(string.sub(str, s, s))
    local aux = ""
    while s do
        -- print(s)
        if str:sub(s, s) == '`' then
            -- print(str)
            -- local v = {create_block(str, '`', 'code', s, e)}
            local v = {write_tag(str, '`', 'code', s, e)}
            aux = aux .. v[1]
            e = v[2]+1
            -- table.insert(content, v[1])
        elseif str:sub(s, s+1) == '**' then
            print('b', str:sub(s, e))
            local v = {write_tag(str, '**', 'b', s, e)}
            print(v[1], v[2])
            aux = aux .. v[1]
            e = v[2]+2
        elseif str:sub(s, s) == '*' then
            print('i', str:sub(s, e))
            local v = {write_tag(str, '*', 'i', s, e)}
            aux = aux .. v[1]
            e = v[2]+1
        elseif str:sub(s, s) == '[' then
            -- out:write('<a target="__blank" href="')
            aux = aux .. '<a target=\\"__blank\\" href=\\"'
            local name = str:match('[^%]]+', s+1)
            local link = str:match('[^%)]+', s+3+name:len())
            print('link', name, link)
            -- out:write(link .. '">' .. str .. '</a>')
            aux = aux .. link .. '\\">' .. name .. '</a>'
            e = s+4+name:len()+link:len()
        else
            --out:write(str:sub(s, e+1))
            aux = aux .. str:sub(s, e+1)
            e = e + 2
        end
        s, e = string.find(str, '%S+', e)
    end
    return aux
end

local function begin_list(md)
    local line = md.line
    local file = md.file
    print('begin list')
    local aux = '<ul>'
    local is_list = true
    while is_list do
        aux = aux .. "<li>"
        -- local s = line:gsub('%s?- ', '')
        local s, e = line:find('- ')
        -- process_string(line:sub(s + 1), file)
        md.line = line:sub(s + 1)
        process_string(md)
        -- print(s)
        -- out:write(s)
        aux = aux .. '</li>'
        line = file:read("*l")
        is_list = string.match(line, '%s?- ')
        -- print(line)
    end
    aux = aux .. '</ul>'
    return aux
end

local function begin_code(md)
    local line = md.line
    local lang = string.match(line, '%w+')
    local file = md.file

    local code = file:read("*l")
    local aux = '<pre>'
    aux = aux .. '<code'
    if lang then
        aux = aux .. ' class=\\"' .. lang .. '\\"'
    end
    aux = aux .. '>'
    while string.sub(code, 1, 3) ~= '```' do
        -- final = final .. code .. '\n'
        aux = aux .. code .. '\\n'
        code = file:read("*l")
    end
    aux = aux .. '</code>'
    aux = aux .. '</pre>'
    return aux
end


local function begin_paragraph(md)
    print('begin paragraph')
    if md.line == "" then
        return '<br/>'
    end
    local line = md.line
    local aux = ""
    local s, e = string.find(line, '%S+')

    -- print(s, e, line:sub(s, e))
    
    aux = aux .. '<p>'
    aux = aux .. process_string(md)
    aux = aux .. '</p>'
    return aux
end

return function(filename)
    local md = {}
    local fp = io.open(filename, 'r')
    if not fp then
        print('failed to open ' .. filename)
        return
    end
    local line = fp:read("*l")
    md.line = line
    md.file = fp
    local m = line:sub(1, 3) == '---'
    if m then
        md.meta = begin_meta(fp)
    end
    print(line, fp)
    local aux = ""
    md.line = fp:read("*l")
    md.content = {}
    while md.line do
        if md.line:sub(1, 1) == '-' then
            -- aux = aux .. begin_list(md)
            table.insert(md.content, begin_list(md))
        elseif md.line:sub(1, 3) == '```' then
            -- aux = aux .. begin_code(md)
            table.insert(md.content, begin_code(md))
        elseif md.line:sub(1, 1) == '!' then
            local a = '<img alt=\\"'
            local str = md.line:match('[^%]]+', 3)
            local link = md.line:match('[^%)]+', 5+str:len())
            print('image', str, link)
            a = a .. str .. '\\" src=\\"' .. link .. '\\"/>'
            a = a .. line:sub(6+str:len()+link:len())
            table.insert(md.content, a)
        else
            -- aux = aux .. begin_paragraph(md)
            table.insert(md.content, begin_paragraph(md))
        end
        md.line = fp:read("*l")
    end
    --md.content = aux
    fp:close()
    md.line = nil
    md.file = nil
    return md
end
