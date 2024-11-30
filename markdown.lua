local markdown = {}
local function begin_meta(file)
    local meta = {}
    local line = file:read("*l")
    while line:sub(1, 3) ~= '---' do
        local st, en = line:find(':')
        local name = line:sub(1, st-1)
        meta[name] = line:sub(en+1)
        if meta[name] == '' then
            print(name)
        end
        line = file:read("*l")
    end
    return meta
end

--- @return string, integer
local function write_tag(line, symbol, tagname, s, e)
    local symlen = symbol:len()
    local str = '<' .. tagname .. '>'
    local find = string.find(line, symbol, s+symlen, true)
    local ss = 0
    ss = line:find(symbol, s+symlen, true)
    str = str .. line:sub(s+symlen, ss-1)
    str = str .. '</' .. tagname .. '>'
    if string.sub(line, ss+symlen, ss+symlen) == ' ' then
        str = str .. ' '
    end
    return str, ss
end

local function create_block(line, symbol, blocktype, s, e)
    local symlen = symbol:len()
    local block = {}
    block.type = blocktype
    local ss = line:find(symbol, s+symlen, true)
    block.value = line:sub(s+symlen, ss-1)
    return block, ss
end

local function process_string(md)
    if md.line == "" then return end
    local content = {}
    local str = md.line
    local s, e = string.find(str, '%S+')
    while s do
        if str:sub(s, s) == '(' then
            local block = {}
            block.type = 'text'
            block.value = '('
            table.insert(content, block)
            s = s + 1
        end
        if str:sub(s, s) == '`' then
            local v = {create_block(str, '`', 'code', s, e)}
            table.insert(content, v[1])
            e = v[2]+1
        elseif str:sub(s, s+1) == '**' then
            print('b', str:sub(s, e))
            local v = {create_block(str, '**', 'bold', s, e)}
            table.insert(content, v[1])
            print(v[1], v[2])
            e = v[2]+2
        elseif str:sub(s, s+1) == '__' then
            local v = {create_block(str, '__', 'bold', s, e)}
            table.insert(content, v[1])
            e = v[2]+2
        elseif str:sub(s, s) == '*' then
            print('i', str:sub(s, e))
            local v = {create_block(str, '*', 'italic', s, e)}
            table.insert(content, v[1])
            e = v[2]+1
        elseif str:sub(s, s) == '[' then
            local name = str:match('[^%]]+', s+1)
            local link = str:match('[^%)]+', s+3+name:len())
            local block = {}
            block.type = 'link'
            block.value = name
            block.href = link
            table.insert(content, block)
            e = s+4+name:len()+link:len()
        else
            local block = {}
            block.type = 'text'
            block.value = str:sub(s, e+1)
            table.insert(content, block)
            e = e + 2
        end
        s, e = string.find(str, '%S+', e)
    end
    return content
end

local function begin_list(md)
    local line = md.line
    local file = md.file
    local block = {}
    block.type = 'list'
    local is_list = true
    block.value = {}
    while is_list do
        local s, e = line:find('- ')
        md.line = line:sub(s + 1)
        table.insert(block.value, process_string(md))
        line = file:read("*l")
        is_list = string.match(line, '%s?- ')
    end
    return block
end

local function begin_code(md)
    local line = md.line
    local lang = string.match(line, '%w+')
    local file = md.file
    local block = {}
    block.type = 'multi code'
    block.lang = lang
    block.value = {}
    local code = file:read("*l")
    local aux = '<pre>'
    aux = aux .. '<code'
    if lang then
        aux = aux .. ' class="' .. lang .. '"'
    end
    aux = aux .. '>'
    while string.sub(code, 1, 3) ~= '```' do
        table.insert(block.value, code)
        aux = aux .. code .. '\\n'
        code = file:read("*l")
    end
    aux = aux .. '</code>n'
    aux = aux .. '</pre>\\n'
    return block
end


local function begin_paragraph(md)
    if md.line == "" then
        return {type = 'breakline'}
    end
    local block = {}
    block.type = 'paragraph'
    block.value = process_string(md)
    return block
end

markdown.decode = function(filename)
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
    md.line = fp:read("*l")
    md.content = {}
    while md.line do
        if md.line:sub(1, 1) == '-' then
            table.insert(md.content, begin_list(md))
        elseif md.line:sub(1, 3) == '```' then
            table.insert(md.content, begin_code(md))
        elseif md.line:sub(1, 1) == '!' then
            local block = {}
            block.type = 'image'
            local str = md.line:match('[^%]]+', 3)
            local link = md.line:match('[^%)]+', 5+str:len())
            block.alt = str
            block.src = link
            table.insert(md.content, block)
        else
            table.insert(md.content, begin_paragraph(md))
        end
        md.line = fp:read("*l")
    end
    fp:close()
    md.line = nil
    md.file = nil
    return md
end
return markdown
