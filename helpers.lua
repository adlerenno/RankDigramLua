local function portableUnpack(t)
    -- LuaJIT only supports unpack, while Lua only supports table.unpack
    if unpack == nil then
        -- Lua
        return table.unpack(t)
    else
        -- LuaJIT
        return unpack(t)
    end
end

local function smallBenchmark(func, ...)
    local cpuStart = os.clock()
    local result = {func(...)}
    local cpuStop = os.clock()
    return result, (cpuStop - cpuStart)
end

local function benchmark(func, ...)
    -- see: https://stackoverflow.com/a/56995937/12164411
    local realStart, cpuStart = os.time(), os.clock()
    local result = {func(...)}
    local realStop, cpuStop = os.time(), os.clock()
    collectgarbage() -- just to make sure that memory count is independent of garbage collector
    local ram = collectgarbage("count")
    return result, (cpuStop - cpuStart), (realStop - realStart), ram
end

local function printBenchmark(name, result, cpuTime, realTime, ram)
    print("------------------")
    print("Benchmarks for: " .. name)
    print(string.format("CPU Time: %.4f seconds", cpuTime))
    print("Real Time: " .. realTime .. " seconds")
    print(string.format("Current Memory Usage: %.2f MB", ram / 1000))
    print("------------------")
    return portableUnpack(result)
end

local function printEdge(edge)
    print(string.format("%s(%s)", edge[1], table.concat(edge, ", ", 2)))
end

local function printAdjacencyTypes(adjacencyTypes)
    print("Adjacency Types:")
    for node, adjacencyTypesPerNode in pairs(adjacencyTypes) do
        local s = node .. ":"
        for _, adjacencyType in ipairs(adjacencyTypesPerNode) do
            s = s .. " " .. adjacencyType.occurrences .. "x(" .. adjacencyType.edgeName .. ", " .. adjacencyType.connectionType .. ")"
        end

        print(s)
    end
end

local function printAdjacencyTypesWithRank(adjacencyTypes)
    print("Adjacency Types with Rank:")
    for node, adjacencyTypesPerNode in pairs(adjacencyTypes) do
        local s = node .. ":"
        for _, adjacencyType in ipairs(adjacencyTypesPerNode) do
            s = string.format("%s %sx(%s, %s, %s)", s, adjacencyType.occurrences, adjacencyType.edgeName,
                    adjacencyType.connectionType, adjacencyType.rank)
        end

        print(s)
    end
end

local function printDigram(digram)
    print(string.format("%ix((%s, %s), (%s, %s))", digram.occurrences, digram.first.edgeName,
            digram.first.connectionType, digram.second.edgeName, digram.second.connectionType))
end

local function printDigrams(digrams)
    print("Digrams:")
    for _, digram in ipairs(digrams) do
        local s = string.format("%ix((%s, %s), (%s, %s))", digram.occurrences, digram.first.edgeName,
                digram.first.connectionType, digram.second.edgeName, digram.second.connectionType)
        print(s)
    end
end

local function printGeneralDigram(digram)
    print(string.format("%ix((%s, %s, %s), (%s, %s))", digram.occurrences, digram.adjacencyType.edgeName,
            digram.adjacencyType.connectionType, digram.adjacencyType.rank, digram.generalType.connectionType,
            digram.generalType.rank))
end

local function printGeneralDigrams(digrams)
    print("General Digrams:")
    for _, digram in ipairs(digrams) do
        local s = string.format("%ix((%s, %s, %s), (%s, %s))", digram.occurrences, digram.adjacencyType.edgeName,
                digram.adjacencyType.connectionType, digram.adjacencyType.rank, digram.generalType.connectionType,
                digram.generalType.rank)
        print(s)
    end
end

local function printRule(rule)
    local rulePartStrings = {} -- array
    for i, rulePart in ipairs(rule) do
        rulePartStrings[i] = string.format("%s(%s)", rulePart[1], table.concat(rulePart, ", ", 2))
    end

    print(table.concat(rulePartStrings, " + "))
end

local function printRules(rules)
    print("Rules:")
    for name, rule in pairs(rules) do
        local rulePartStrings = {} -- array
        for i, rulePart in ipairs(rule) do
            rulePartStrings[i] = string.format("%s(%s)", rulePart[1], table.concat(rulePart, ", ", 2))
        end

        print(string.format("%s -> %s", name, table.concat(rulePartStrings, " + ")))
    end
end

local function median(array)
    local copy = {}
    for i, v in ipairs(array) do
        copy[i] = v
    end

    table.sort(copy)
    local copyLength = #copy
    if (copyLength % 2) == 1 then
        -- copy has uneven length
        return copy[(copyLength + 1) / 2]
    else
        -- copy has even length
        return (copy[copyLength / 2] + copy[(copyLength / 2) + 1]) / 2
    end
end

helpers = {
    portableUnpack=portableUnpack,
    benchmark=benchmark,
    smallBenchmark=smallBenchmark,
    printBenchmark=printBenchmark,
    printEdge=printEdge,
    printAdjacencyTypes=printAdjacencyTypes,
    printAdjacencyTypesWithRank=printAdjacencyTypesWithRank,
    printDigram=printDigram,
    printDigrams=printDigrams,
    printGeneralDigram=printGeneralDigram,
    printGeneralDigrams=printGeneralDigrams,
    printRule=printRule,
    printRules=printRules,
    median=median
}