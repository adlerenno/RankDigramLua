local function convert(fileName)
    local readFile = assert(io.open(fileName, "r"))
    local writeFile = assert(io.open(fileName .. ".grph", "w"))
    writeFile:write("Base:\n")
    for line in readFile:lines() do
        if not line:find("^%s*#") and not line:find("^%s*$") then -- line is not comment and not empty
            local writeString = "0"
            for edge_part in line:gmatch("%g+") do
                edge_part = tonumber(edge_part) + 1 -- ensure no 0 node is in graph
                writeString = writeString .. "\t" .. edge_part
            end

            writeFile:write(writeString, "\n")
        end
    end

    readFile:close()
    writeFile:close()
    os.remove(fileName)
end

convert(arg[1])