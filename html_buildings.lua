--require('mobdebug').start()

local template = {}
local function parse(t)
    local tmp = {}
    for i = 1, #t do
        for j = 1, #t, 2 do
            local k = t[j]
            local v = t[j+1]
            tmp[k] = v
        end
    end
    table.insert(template, tmp)
end

function PlaceObj(n, t) parse(t) end
function T(t) return t[2] end
function range(from, to) return from.."-"..to end
function RGBA(r, g, b, a) return r..", "..g..", "..b..", "..a end

local function load_lua(fname)
    local r = assert(io.open(fname, "rb"))
    local data = {}
    data[1] = r:read(14)
    data[2] = "\x04\x08"
    data[3] = r:read("a")
    r:close()
    data = table.concat(data)
    return load(data)   -- data, err
end

local function err_msg(msg)
    return "\n" .. string.rep("-", 80) .. "\nERROR: " .. tostring(msg) .. "\n" .. string.rep("-", 80)
end

local content, err = load_lua("d:/tmp/surv_mars/out1/Data/BuildingTemplate.lua.ori")
assert(content, err_msg(err))
content()

--[[    ]]---------------------------------------------------------------------

local function sort_template(a, b)
    if (a.build_category < b.build_category) then
        return true
    elseif (a.build_category == b.build_category) then
        a.build_pos = a.build_pos or 1
        b.build_pos = b.build_pos or 1
        if (a.build_pos < b.build_pos) then
            return true
        end
    end
    return false
end
table.sort(template, sort_template)


local function scale_value(val, s)
    if val and val > 0 then
        return tostring(val / s):gsub("%.?0+$", "")
    else
        return nil
    end
end

--[[ html ]]-------------------------------------------------------------------

io.write([[
<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<title>Surviving Mars Buildings</title>
<link rel="stylesheet" href="style.css" />
</head>
<body>]])

io.write("<table cols='5'>")
io.write("<thead><tr><th>icon</th><th>name</th><th class='th_cost'>build</th><th class='th_cost'>service</th><th>consup</th></tr></thead>")

local icon_fmt = "<i class='icon %s' title='%s'></i>"
local name_fmt = "<p class='name'>%s</span><p class='description'>%s%s"
local cost_fmt = "<i class='res %s'></i>%s"
local cons_fmt = "<i class='res %s'></i>%s"

local old_cat = ""

for i = 1, #template do
    local ti = template[i]
    local t = {}

    local cat = ti.build_category
    if old_cat ~= cat then
        io.write("<tr><th class='th_category' colspan='5'>" .. cat .. "</td></tr>\n")
        old_cat = cat
    end

    local icon = string.gsub(ti.display_icon, ".+/(.+)%.tga$", "%1")
    table.insert(t, icon_fmt:format(icon, ti.name))

    local text = "" --[[ti.encyclopedia_text
    if text then
        text = text:gsub("\n\n", "<p class='p_normal'>")
        text = text:gsub("<left>", "<p class='p_normal'>")
        text = text:gsub("<center>", "<p class='p_center'>")
        text = text:gsub("<image (.+) (%d+)>", "<span>%1 # %2</span>")
        text = "<blockquote class='text'><p>" .. text .. "</blockquote>"
    else
        text = ""
    end--]]
    local desc = ti.description
    local res, max
    for r, m in desc:gmatch("<(.+)%((.+)%)>") do
        if r and m then
            res = r
            max = scale_value(ti[m], 1000) or 30
        end
    end
    if "resource" == res then
        res = max
    else
        if "metals" == res then res = "metal"
        elseif "preciousmetals" == res then res = "precious_metals"
        elseif "machineparts" == res then res = "machine_parts"
        elseif "wasterock" == res then res = "waste_rock"
        end
        res = cost_fmt:format(res, max)
    end
    desc = desc:gsub("(.+)<(.+)%((.+)%)>(.+)", "%1" .. res .. "%4")

    table.insert(t, name_fmt:format(ti.display_name, desc, text))

    -- construction_cost
    local c = {}
    local met = scale_value(ti.construction_cost_Metals, 1000)
    local con = scale_value(ti.construction_cost_Concrete, 1000)
    local pol = scale_value(ti.construction_cost_Polymers, 1000)
    local ele = scale_value(ti.construction_cost_Electronics, 1000)
    local par = scale_value(ti.construction_cost_MachineParts, 1000)
    local cub = scale_value(ti.construction_cost_BlackCube, 1000)

    if met then table.insert(c, cost_fmt:format("metal", met)) end
    if con then table.insert(c, cost_fmt:format("concrete", con)) end
    if pol then table.insert(c, cost_fmt:format("polymers", pol)) end
    if ele then table.insert(c, cost_fmt:format("electronics", ele)) end
    if par then table.insert(c, cost_fmt:format("machine_parts", par)) end
    if cub then table.insert(c, cost_fmt:format("black_box", cub)) end
    table.insert(t, "<span class='cost'>" .. table.concat(c, "<br />") .. "</span>")

    -- maintenance cost
    local res_type = ti.maintenance_resource_type
    if res_type then
        c = {}
        local res_amount = ti.maintenance_resource_amount or 1000
        res_amount = res_amount // 1000
        if "Metals" == res_type then table.insert(c, cost_fmt:format("metal", res_amount))
        elseif "Concrete" == res_type then table.insert(c, cost_fmt:format("concrete", res_amount))
        elseif "Polymers" == res_type then table.insert(c, cost_fmt:format("polymers", res_amount))
        elseif "Electronics" == res_type then table.insert(c, cost_fmt:format("electronics", res_amount))
        elseif "MachineParts" == res_type then table.insert(c, cost_fmt:format("machine_parts", res_amount))
        end
        table.insert(t, "<span class='cost'>" .. table.concat(c, "&nbsp;") .. "</span>")
    else
        table.insert(t, "<span class='cost'></span>")
    end

    -- consuption
    c = {}
    ele = scale_value(ti.electricity_consumption, 1000)
    local air = scale_value(ti.air_consumption, 1000)
    local wat = scale_value(ti.water_consumption, 1000)

    if ele then table.insert(c, cons_fmt:format("electricity", ele)) end
    if air then table.insert(c, cons_fmt:format("oxygen", air)) end
    if wat then table.insert(c, cons_fmt:format("water", wat)) end
    table.insert(t, "<span class='cost'>" .. table.concat(c, "<br />") .. "</span>")


    io.write("<tr>\n<td>")
    io.write(table.concat(t, "</td>\n<td>"))
    io.write("</td>\n</tr>\n")
end
io.write("</table>")

io.write("</body>")
