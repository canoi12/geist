local md = require('markdown')
local html = require('html')
local cont = md.decode('post.md')

print(cont)
print('testandow')
for i,v in pairs(cont.content) do
    -- print(i, v)
end

local f = io.open('post.json', 'w')
-- local str = geist.json.encode({olar = "Brazil", oler = 'Brazel'})
local str = geist.json.encode(cont)
--print(str)
f:write(str)
f:close()
f = io.open('post.html', 'w')
f:write(html.encode(cont.content))
f:close()
