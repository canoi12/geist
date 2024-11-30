local html = {}

local out = ""
local function encode_text(content)
    local str = ""
    for _,c in ipairs(content) do
        if c.type == 'text' then
            str = str .. c.value
        elseif c.type == 'bold' then
            str = str .. '<b>' .. c.value .. '</b>'
        elseif c.type == 'italic' then
            str = str .. '<i>' .. c.value .. '</i>'
        elseif c.type == 'code' then
            str = str .. '<code>' .. c.value .. '</code>'
        elseif c.type == 'link' then
            str = str .. '<a target="__blank" href="' .. c.href .. '">' .. c.name .. '</a>'
        end
    end
    return str
end

function html.encode(content)
    out = ""
    for _,block in ipairs(content) do
        if block.type == 'multi code' then
            out = out .. '<pre><code'
            if block.lang then
                out = out .. ' class="' .. block.lang .. '"'
            end
            out = out .. '>\n'
            for _,c in ipairs(block.value) do
                out = out .. c .. '\n'
            end
            out = out .. '</code></pre>\n'
        elseif block.type == 'breakline' then
            out = out .. '<br/>\n'
        elseif block.type == 'list' then
            out = out .. '<ul>\n'
            for j,v in ipairs(block.value) do
                -- print(j, v.type)
                out = out .. '<li>' .. encode_text(v) .. '</li>\n'
            end
            out = out .. '</ul>\n'
        elseif block.type == 'image' then
            out = out .. '<img alt="' .. block.alt .. '" src="' .. block.src .. '"/>'
        elseif block.type == 'paragraph' then
            out = out .. '<p>' .. encode_text(block.value) .. '</p>'
        end
    end
    return out
end

return html
