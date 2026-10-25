require("Graph")
require("helpers")

local function oldMethod(fileName, minOccs)
    print("Old method:")
    local graph = Graph:newFromFile(fileName)
    local startSize = graph:getSize()
    local _, replaceTime, realReplaceTime, replaceRam = helpers.benchmark(graph.replaceDigrams, graph, minOccs)
    local replacementSize = graph:getSize()
    local _, pruneTime, realPruneTime, pruneRam = helpers.benchmark(graph.prune, graph)
    local pruneSize = graph:getSize()
    local newName, _ = fileName:gsub("%..-$", "Comp.grph")
    graph:saveToFile(newName)

    local _, decompressionTime, realDecompressionTime, decompressionRam = helpers.benchmark(graph.decompress, graph)
    local comparison = Graph:newFromFile(fileName)
    if graph == comparison then
        print("Decompression successful!")
    else
        newName, _ = fileName:gsub("%..-$", "Decomp.grph")
        graph:saveToFile(newName)
        print("CRITICAL: Graph is not the same as before!")
        os.exit()
    end

    return startSize, replaceTime, realReplaceTime, replaceRam, replacementSize, pruneTime, realPruneTime, pruneRam, pruneSize, decompressionTime, realDecompressionTime, decompressionRam
end

local function newMethod(fileName, minOccs)
    print("New method:")
    local graph = Graph:newFromFile(fileName)
    local startSize = graph:getSize()
    local _, replaceTime, realReplaceTime, replaceRam = helpers.benchmark(graph.replaceGeneralDigrams, graph, minOccs)
    local replacementSize = graph:getSize()
    local _, pruneTime, realPruneTime, pruneRam = helpers.benchmark(graph.pruneGeneral, graph)
    local pruneSize = graph:getSize()
    local newName, _ = fileName:gsub("%..-$", "GeneralComp.grph")
    graph:saveToFile(newName)

    local _, decompressionTime, realDecompressionTime, decompressionRam = helpers.benchmark(graph.decompressGeneral, graph)
    local comparison = Graph:newFromFile(fileName)
    if graph == comparison then
        print("Decompression successful!")
    else
        newName, _ = fileName:gsub("%..-$", "GeneralDecomp.grph")
        graph:saveToFile(newName)
        print("CRITICAL: Graph is not the same as before!")
        os.exit()
    end

    return startSize, replaceTime, realReplaceTime, replaceRam, replacementSize, pruneTime, realPruneTime, pruneRam, pruneSize, decompressionTime, realDecompressionTime, decompressionRam
end

local fileName = arg[1]
local method = arg[2] or "both"
local minOccs = arg[3]
if minOccs ~= nil then
    minOccs = tonumber(minOccs)
end

local doOld = (method == "old") or (method == "both")
local doNew = (method == "new") or (method == "both")
local startSize, replaceTime, realReplaceTime, replaceRam, replacementSize, pruneTime, realPruneTime, pruneRam, pruneSize, decompressionTime, realDecompressionTime, decompressionRam
local generalStartSize, generalReplaceTime, realGeneralReplaceTime, generalReplaceRam, generalReplacementSize, generalPruneTime, realGeneralPruneTime, generalPruneRam, generalPruneSize, generalDecompressionTime, realGeneralDecompressionTime, generalDecompressionRam
if doOld then
    startSize, replaceTime, realReplaceTime, replaceRam, replacementSize, pruneTime, realPruneTime, pruneRam, pruneSize, decompressionTime, realDecompressionTime, decompressionRam = oldMethod(fileName, minOccs)
end

if doNew then
    if doOld then
        print("----------------------")
    end

    generalStartSize, generalReplaceTime, realGeneralReplaceTime, generalReplaceRam, generalReplacementSize, generalPruneTime, realGeneralPruneTime, generalPruneRam, generalPruneSize, generalDecompressionTime, realGeneralDecompressionTime, generalDecompressionRam = newMethod(fileName, minOccs)
end

print("----------------------")
print("File: " .. fileName)
print("Results:")
if doOld then
    print("Normal:  " .. startSize .. " -> " .. replacementSize .. " -> " .. pruneSize)
end

if doNew then
    print("General: " .. generalStartSize .. " -> " .. generalReplacementSize .. " -> " .. generalPruneSize)
end

print("Percentages:")
if doOld then
    print("Normal:  " .. "100%" .. " -> " .. string.format("%.2f", (replacementSize / startSize) * 100) .. "% -> " .. string.format("%.2f", (pruneSize / startSize) * 100) .. "% (" .. string.format("%.2f", ((replacementSize - pruneSize) / pruneSize) * 100) .. ")")
end

if doNew then
    print("General: " .. "100%" .. " -> " .. string.format("%.2f", (generalReplacementSize / generalStartSize) * 100) .. "% -> " .. string.format("%.2f", (generalPruneSize / generalStartSize) * 100) .. "% (" .. string.format("%.2f", ((generalReplacementSize - generalPruneSize) / generalPruneSize) * 100) .. ")")
end

print("Runtimes:")
if doOld then
    print("Normal:  " .. string.format("%.4f", replaceTime) .. " + " .. string.format("%.4f", pruneTime) .. " = " .. string.format("%.4f", replaceTime + pruneTime) .. " [" .. string.format("%.4f", decompressionTime) .. "]")
end

if doNew then
    print("General: " .. string.format("%.4f", generalReplaceTime) .. " + " .. string.format("%.4f", generalPruneTime) .. " = " .. string.format("%.4f", generalReplaceTime + generalPruneTime) .. " [" .. string.format("%.4f", generalDecompressionTime) .. "]")
end

print("Real Runtimes:")
if doOld then
    print("Normal:  " .. string.format("%.4f", realReplaceTime) .. " + " .. string.format("%.4f", realPruneTime) .. " = " .. string.format("%.4f", realReplaceTime + realPruneTime) .. " [" .. string.format("%.4f", realDecompressionTime) .. "]")
end

if doNew then
    print("General: " .. string.format("%.4f", realGeneralReplaceTime) .. " + " .. string.format("%.4f", realGeneralPruneTime) .. " = " .. string.format("%.4f", realGeneralReplaceTime + realGeneralPruneTime) .. " [" .. string.format("%.4f", realGeneralDecompressionTime) .. "]")
end

print("----------------------")