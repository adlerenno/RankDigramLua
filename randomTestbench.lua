require("Graph")
require("helpers")

local function oldMethod(fileName, minOccs)
    print("Old method:")
    local graph = Graph:newFromFile(string.format("%s.grph", fileName))
    local stats = {
        replace={},
        prune={},
        decompress={}
    }

    _, stats.replace.time, stats.replace.realTime, stats.replace.ram = helpers.benchmark(graph.replaceDigrams, graph, minOccs)
    stats.replace.size = graph:getSize()

    _, stats.prune.time, stats.prune.realTime, stats.prune.ram = helpers.benchmark(graph.prune, graph)
    stats.prune.size = graph:getSize()

    graph:saveToFile(string.format("%sComp.grph", fileName))

    _, stats.decompress.time, stats.decompress.realTime, stats.decompress.ram = helpers.benchmark(graph.decompress, graph)
    stats.decompress.size = graph:getSize()

    local comparison = Graph:newFromFile(string.format("%s.grph", fileName))
    if graph == comparison then
        print("Decompression successful!")
    else
        graph:saveToFile(string.format("%sDecomp.grph", fileName))
        print("CRITICAL: Graph is not the same as before!")
        os.exit()
    end

    return stats
end

local function newMethod(fileName, minOccs)
    print("New method:")
    local graph = Graph:newFromFile(string.format("%s.grph", fileName))
    local stats = {
        replace={},
        prune={},
        decompress={}
    }

    _, stats.replace.time, stats.replace.realTime, stats.replace.ram = helpers.benchmark(graph.replaceGeneralDigrams, graph, minOccs)
    stats.replace.size = graph:getSize()

    _, stats.prune.time, stats.prune.realTime, stats.prune.ram = helpers.benchmark(graph.pruneGeneral, graph)
    stats.prune.size = graph:getSize()

    graph:saveToFile(string.format("%sGeneralComp.grph", fileName))

    _, stats.decompress.time, stats.decompress.realTime, stats.decompress.ram = helpers.benchmark(graph.decompressGeneral, graph)
    stats.decompress.size = graph:getSize()

    local comparison = Graph:newFromFile(string.format("%s.grph", fileName))
    if graph == comparison then
        print("Decompression successful!")
    else
        graph:saveToFile(string.format("%sGeneralDecomp.grph", fileName))
        print("CRITICAL: Graph is not the same as before!")
        os.exit()
    end

    return stats
end

local function insertStatsInHistory(stats, history)
    table.insert(history.replace.time, stats.replace.time)
    table.insert(history.replace.realTime, stats.replace.realTime)
    table.insert(history.replace.ram, stats.replace.ram)
    table.insert(history.replace.size, stats.replace.size)

    table.insert(history.prune.time, stats.prune.time)
    table.insert(history.prune.realTime, stats.prune.realTime)
    table.insert(history.prune.ram, stats.prune.ram)
    table.insert(history.prune.size, stats.prune.size)

    table.insert(history.decompress.time, stats.decompress.time)
    table.insert(history.decompress.realTime, stats.decompress.realTime)
    table.insert(history.decompress.ram, stats.decompress.ram)
    table.insert(history.decompress.size, stats.decompress.size)
end

local function historyToMedian(history)
    history.replace.time = helpers.median(history.replace.time)
    history.replace.realTime = helpers.median(history.replace.realTime)
    history.replace.ram = helpers.median(history.replace.ram)
    history.replace.size = math.floor(helpers.median(history.replace.size))

    history.prune.time = helpers.median(history.prune.time)
    history.prune.realTime = helpers.median(history.prune.realTime)
    history.prune.ram = helpers.median(history.prune.ram)
    history.prune.size = math.floor(helpers.median(history.prune.size))

    history.decompress.time = helpers.median(history.decompress.time)
    history.decompress.realTime = helpers.median(history.decompress.realTime)
    history.decompress.ram = helpers.median(history.decompress.ram)
    history.decompress.size = math.floor(helpers.median(history.decompress.size))
end

local nodeAmount = tonumber(arg[1])
local edgeAmount = tonumber(arg[2])
local differentEdgeNameAmount = tonumber(arg[3])
local runAmount = tonumber(arg[4])

local oldHistory = {
    replace={
        time={},
        realTime={},
        ram={},
        size={}
    },
    prune={
        time={},
        realTime={},
        ram={},
        size={}
    },
    decompress={
        time={},
        realTime={},
        ram={},
        size={}
    }
}

local newHistory = {
    replace={
        time={},
        realTime={},
        ram={},
        size={}
    },
    prune={
        time={},
        realTime={},
        ram={},
        size={}
    },
    decompress={
        time={},
        realTime={},
        ram={},
        size={}
    }
}

for run=1,runAmount do
    local graph = Graph:newRandom(nodeAmount, edgeAmount, differentEdgeNameAmount)
    local fileName = string.format("%i_%i_%i", nodeAmount, edgeAmount, differentEdgeNameAmount)
    graph:saveToFile(string.format("%s.grph", fileName))
    local oldStats = oldMethod(fileName)
    insertStatsInHistory(oldStats, oldHistory)
    local newStats = newMethod(fileName)
    insertStatsInHistory(newStats, newHistory)
    print(string.format("Run %i complete.", run))
end

historyToMedian(oldHistory)
historyToMedian(newHistory)

print("----------------------")
print(string.format("RandomGraph: Nodes=%i Edges=%i Names=%i", nodeAmount, edgeAmount, differentEdgeNameAmount))
print(string.format("Runs: %i", runAmount))
print("Results:")
print(string.format("Normal:  %i -> %i -> %i", oldHistory.decompress.size, oldHistory.replace.size, oldHistory.prune.size))
print(string.format("General: %i -> %i -> %i", newHistory.decompress.size, newHistory.replace.size, newHistory.prune.size))
print("Percentages:")
print(string.format("Normal:  100%% -> %s%% -> %s%% (%s)", string.format("%.2f", (oldHistory.replace.size / oldHistory.decompress.size) * 100), string.format("%.2f", (oldHistory.prune.size / oldHistory.decompress.size) * 100), string.format("%.2f", ((oldHistory.replace.size - oldHistory.prune.size) / oldHistory.prune.size) * 100)))
print(string.format("General: 100%% -> %s%% -> %s%% (%s)", string.format("%.2f", (newHistory.replace.size / newHistory.decompress.size) * 100), string.format("%.2f", (newHistory.prune.size / newHistory.decompress.size) * 100), string.format("%.2f", ((newHistory.replace.size - newHistory.prune.size) / newHistory.prune.size) * 100)))
print("Runtimes:")
print(string.format("Normal:  %s + %s = %s [%s]", string.format("%.4f", oldHistory.replace.time), string.format("%.4f", oldHistory.prune.time), string.format("%.4f", oldHistory.replace.time + oldHistory.prune.time), string.format("%.4f", oldHistory.decompress.time)))
print(string.format("General: %s + %s = %s [%s]", string.format("%.4f", newHistory.replace.time), string.format("%.4f", newHistory.prune.time), string.format("%.4f", newHistory.replace.time + newHistory.prune.time), string.format("%.4f", newHistory.decompress.time)))
print("Real Runtimes:")
print(string.format("Normal:  %s + %s = %s [%s]", string.format("%.4f", oldHistory.replace.realTime), string.format("%.4f", oldHistory.prune.realTime), string.format("%.4f", oldHistory.replace.realTime + oldHistory.prune.realTime), string.format("%.4f", oldHistory.decompress.realTime)))
print(string.format("General: %s + %s = %s [%s]", string.format("%.4f", newHistory.replace.realTime), string.format("%.4f", newHistory.prune.realTime), string.format("%.4f", newHistory.replace.realTime + newHistory.prune.realTime), string.format("%.4f", newHistory.decompress.realTime)))
print("----------------------")
