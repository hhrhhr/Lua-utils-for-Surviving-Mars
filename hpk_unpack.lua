require("mod_binary_reader")
local lz4 = require("lz4")
local r = BinaryReader or {}

local in_file = assert(arg[1], "\n\nno input file\n")
local out_path = arg[2] or nil

local entry = {}
local tree = {}
local file = {}
local path = {}

local function parse_header()
    r:idstring("BPUL")
    assert(36 == r:uint32())
    assert(1 == r:uint32())
    assert(-1 == r:sint32())
    assert(0 == r:uint32())
    assert(0 == r:uint32())
    assert(1 == r:uint32())

    entry.offset = r:uint32()
    entry.count = r:uint32() // 8

    r:seek(entry.offset)
    for _ = 1, entry.count do
        table.insert(entry, {r:uint32(), r:uint32()})
    end
end

local function parse_file(entry)
    local t = {}
    t[1] = entry[1] -- offset
    t[2] = entry[2] -- size
    t[3] = table.concat(path, "\\")
    table.insert(file, t)
    if not out_path then
        print(table.concat(t, "\t"))
    end
end

local function parse_dir(idx)
    local pos = r:pos() -- save position
    local e = entry[idx]
    r:seek(e[1])
    local left = e[2]
    while left > 0 do
        local link = r:uint32()
        local attr = r:uint32()
        local sz = r:uint16()
        local name = r:str(sz)
        left = left - 10 - sz

        table.insert(path, name)
        if 1 == attr then
            table.insert(tree, table.concat(path, "\\"))
            parse_dir(link)
        elseif 0 == attr then
            parse_file(entry[link])
        else
            assert(false, "\n\nunknown attr: " .. attr .. "\n")
        end
        table.remove(path)
    end
    r:seek(pos) -- restore position
end

local function unlz(zsz)
    local size = r:uint32()
    local block = r:uint32()
    if size == 0 then return "" end
    local h_size = r:uint32()
    local zsize = zsz - h_size
    local data = {}
    
    local function unlz4(zsz, sz)
        if sz > zsz then
            local lz_data = r:str(zsz)
            local unlz_data = lz4.block_decompress_safe(lz_data, sz)
            table.insert(data, unlz_data)
        else
            table.insert(data, r:str(sz))
        end
    end
    
    local chunks = (h_size - 16) >> 2
    if chunks > 0 then
        local chunk = {[0] = h_size}
        for i = 1, chunks do
            chunk[i] = r:uint32()
        end
        -- complete chunks (131072 bytes)
        for j = 1, chunks do
            local zsz = chunk[j] - chunk[j-1]
            zsize = zsize - zsz
            unlz4(zsz, block)
        end
    end
    -- tail chunk
    local sz = size - chunks * block
    unlz4(zsize, sz)

    return table.concat(data)
end

local function save_file(f)
    local fullpath = out_path .. "\\" .. f[3]
    print(f[1], f[2], fullpath)
    r:seek(f[1])
    local data
    local fourcc = r:uint32()
    if fourcc == 540301900 then -- "LZ4 "
        data = unlz(f[2])
    else
        r:seek(f[1])
        data = r:str(f[2])
    end
    if data then
        local w = assert(io.open(fullpath, "w+b"))
        w:write(data)
        w:close()
    end
end

local function prepare_dirtree()
    for i = 1, #tree do
        local t = tree[i]
        os.execute("mkdir \"" .. out_path .. "\\" .. t .. "\" >NUL 2>&1")
    end
end

local function export_files()
    local count = #file
--    print("N/" .. count .. "\toffset\tsize\tfullpath")
    for i = 1, count do
        local f = file[i]
--        print(i, table.concat(f, "\t"))
        save_file(f)
    end
end


--[[ main ]]--
r:open(in_file)
parse_header()
parse_dir(1)
if out_path then
    prepare_dirtree()
    export_files()
end
r:close()
