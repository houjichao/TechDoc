--- String 辅助工具

function string.startWith(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function string.endWith(String,End)
    return End=='' or string.sub(String,-string.len(End))==End
end

function string.hex2base64(s)
    local raw = s:gsub("..",function(cc)  return string.char(tonumber(cc,16)) end)
    return ngx.encode_base64(raw)
end


function string.split(raws,pat)
    local t = {}
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = raws:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t,cap)
        end
        last_end = e+1
        s, e, cap = raws:find(fpat, last_end)
    end
    if last_end <= #raws then
        cap = raws:sub(last_end)
        table.insert(t, cap)
    end
    return t
end

function string.trim(s)
    return s:match"^%s*(.*)":match"(.-)%s*$"
end

function string.random_string(length)
    local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-={}|[]`~'
    local random_string = ''
    math.randomseed(os.time())
    charTable = {}
    for c in chars:gmatch"." do
        table.insert(charTable, c)
    end
    for i = 1, length do
        random_string = random_string .. charTable[math.random(1, #charTable)]
    end
    return random_string
end