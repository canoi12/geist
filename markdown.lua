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

local function create_block(line, symbol, blocktype, s)
    local symlen = symbol:len()
    local block = {}
    block.type = blocktype
    local ss = line:find(symbol, s+symlen, true)
    block.value = line:sub(s+symlen, ss-1)
    print(line:sub(s, #line), symlen, symbol)
    return block, ss+symlen
end

local function link_block(str, s)
    local name = str:match('%b[]', s)
    local link = str:match('%b()', s)
    local block = {}
    block.type = 'link'
    block.name = name:sub(2, #name-1)
    block.href = link:sub(2, #link-1)
    local ss = s+4+name:len()+link:len()
    return block, ss
end
local function code_block(str, symbol, s) return create_block(str, symbol, 'code', s) end
local function bold_block(str, symbol, s) return create_block(str, symbol, 'bold', s) end
local function italic_block(str, symbol, s) return create_block(str, symbol, 'italic', s) end
local function italic_bold_block(str, symbol, s) return create_block(str, symbol, 'italic bold', s) end
local function image_block(str, s)
    local name = str:match('%b[]', s)
    local link = str:match('%b()', s)
    local block = {}
    block.type = 'image'
    block.alt = name:sub(2, #name-1)
    block.src = link:sub(2, #link-1)
    local ss = s+4+name:len()+link:len()
    return block, ss
end

local symbols = {
    ['['] = link_block,
    ['`'] = function (str, s) return code_block(str, '`', s) end,
    ['*'] = function (str, s) return italic_block(str, '*', s) end,
    ['_'] = function (str, s) return italic_block(str, '_', s) end,
    ['**'] = function (str, s) return bold_block(str, '**', s) end,
    ['__'] = function (str, s) return bold_block(str, '__', s) end,
    ['!['] = image_block,
    ['***'] = function (str, s) return italic_bold_block(str, '***', s) end
}

local function process_string(md)
    if md.line == "" then return end
    local content = {}
    local str = md.line
    local s, e = string.find(str, '%S+')
    local text = ""
    while s do
        if str:sub(s, s) == '(' then
            local block = {}
            block.type = 'text'
            block.value = '('
            table.insert(content, block)
            s = s + 1
        end
        if string.match(str, '^[%*%`%_%[]', s) then
            local block = {}
            block.type = 'text'
            block.value = text
            table.insert(content, block)
            text = ""
            for i=2,0,-1 do
                local c = str:sub(s, s+i)
                -- print(s, c, symbols[c])
                if symbols[c] then
                    -- print('symbol', c)
                    local res = {symbols[c](str, s)}
                    table.insert(content, res[1])
                    e = res[2]
                    break
                end
            end
        else
            text = text .. str:sub(s, e+1)
            e = e + 2
        end
        --[[
        local c = str:sub(s, s)
        if c == '`' then
            local v = {create_block(str, c, 'code', s, e)}
            table.insert(content, v[1])
            e = v[2]+1
        elseif str:sub(s, s+1) == '**' or str:sub(s, s+1) == '__' then
            print('b', str:sub(s, e))
            local v = {create_block(str, str:sub(s, s+1), 'bold', s, e)}
            table.insert(content, v[1])
            print(v[1], v[2])
            e = v[2]+2
        elseif c == '*' or c == '_' then
            print('i', str:sub(s, e))
            local v = {create_block(str, c, 'italic', s, e)}
            table.insert(content, v[1])
            e = v[2]+1
        elseif c == '[' then]]
            --local name = str:match('[^%]]+', s+1)
            --[[local link = str:match('[^%)]+', s+3+name:len())
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
        end]]
        s, e = string.find(str, '%S+', e)
    end
    if text ~= "" then
        local block = {}
        block.type = 'text'
        block.value = text
        table.insert(content, block)
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
    while string.sub(code, 1, 3) ~= '```' do
        table.insert(block.value, code)
        code = file:read("*l")
    end
    return block
end


local function begin_paragraph(md)
    local block = {}
    block.type = 'paragraph'
    block.value = process_string(md)
    table.insert(md.content, block)
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
            -- local block = {}
            -- block.type = 'image'
            -- local str = md.line:match('[^%]]+', 3)
            -- local link = md.line:match('[^%)]+', 5+str:len())
            -- block.alt = str
            -- block.src = link
            table.insert(md.content, image_block(md.line, 1))
        else
            if md.line == "" then
                table.insert(md.content, {type='breakline'})
            else
                local block = md.content[#md.content]
                if block.type ~= 'paragraph' then
                    begin_paragraph(md)
                else
                    local b = process_string(md)
                    table.insert(block.value, {type='text',value=' '})
                    for _,v in ipairs(b) do
                        table.insert(block.value, v)
                    end
                end
            end
        end
        md.line = fp:read("*l")
    end
    fp:close()
    md.line = nil
    md.file = nil
    return md
end
return markdown
