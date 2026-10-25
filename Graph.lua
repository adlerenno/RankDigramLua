require("helpers")

Graph = {}

-- todo: not every line works with strings as edge or node names (or does it?)
-- todo: currently only directed?
function Graph:new()
    object = {
        edgesPerNode={},
        rules={}
    }

    setmetatable(object, self)
    self.__index = self
    return object
end

function Graph:newFromFile(fileName)
    local graph = Graph:new()
    local ruleMode = true
    local file = assert(io.open(fileName, "r"))
    for line in file:lines() do
        if line:find("^Base:$") then
            ruleMode = false
        elseif not line:find("^%s*#") and not line:find("^%s*$") then -- line is not comment and not empty
            if ruleMode then
                local _, endOfMatch, captureName = line:find("^(%g+)\t%g")
                local name = tonumber(captureName) or captureName
                local stripped = line:sub(endOfMatch, line:len()) .. "\t\t"
                local rule = {name}
                for part in stripped:gmatch("(.-)\t\t") do
                    local edge = {}
                    for edgePart in part:gmatch("%g+") do
                        table.insert(edge, tonumber(edgePart) or edgePart)
                    end

                    table.insert(rule, edge)
                end

                graph:addRule(helpers.portableUnpack(rule))
            else
                local edge = {}
                for edgePart in line:gmatch("%g+") do
                    edgePart = tonumber(edgePart) or edgePart
                    if (edge[1] ~= nil) and (graph.edgesPerNode[edgePart] == nil) then
                        -- edge name already has been added and edge_part is now a node name that isn't in the graph
                        graph:addNode(edgePart)
                    end

                    table.insert(edge, edgePart)
                end

                graph:addEdge(helpers.portableUnpack(edge)) -- fixme: this might cause issues with importing of compressed general edges
            end
        end
    end

    file:close()
    return graph
end

function Graph:newRandom(nodeAmount, edgeAmount, differentEdgeNameAmount)
    -- todo: maybe add highest node rank for random hypergraphs
    math.randomseed(os.time())
    if edgeAmount < nodeAmount - 1 then
        -- i need two edges to connect three nodes
        error("Please specify enough edges to connect all nodes!")
    elseif differentEdgeNameAmount <= 0 then
        error("Please specify enough edge names!")
    end

    local nodes, edges = {}, {} -- arrays
    for i=1,nodeAmount do
        nodes[i] = i
    end

    for i=1,edgeAmount do
        edges[i] = nodeAmount + math.random(differentEdgeNameAmount)
    end

    local alreadyAddedNodeNames = {} -- array
    local graph = Graph:new()
    local node = table.remove(nodes, 1) -- later iteration is ascending, so here we remove the first (to be consistent; just personal preference, no real benefit)
    graph:addNode(node)
    table.insert(alreadyAddedNodeNames, node)
    for _, nodeName in ipairs(nodes) do
        graph:addNode(nodeName)
        local alreadyAddedNodeName = alreadyAddedNodeNames[math.random(#alreadyAddedNodeNames)]
        if math.random(2) == 1 then
            -- new node is first in edge
            graph:addEdge(table.remove(edges), nodeName, alreadyAddedNodeName) -- edges are random, deletion order does not matter
        else
            -- new node is second in edge
            graph:addEdge(table.remove(edges), alreadyAddedNodeName, nodeName) -- edges are random, deletion order does not matter
        end

        table.insert(alreadyAddedNodeNames, nodeName)
    end

    local amountOfNodeNames = #alreadyAddedNodeNames
    for _, edgeName in ipairs(edges) do
        local firstNodeName = alreadyAddedNodeNames[math.random(amountOfNodeNames)]
        local secondNodeName = alreadyAddedNodeNames[math.random(amountOfNodeNames)]
        graph:addEdge(edgeName, firstNodeName, secondNodeName)
    end

    if (graph:getAmountOfNodes() ~= nodeAmount) or (graph:getAmountOfEdges() ~= edgeAmount) then
        error("Graph creation did not work as expected!")
    end

    return graph
end

function Graph:addNode(nodeName)
    if nodeName == nil then
        error("Please specify a valid node name (currently nil)!")
    elseif self.edgesPerNode[nodeName] then
        error("Node already exists!")
    else
        self.edgesPerNode[nodeName] = {}
    end
end

function Graph:removeNode(nodeName)
    if nodeName == nil then
        error("Please specify a valid node name (currently nil)!")
    elseif self.edgesPerNode[nodeName] == nil then
        error("Node does not exist!")
    elseif #self.edgesPerNode[nodeName] > 0 then
        error("Node still has edges! Please remove them first to ensure consistency.")
    else
        self.edgesPerNode[nodeName] = nil
    end
end

function Graph:addEdge(edgeName, firstNode, secondNode, ...)
    if edgeName == nil then
        error("Please specify a valid edge name (currently nil)!")
    elseif firstNode == nil then
        error("Please specify a valid first node (currently nil)!")
    elseif secondNode == nil then
        error("Please specify a valid second node (currently nil)!")
    else
        local nodes = {firstNode, secondNode, ...}
        local edge = {edgeName, firstNode, secondNode, ...}
        local cleanedNodes = {} -- set (no duplicates)
        for i, node in ipairs(nodes) do -- check if all nodes exist
            if self.edgesPerNode[node] == nil then
                error(string.format("Node number %i does not exist!", i))
            else
                cleanedNodes[node] = true
            end
        end

        for node, _ in pairs(cleanedNodes) do -- insert edge in all nodes
            table.insert(self.edgesPerNode[node], edge)
        end
    end
end

function Graph:removeEdge(edgeName, firstNode, secondNode, ...)
    if edgeName == nil then
        error("Please specify a valid edge name (currently nil)!")
    elseif firstNode == nil then
        error("Please specify a valid first node (currently nil)!")
    elseif secondNode == nil then
        error("Please specify a valid second node (currently nil)!")
    else
        local nodesToRemoveFrom = {firstNode, secondNode, ...}
        local edgeToBeRemoved = {edgeName, firstNode, secondNode, ...}
        local realEdge = nil
        for _, node in ipairs(nodesToRemoveFrom) do
            local edges = self.edgesPerNode[node]
            -- see: https://stackoverflow.com/a/53038524/12164411
            local shiftingPosition = 1
            local numberOfEdges = #edges
            for index=1,numberOfEdges do
                local currentEdge = edges[index]
                if realEdge == nil then -- if we already found the realEdge we just need to compare with ==
                    -- lets check if the currentEdge is the edge we need to remove
                    if #currentEdge == #edgeToBeRemoved then
                        -- tables have the same length, if now all values are the same, this is our realEdge
                        local sameValues = true
                        for i, v in ipairs(currentEdge) do
                            if edgeToBeRemoved[i] ~= v then
                                sameValues = false
                                break
                            end
                        end

                        if sameValues then
                            realEdge = currentEdge
                        end
                    end
                end

                local removeEdge = currentEdge == realEdge
                if removeEdge then
                    edges[index] = nil
                    -- even if all occurrences have been removed, iteration needs to continue to relocate left elements
                else
                    -- the edge should be kept and is moved to the shiftingPosition
                    if shiftingPosition ~= index then
                        -- but only if the edge is not already there
                        edges[shiftingPosition] = currentEdge
                        edges[index] = nil
                    end

                    shiftingPosition = shiftingPosition + 1
                end
            end
        end

        if realEdge == nil then
            error("Edge does not exist!")
        end
    end
end

function Graph:addRule(name, firstEdge, secondEdge, ...)
    if name == nil then
        error("Please specify a valid rule name (currently nil)!")
    elseif firstEdge == nil then
        error("Please specify a valid first edge (currently nil)!")
    elseif secondEdge == nil then
        error("Please specify a valid second edge (currently nil)!")
    elseif self.rules[name] then
        error("A rule with this name already exists!")
    else
        local rule = {{}, {}}
        for i, v in ipairs(firstEdge) do
            rule[1][i] = v
        end

        for i, v in ipairs(secondEdge) do
            rule[2][i] = v
        end

        for i, l in ipairs({...}) do
            rule[i+2] = {}
            for j, v in ipairs(l) do
                rule[i+2][j] = v
            end
        end

        self.rules[name] = rule
    end
end

function Graph:getAmountOfNodes()
    local counter = 0
    for _, _ in pairs(self.edgesPerNode) do
        counter = counter + 1
    end

    return counter
end

function Graph:getAmountOfEdges()
    local counter = 0
    local haveSeen = {} -- set
    for _, edges in pairs(self.edgesPerNode) do
        for _, edge in ipairs(edges) do
            if not haveSeen[edge] then
                counter = counter + 1
                haveSeen[edge] = true
            end
        end
    end

    return counter
end

function Graph:_getHighestNumberInGraph()
    local counter = nil
    for node, edges in pairs(self.edgesPerNode) do
        if type(node) == "number" then
            if (counter == nil) or (counter < node) then
                counter = node
            end
        end

        for _, edge in ipairs(edges) do
            for _, v in ipairs(edge) do
                if type(v) == "number" then
                    if (counter == nil) or (counter < v) then
                        counter = v
                    end
                end
            end
        end
    end

    for rule, edges in pairs(self.rules) do
        if type(rule) == "number" then
            if (counter == nil) or (counter < rule) then
                counter = rule
            end
        end

        for _, edge in ipairs(edges) do
            for _, v in ipairs(edge) do
                if type(v) == "number" then
                    if (counter == nil) or (counter < v) then
                        counter = v
                    end
                end
            end
        end
    end

    return counter
end

function Graph:_calculateRuleCallAmounts()
    local countingMap = {} -- set
    for name, rule in pairs(self.rules) do
        countingMap[name] = countingMap[name] or 0
        for _, edge in ipairs(rule) do
            if self.rules[edge[1]] then
                -- edge is rule call
                if countingMap[edge[1]] == nil then
                    countingMap[edge[1]] = 1
                else
                    countingMap[edge[1]] = countingMap[edge[1]] + 1
                end
            end
        end
    end

    local haveSeen = {} -- set
    for _, edges in pairs(self.edgesPerNode) do
        for _, edge in ipairs(edges) do
            if not haveSeen[edge] then
                if self.rules[edge[1]] then
                    -- edge is rule call
                    countingMap[edge[1]] = countingMap[edge[1]] + 1
                end

                haveSeen[edge] = true
            end
        end
    end

    -- i am not sorting this as i probably have to check every entry as well (would have to make to array for sorting as well)
    return countingMap
end

function Graph:_calculateGeneralRuleCallAmounts()
    local countingMap = {} -- set
    for name, rule in pairs(self.rules) do
        countingMap[name] = countingMap[name] or {callAmount=0, paramUses=0}
        if self.rules[rule[1][1]] then
            -- first edge is rule call
            if countingMap[rule[1][1]] == nil then
                countingMap[rule[1][1]] = {callAmount=1, paramUses=0}
            else
                countingMap[rule[1][1]].callAmount = countingMap[rule[1][1]].callAmount + 1
            end
        end
    end

    local haveSeen = {} -- set
    for _, edges in pairs(self.edgesPerNode) do
        for _, edge in ipairs(edges) do
            if not haveSeen[edge] then
                for i, v in ipairs(edge) do
                    if self.rules[v] then
                        if i == 1 then
                            -- edge is rule call
                            countingMap[v].callAmount = countingMap[v].callAmount + 1
                        else
                            countingMap[v].paramUses = countingMap[v].paramUses + 1
                        end
                    end
                end

                haveSeen[edge] = true
            end
        end
    end

    local result = {} -- array
    for k, t in pairs(countingMap) do
        table.insert(result, {ruleName=k, callAmount=t.callAmount, paramUses=t.paramUses})
    end

    table.sort(result, function (a,b) return a.ruleName > b.ruleName end)
    return result
end

-- todo: should i include this in insertEdge and update an object variable?
-- possible optimization: Most nodes only appear once per edge, so only first occurrence of node in edge needs to be
-- found, you could break after. But we need to count the amount of times an edge has been seen in current node to
-- determine which occurrence to find next (or even better: index of last occurrence of node in edge). With many "long"
-- edges, this overhead might be worth it (edge iteration stops earlier)
---calculateAdjacencyTypesPerNode: This function returns a table that contains the list of adjacency-types for every node
function Graph:calculateAdjacencyTypesPerNode()
    local result = {}
    local hashMap = {}
    for node, edges in pairs(self.edgesPerNode) do
        result[node] = {} -- array
        hashMap[node] = {} -- table
        local visitedEdges = {} -- todo: this could be removed, as every edge is now only once in node (even if there is a cycle)
        for _, edge in ipairs(edges) do
            -- edge is a table, so if the same edge occurs more than once, only on occurrence will be used to count
            if visitedEdges[edge] == nil then
                local edgeName = edge[1]
                for index=2,#edge do
                    if edge[index] == node then
                        -- first index in an edge is always its name -> indices are shifted one to the right -> -1
                        local key = string.format("(%s, %s)", tostring(edgeName), tostring(index - 1)) -- todo: non string keys for better performance?
                        if hashMap[node][key] == nil then
                            local adjacencyType = {edgeName=edgeName, connectionType=index-1, occurrences=1}
                            hashMap[node][key] = adjacencyType
                            table.insert(result[node], adjacencyType)
                        else
                            hashMap[node][key].occurrences = hashMap[node][key].occurrences + 1
                        end
                    end
                end

                visitedEdges[edge] = true -- mark edge as visited
            end
        end
    end

    return result
end

function Graph:calculateAdjacencyTypesPerNodeWithRank() -- todo: should i use this for normal digrams as well?
    local result = {}
    local hashMap = {}
    for node, edges in pairs(self.edgesPerNode) do
        result[node] = {} -- array
        hashMap[node] = {} -- table
        local visitedEdges = {} -- todo: this could be removed, as every edge is now only once in node (even if there is a cycle)
        for _, edge in ipairs(edges) do
            -- edge is a table, so if the same edge occurs more than once, only on occurrence will be used to count
            if visitedEdges[edge] == nil then
                local edgeName = edge[1]
                local size = #edge
                local rank = size - 1 -- first value is edge name
                for index=2,size do
                    if edge[index] == node then
                        -- first index in an edge is always its name -> indices are shifted one to the right -> -1
                        local key = string.format("(%s, %s, %s)", edgeName, index - 1, rank) -- todo: non string keys for better performance?
                        if hashMap[node][key] == nil then
                            local adjacencyType = {edgeName=edgeName, connectionType=index-1, rank=rank, occurrences=1}
                            hashMap[node][key] = adjacencyType
                            table.insert(result[node], adjacencyType)
                        else
                            hashMap[node][key].occurrences = hashMap[node][key].occurrences + 1
                        end
                    end
                end

                visitedEdges[edge] = true -- mark edge as visited
            end
        end
    end

    return result
end

---calculateDigrams: This function calculates all digrams and returns a list of them
function Graph:calculateDigrams()
    local result = {} -- array
    local hashMap = {} -- table
    local adjacencyTypesPerNode = self:calculateAdjacencyTypesPerNode()
    for _, adjacencyTypes in pairs(adjacencyTypesPerNode) do
        for _, adjacencyType in ipairs(adjacencyTypes) do
            for _, otherAdjacencyType in ipairs(adjacencyTypes) do
                local occurrences = 0
                if (adjacencyType.edgeName == otherAdjacencyType.edgeName) and (adjacencyType.connectionType == otherAdjacencyType.connectionType) then
                    occurrences = math.floor(adjacencyType.occurrences / 2)
                else
                    occurrences = math.min(adjacencyType.occurrences, otherAdjacencyType.occurrences)
                end

                if occurrences > 0 then -- only first if with adjacencyType.occurrences == 1 could result in occurrences == 0
                    local key = string.format("((%s, %s), (%s, %s))", tostring(adjacencyType.edgeName),
                            tostring(adjacencyType.connectionType), tostring(otherAdjacencyType.edgeName),
                            tostring(otherAdjacencyType.connectionType)) -- todo: non string keys for better performance?

                    if hashMap[key] == nil then
                        local digram = {first=adjacencyType, second=otherAdjacencyType, occurrences=occurrences}
                        hashMap[key] = digram
                        table.insert(result, digram)
                    else
                        hashMap[key].occurrences = hashMap[key].occurrences + occurrences
                    end
                end
            end
        end
    end

    table.sort(result, function (a,b) return a.occurrences > b.occurrences end)
    return result
end

function Graph:calculateGeneralDigrams()
    local result = {} -- array
    local hashMap = {} -- table
    local adjacencyTypesPerNode = self:calculateAdjacencyTypesPerNodeWithRank()
    for _, adjacencyTypes in pairs(adjacencyTypesPerNode) do
        local connectionTypeOccurrencesByRank = {} -- table
        for _, adjacencyType in ipairs(adjacencyTypes) do
            if connectionTypeOccurrencesByRank[adjacencyType.connectionType] == nil then
                connectionTypeOccurrencesByRank[adjacencyType.connectionType] = {} -- table
            end

            if connectionTypeOccurrencesByRank[adjacencyType.connectionType][adjacencyType.rank] == nil then
                connectionTypeOccurrencesByRank[adjacencyType.connectionType][adjacencyType.rank] = adjacencyType.occurrences
            else
                connectionTypeOccurrencesByRank[adjacencyType.connectionType][adjacencyType.rank] =
                connectionTypeOccurrencesByRank[adjacencyType.connectionType][adjacencyType.rank] + adjacencyType.occurrences
            end
        end

        for _, adjacencyType in ipairs(adjacencyTypes) do
            for connectionType, occurrencesByRank in pairs(connectionTypeOccurrencesByRank) do
                for rank, occurrences in pairs(occurrencesByRank) do
                    local occs = 0
                    if connectionType == adjacencyType.connectionType then
                        local occsWithoutMe = occurrences - adjacencyType.occurrences
                        occs = math.min(occsWithoutMe, adjacencyType.occurrences)
                        occs = occs + math.floor((adjacencyType.occurrences - occs) / 2) -- to be able to create new occurrences i need to have at least a difference of two
                    else
                        occs = math.min(occurrences, adjacencyType.occurrences)
                    end

                    -- could be 0 if adjacencyType is only type that has his connectionType and only has one occurrence
                    if occs > 0 then
                        local key = string.format("((%s, %s, %s), (%s, %s))", adjacencyType.edgeName,
                                adjacencyType.connectionType, adjacencyType.rank, connectionType, rank) -- todo: non string keys for better performance?

                        if hashMap[key] == nil then
                            local digram = {adjacencyType=adjacencyType, generalType={connectionType=connectionType, rank=rank}, occurrences=occs}
                            hashMap[key] = digram
                            table.insert(result, digram)
                        else
                            hashMap[key].occurrences = hashMap[key].occurrences + occs
                        end
                    end
                end
            end
        end
    end

    table.sort(result, function (a,b) return a.occurrences > b.occurrences end)
    return result
end

-- assumption: edges have the same length if they have the same name
function Graph:replaceDigram(digram, newEdgeName)
    local rule = nil
    local deletions = {} -- set
    local additions = {} -- set
    -- todo: because traversal order is different each call, each call produces different replacement -> different compression
    for node, edges in pairs(self.edgesPerNode) do
        repeat
            -- todo: i could skip max(firstIndex, secondIndex) edges at the next traversal
            local firstIndex = nil
            local secondIndex = nil
            for index, edge in ipairs(edges) do
                if (deletions[edge] == nil) and (index ~= firstIndex) and (index ~= secondIndex) then
                    -- this ensures that i would get two distinct indices
                    if (firstIndex == nil) and (edge[1] == digram.first.edgeName) and (edge[digram.first.connectionType + 1] == node) then
                        firstIndex = index
                        if secondIndex ~= nil then
                            break
                        end
                    elseif (secondIndex == nil) and (edge[1] == digram.second.edgeName) and (edge[digram.second.connectionType + 1] == node) then
                        secondIndex = index
                        if firstIndex ~= nil then
                            break
                        end
                    end
                end
            end

            if (firstIndex ~= nil) and (secondIndex ~= nil) then
                -- here i have two distinct indices that can be replaced
                local first = edges[firstIndex]
                local second = edges[secondIndex]
                if rule == nil then
                    -- create rule
                    rule = {{digram.first.edgeName}, {digram.second.edgeName}}
                    local nextNumber = 1
                    local index = 2
                    while index <= #first do
                        rule[1][index] = nextNumber
                        nextNumber = nextNumber + 1
                        index = index + 1
                    end

                    index = 2
                    while index <= #second do
                        if index == (digram.second.connectionType + 1) then
                            rule[2][index] = rule[1][digram.first.connectionType + 1]
                        else
                            rule[2][index] = nextNumber
                            nextNumber = nextNumber + 1
                        end

                        index = index + 1
                    end
                end

                -- create replacement
                local replacement = {newEdgeName}
                for i=2,#first do
                    table.insert(replacement, first[i])
                end

                for i=2,#second do
                    if i ~= digram.second.connectionType + 1 then
                        table.insert(replacement, second[i])
                    end
                end

                deletions[first] = true
                deletions[second] = true
                additions[replacement] = true
            end
        until (firstIndex == nil) or (secondIndex == nil)
    end

    for edge, _ in pairs(deletions) do
        self:removeEdge(helpers.portableUnpack(edge))
        --[[
        it shouldn't matter if I delete the exact references or all references of a different edge with the same values,
        the result should be the same (or at least not make a difference for the compression). I should add the custom
        remove edge part here however, since this will probably way faster (because we would only iterate once over
        every edge list).
        --]]
    end

    for edge, _ in pairs(additions) do
        self:addEdge(helpers.portableUnpack(edge))
        --[[ fixme:
        Replaced digram with 2 occurrences
luajit: ./Graph.lua:597: too many results to unpack
stack traceback:
	[C]: in function 'portableUnpack'
	./Graph.lua:597: in function 'replaceDigram'
	./Graph.lua:742: in function 'func'
	./helpers.lua:15: in function 'benchmark'
	test.lua:10: in main chunk
	[C]: at 0x01003e65cc

        --]]
    end

    if rule ~= nil then
        self:addRule(newEdgeName, helpers.portableUnpack(rule))
    end

    return rule
end

function Graph:replaceGeneralDigram(digram, newEdgeName)
    local rule = nil
    local deletions = {} -- set
    local additions = {} -- set
    -- todo: because traversal order is different each call, each call produces different replacement -> different compression
    for node, edges in pairs(self.edgesPerNode) do
        repeat
            -- todo: i could skip max(firstIndex, secondIndex) edges at the next traversal
            local firstIndex = nil
            local secondIndex = nil
            for index, edge in ipairs(edges) do
                if (deletions[edge] == nil) and (index ~= firstIndex) and (index ~= secondIndex) then
                    -- this ensures that i would get two distinct indices
                    if (firstIndex == nil) and (edge[1] == digram.adjacencyType.edgeName)
                            and (edge[digram.adjacencyType.connectionType + 1] == node)
                            and (#edge == digram.adjacencyType.rank + 1) then
                        firstIndex = index
                        if secondIndex ~= nil then
                            break
                        end
                    elseif (secondIndex == nil) and (edge[digram.generalType.connectionType + 1] == node)
                            and (#edge == digram.generalType.rank + 1) then
                        secondIndex = index
                        if firstIndex ~= nil then
                            break
                        end
                    end
                end
            end

            if (firstIndex ~= nil) and (secondIndex ~= nil) then
                -- here i have two distinct indices that can be replaced
                local first = edges[firstIndex]
                local second = edges[secondIndex]
                if rule == nil then
                    -- create rule
                    rule = {{digram.adjacencyType.edgeName}, {}}
                    local nextNumber = 1
                    local index = 2
                    while index <= #first do
                        rule[1][index] = nextNumber
                        nextNumber = nextNumber + 1
                        index = index + 1
                    end

                    index = 2
                    while index <= #second do
                        if index == (digram.generalType.connectionType + 1) then
                            rule[2][index] = rule[1][digram.adjacencyType.connectionType + 1]
                        else
                            rule[2][index] = nextNumber
                            nextNumber = nextNumber + 1
                        end

                        index = index + 1
                    end

                    rule[2][1] = nextNumber
                end

                -- create replacement
                local replacement = {newEdgeName}
                local firstLength = digram.adjacencyType.rank + 1
                local secondLength = digram.generalType.rank + 1
                for i=2,firstLength do
                    replacement[i] = first[i]
                end

                for i=2,secondLength do
                    if i ~= digram.generalType.connectionType + 1 then
                        table.insert(replacement, second[i])
                    end
                end

                table.insert(replacement, second[1])
                deletions[first] = true
                deletions[second] = true
                additions[replacement] = true
            end
        until (firstIndex == nil) or (secondIndex == nil)
    end

    -- delete edges (https://stackoverflow.com/a/53038524/12164411)
    for _, edges in pairs(self.edgesPerNode) do
        local shiftingPosition = 1
        local numberOfEdges = #edges
        for index=1,numberOfEdges do
            local currentEdge = edges[index]
            if deletions[currentEdge] then
                edges[index] = nil
                -- even if all occurrences have been removed, iteration needs to continue to relocate left elements
            else
                -- the edge should be kept and is moved to the shiftingPosition
                if shiftingPosition ~= index then
                    -- but only if the edge is not already there
                    edges[shiftingPosition] = currentEdge
                    edges[index] = nil
                end

                shiftingPosition = shiftingPosition + 1
            end
        end
    end

    for edge, _ in pairs(additions) do
        -- self:addEdge(helpers.portableUnpack(edge))
        -- fixme: quick hack for above statement because some edge parts are not a node
        local addedAlready = {} -- set
        local index = 2
        while index <= #edge do
            local node = edge[index]
            if (self.edgesPerNode[node] ~= nil) and (not addedAlready[node]) then
                table.insert(self.edgesPerNode[node], edge)
                addedAlready[node] = true
            end

            index = index + 1
        end
    end

    if rule ~= nil then
        self:addRule(newEdgeName, helpers.portableUnpack(rule))
    end

    return rule
end

function Graph:replaceDigrams(minOccs)
    local nextRuleName = self:_getHighestNumberInGraph()
    local oldSize = self:getSize()
    local newSize = oldSize
    repeat
        oldSize = newSize
        local digrams = self:calculateDigrams()
        nextRuleName = nextRuleName + 1
        local rule = nil
        for _, digram in ipairs(digrams) do
            if (minOccs ~= nil) and (digram.occurrences < minOccs) then
                break
            end

            rule = self:replaceDigram(digram, nextRuleName)
            if rule ~= nil then
                newSize = self:getSize()
                print(string.format("Replaced digram with %s occurrences", digram.occurrences))
                break
            end
        end

        if rule == nil then
            break
        end
    until (minOccs == nil) and (newSize >= oldSize)
end

function Graph:replaceGeneralDigrams(minOccs)
    local nextRuleName = self:_getHighestNumberInGraph()
    local oldSize = self:getSize()
    local newSize = oldSize
    repeat
        oldSize = newSize
        local digrams = self:calculateGeneralDigrams()
        nextRuleName = nextRuleName + 1
        local rule = nil
        for _, digram in ipairs(digrams) do
            if (minOccs ~= nil) and (digram.occurrences < minOccs) then
                break
            end

            rule = self:replaceGeneralDigram(digram, nextRuleName)
            if rule ~= nil then
                newSize = self:getSize()
                print(string.format("Replaced general digram with %s occurrences", digram.occurrences))
                break
            end
        end

        if rule == nil then
            break
        end
    until (minOccs == nil) and (newSize >= oldSize)
end

function Graph:prune()
    repeat
        local didChange = false
        local ruleCallAmounts = self:_calculateRuleCallAmounts()
        for ruleName, callAmount in pairs(ruleCallAmounts) do -- i dont think I can break iteration. What if next rule has slightly more calls but is 10x in size?
            local oldRule = self.rules[ruleName]
            local p = 1 -- amount of params
            local q = 0 -- amount of param uses
            local e = 0 -- amount of edges
            for _, rulePart in ipairs(oldRule) do
                e = e + 1
                for i, v in ipairs(rulePart) do
                    if i ~= 1 then
                        q = q + 1
                        p = math.max(v, p)
                    end
                end
            end

            if callAmount < math.ceil((1 + q + e) / (q + e - p - 1)) then
                -- rule should be inlined -> i need to find every call todo: maybe i could combine this with the call amount calculation for better performance?
                local changedRules = {} -- set
                for name, rule in pairs(self.rules) do
                    local newRule = {}
                    for _, rulePart in ipairs(rule) do
                        if rulePart[1] == ruleName then
                            -- inline here
                            for _, oldRulePart in ipairs(oldRule) do
                                local newPart = {oldRulePart[1]}
                                for i, v in ipairs(oldRulePart) do
                                    if i ~= 1 then
                                        -- v is a parameter index, cause first value is edge name
                                        newPart[i] = rulePart[v + 1]
                                    end
                                end

                                table.insert(newRule, newPart)
                            end
                        else
                            table.insert(newRule, rulePart)
                        end
                    end

                    changedRules[name] = newRule
                end

                for k, v in pairs(changedRules) do
                    self.rules[k] = v
                end

                self.rules[ruleName] = nil

                local additions = {} -- set
                local deletions = {} -- set
                for _, edges in pairs(self.edgesPerNode) do
                    for _, edge in ipairs(edges) do
                        if (not deletions[edge]) and (edge[1] == ruleName) then
                            -- inline
                            for _, oldRulePart in ipairs(oldRule) do
                                local oldRulePartReplacement = {oldRulePart[1]}
                                for i, v in ipairs(oldRulePart) do
                                    if i ~= 1 then
                                        -- v is a parameter index, cause first value is edge name
                                        oldRulePartReplacement[i] = edge[v + 1]
                                    end
                                end

                                additions[oldRulePartReplacement] = true
                            end

                            deletions[edge] = true
                        end
                    end
                end

                -- todo: should make a function out of this, for bulk addition/deletion
                -- delete edges (https://stackoverflow.com/a/53038524/12164411)
                for _, edges in pairs(self.edgesPerNode) do
                    local shiftingPosition = 1
                    local numberOfEdges = #edges
                    for index=1,numberOfEdges do
                        local currentEdge = edges[index]
                        if deletions[currentEdge] then
                            edges[index] = nil
                            -- even if all occurrences have been removed, iteration needs to continue to relocate left elements
                        else
                            -- the edge should be kept and is moved to the shiftingPosition
                            if shiftingPosition ~= index then
                                -- but only if the edge is not already there
                                edges[shiftingPosition] = currentEdge
                                edges[index] = nil
                            end

                            shiftingPosition = shiftingPosition + 1
                        end
                    end
                end

                -- add edges
                for edge, _ in pairs(additions) do
                    self:addEdge(helpers.portableUnpack(edge))
                end

                didChange = true
                break -- for call amount recalculation (is this necessary?)
            end
        end
    until not didChange
end

function Graph:pruneGeneral()
    repeat
        local didChange = false
        local ruleCallAmounts = self:_calculateGeneralRuleCallAmounts()
        for _, triple in ipairs(ruleCallAmounts) do -- i dont think I can break iteration. What if next rule has slightly more calls but is 10x in size?
            local ruleName, callAmount, paramUses = triple.ruleName, triple.callAmount, triple.paramUses
            local oldRule = self.rules[ruleName]
            local p = 1 -- amount of params
            local q = 0 -- amount of param uses
            local e = 0 -- amount of edges
            for partNumber, rulePart in ipairs(oldRule) do
                e = e + 1
                for i, v in ipairs(rulePart) do
                    if i ~= 1 then -- otherwise it would be counted twice (as edge and as param use)
                        q = q + 1
                    end

                    if (partNumber ~= 1) or (i ~= 1) then -- this excludes first value of first edge (which is only one that is no param)
                        p = math.max(v, p)
                    end
                end
            end

            if callAmount < math.ceil((1 + q + e) / (q + e - p - 1)) and (paramUses == 0) then
                -- rule should be inlined -> i need to find every call todo: maybe i could combine this with the call amount calculation for better performance?
                local changedRules = {} -- set
                for name, rule in pairs(self.rules) do
                    local newRule = {}
                    if rule[1][1] == ruleName then
                        -- inline here
                        for oldPartNumber, oldRulePart in ipairs(oldRule) do
                            local newPart = {}
                            if oldPartNumber == 1 then
                                newPart[1] = oldRulePart[1]
                            end

                            for i, v in ipairs(oldRulePart) do
                                if newPart[i] == nil then
                                    -- this only happens if oldPartNumber and i are not 1
                                    newPart[i] = rule[1][v + 1]
                                end
                            end

                            table.insert(newRule, newPart)
                        end

                        for i=2,#rule do
                            table.insert(newRule, rule[i])
                        end
                    else
                        newRule = rule
                    end

                    changedRules[name] = newRule
                end

                for k, v in pairs(changedRules) do
                    self.rules[k] = v
                end

                self.rules[ruleName] = nil

                local additions = {} -- set
                local deletions = {} -- set
                for _, edges in pairs(self.edgesPerNode) do
                    for _, edge in ipairs(edges) do
                        if (not deletions[edge]) and (edge[1] == ruleName) then
                            -- inline
                            for edgeNumber, edgePart in ipairs(oldRule) do
                                local edgePartReplacement = {}
                                if edgeNumber == 1 then
                                    edgePartReplacement[1] = edgePart[1]
                                end

                                for i, v in ipairs(edgePart) do
                                    if edgePartReplacement[i] == nil then
                                        -- this only happens if edgeNumber and i are not 1
                                        edgePartReplacement[i] = edge[v + 1]
                                    end
                                end

                                additions[edgePartReplacement] = true
                            end

                            deletions[edge] = true
                        end
                    end
                end

                -- delete edges (https://stackoverflow.com/a/53038524/12164411)
                for _, edges in pairs(self.edgesPerNode) do
                    local shiftingPosition = 1
                    local numberOfEdges = #edges
                    for index=1,numberOfEdges do
                        local currentEdge = edges[index]
                        if deletions[currentEdge] then
                            edges[index] = nil
                            -- even if all occurrences have been removed, iteration needs to continue to relocate left elements
                        else
                            -- the edge should be kept and is moved to the shiftingPosition
                            if shiftingPosition ~= index then
                                -- but only if the edge is not already there
                                edges[shiftingPosition] = currentEdge
                                edges[index] = nil
                            end

                            shiftingPosition = shiftingPosition + 1
                        end
                    end
                end

                -- add edges
                for edge, _ in pairs(additions) do
                    -- self:addEdge(helpers.portableUnpack(edge))
                    -- fixme: quick hack for above statement because some edge parts are not a node
                    local addedAlready = {} -- set
                    local index = 2
                    while index <= #edge do
                        local node = edge[index]
                        if (self.edgesPerNode[node] ~= nil) and (not addedAlready[node]) then
                            table.insert(self.edgesPerNode[node], edge)
                            addedAlready[node] = true
                        end

                        index = index + 1
                    end
                end

                didChange = true
                break -- for call amount recalculation (is this necessary?)
            end
        end
    until not didChange
end

function Graph:compress(minOccs)
    self:replaceDigrams(minOccs)
    self:prune()
end

function Graph:compressGeneral(minOccs)
    self:replaceGeneralDigrams(minOccs)
    self:pruneGeneral()
end

function Graph:decompress()
    local additions = {} -- set
    local deletions = {} -- set
    for _, edges in pairs(self.edgesPerNode) do
        for _, edge in ipairs(edges) do
            if (not deletions[edge]) and (self.rules[edge[1]]) then
                -- edge is call of a rule
                local rule = self.rules[edge[1]]
                for _, edgePart in ipairs(rule) do
                    local edgePartReplacement = {edgePart[1]}
                    for i, v in ipairs(edgePart) do
                        if i ~= 1 then
                            -- v is a parameter index, cause first value is edge name
                            edgePartReplacement[i] = edge[v + 1]
                        end
                    end

                    additions[edgePartReplacement] = true
                end

                deletions[edge] = true
            end
        end
    end

    -- all remaining rule callings are now in additions

    -- delete edges (https://stackoverflow.com/a/53038524/12164411)
    for _, edges in pairs(self.edgesPerNode) do
        local shiftingPosition = 1
        local numberOfEdges = #edges
        for index=1,numberOfEdges do
            local currentEdge = edges[index]
            if deletions[currentEdge] then
                edges[index] = nil
                -- even if all occurrences have been removed, iteration needs to continue to relocate left elements
            else
                -- the edge should be kept and is moved to the shiftingPosition
                if shiftingPosition ~= index then
                    -- but only if the edge is not already there
                    edges[shiftingPosition] = currentEdge
                    edges[index] = nil
                end

                shiftingPosition = shiftingPosition + 1
            end
        end
    end

    -- this code is some kind of duplicate, but should be a fairly speedy approach
    -- todo: can I sort out edges who arent a rule and only work with the remaining rule calls? Maybe even better: Go in depth instead of width (fully resolve one edge at a time)
    repeat
        local didChange = false
        local tempAdditions = {}
        for edge, _ in pairs(additions) do
            if self.rules[edge[1]] then
                -- edge is call of a rule
                local rule = self.rules[edge[1]]
                for _, edgePart in ipairs(rule) do
                    local edgePartReplacement = {edgePart[1]}
                    for i, v in ipairs(edgePart) do
                        if i ~= 1 then
                            -- v is a parameter index, cause first value is edge name
                            edgePartReplacement[i] = edge[v + 1]
                        end
                    end

                    tempAdditions[edgePartReplacement] = true
                end

                didChange = true
            else
                tempAdditions[edge] = true
            end
        end

        additions = tempAdditions
    until didChange == false

    -- add edges
    for edge, _ in pairs(additions) do
        self:addEdge(helpers.portableUnpack(edge))
    end

    -- delete rules
    self.rules = {}
end

function Graph:decompressGeneral()
    local additions = {} -- set
    local deletions = {} -- set
    for _, edges in pairs(self.edgesPerNode) do
        for _, edge in ipairs(edges) do
            if (not deletions[edge]) and (self.rules[edge[1]]) then
                -- edge is call of a rule
                local rule = self.rules[edge[1]]
                for edgeNumber, edgePart in ipairs(rule) do
                    local edgePartReplacement = {}
                    if edgeNumber == 1 then
                        edgePartReplacement[1] = edgePart[1]
                    end

                    for i, v in ipairs(edgePart) do
                        if edgePartReplacement[i] == nil then
                            -- this only happens if edgeNumber and i are not 1
                            edgePartReplacement[i] = edge[v + 1]
                        end
                    end

                    additions[edgePartReplacement] = true
                end

                deletions[edge] = true
            end
        end
    end

    -- all remaining rule callings are now in additions

    -- delete edges (https://stackoverflow.com/a/53038524/12164411)
    for _, edges in pairs(self.edgesPerNode) do
        local shiftingPosition = 1
        local numberOfEdges = #edges
        for index=1,numberOfEdges do
            local currentEdge = edges[index]
            if deletions[currentEdge] then
                edges[index] = nil
                -- even if all occurrences have been removed, iteration needs to continue to relocate left elements
            else
                -- the edge should be kept and is moved to the shiftingPosition
                if shiftingPosition ~= index then
                    -- but only if the edge is not already there
                    edges[shiftingPosition] = currentEdge
                    edges[index] = nil
                end

                shiftingPosition = shiftingPosition + 1
            end
        end
    end

    -- this code is some kind of duplicate, but should be a fairly speedy approach
    -- todo: can I sort out edges who arent a rule and only work with the remaining rule calls? Maybe even better: Go in depth instead of width (fully resolve on edge at a time)
    repeat
        local didChange = false
        local tempAdditions = {}
        for edge, _ in pairs(additions) do
            if self.rules[edge[1]] then
                -- edge is call of a rule
                local rule = self.rules[edge[1]]
                for edgeNumber, edgePart in ipairs(rule) do
                    local edgePartReplacement = {}
                    if edgeNumber == 1 then
                        edgePartReplacement[1] = edgePart[1]
                    end

                    for i, v in ipairs(edgePart) do
                        if edgePartReplacement[i] == nil then
                            -- this only happens if edgeNumber and i are not 1
                            edgePartReplacement[i] = edge[v + 1]
                        end
                    end

                    tempAdditions[edgePartReplacement] = true
                end

                didChange = true
            else
                tempAdditions[edge] = true
            end
        end

        additions = tempAdditions
    until didChange == false

    -- add edges
    for edge, _ in pairs(additions) do
        -- self:addEdge(helpers.portableUnpack(edge))
        -- fixme: quick hack for above statement because some edge parts are not a node
        local addedAlready = {} -- set
        local index = 2
        while index <= #edge do
            local node = edge[index]
            if (self.edgesPerNode[node] ~= nil) and (not addedAlready[node]) then
                table.insert(self.edgesPerNode[node], edge)
                addedAlready[node] = true
            end

            index = index + 1
        end
    end

    -- delete rules
    self.rules = {}
end

function Graph:saveToFile(fileName)
    local file = assert(io.open(fileName, "w+"))
    local alreadySaved = {} -- table
    for name, rule in pairs(self.rules) do
        local edgeStrings = {}
        for i, edge in ipairs(rule) do
            edgeStrings[i] = table.concat(edge, "\t")
        end

        file:write(name, "\t", table.concat(edgeStrings, "\t\t"), "\n")
    end

    file:write("Base:", "\n")
    for _, edges in pairs(self.edgesPerNode) do
        for _, edge in ipairs(edges) do
            if alreadySaved[edge] == nil then
                file:write(table.concat(edge, "\t"), "\n")
                alreadySaved[edge] = true
            end
        end
    end

    file:close()
end

function Graph:getSize() -- fixme: __len could be used, but does not work in LuaJIT
    local size = 0
    local haveSeen = {} -- set
    for _, edges in pairs(self.edgesPerNode) do
        for _, edge in ipairs(edges) do
            if not haveSeen[edge] then
                size = size + #edge
                haveSeen[edge] = true
            end
        end
    end

    for _, rule in pairs(self.rules) do
        size = size + 1 -- +1 because of rule name
        for _, edge in ipairs(rule) do
            size = size + #edge
        end
    end

    return size
end

function Graph:__eq(other)
    if getmetatable(self) == getmetatable(other) then
        for node, edges in pairs(self.edgesPerNode) do
            if (other.edgesPerNode[node] == nil) or (#edges ~= #other.edgesPerNode[node]) then
                return false
            end

            local alreadyUsedOtherEdges = {} -- set
            for _, edge in ipairs(edges) do
                -- find corresponding edge in other
                local otherEdge = nil
                for _, potentialOtherEdge in ipairs(other.edgesPerNode[node]) do
                    if not alreadyUsedOtherEdges[potentialOtherEdge] then
                        local edgeLength = #edge
                        local doesFit = true
                        for i=1,edgeLength+1 do
                            if potentialOtherEdge[i] ~= edge[i] then
                                doesFit = false
                                break
                            end
                        end

                        if doesFit then
                            otherEdge = potentialOtherEdge
                            break
                        end
                    end
                end

                if otherEdge then
                    alreadyUsedOtherEdges[otherEdge] = true
                else
                    return false
                end
            end
        end

        for node, _ in pairs(other.edgesPerNode) do
            if (self.edgesPerNode[node] == nil) then
                return false
            end
        end

        for ruleName, rule in pairs(self.rules) do
            if (other.rules[ruleName] == nil) or (#rule ~= #other.rules[ruleName]) then
                return false
            end

            for edgeIndex, edge in ipairs(rule) do
                local edgeLength = #edge
                for i=1,edgeLength+1 do
                    if edge[i] ~= other.rules[ruleName][edgeIndex][i] then
                        return false
                    end
                end
            end
        end

        for ruleName, _ in pairs(other.rules) do
            if (self.rules[ruleName] == nil) then
                return false
            end
        end

        return true
    end

    return false
end

function Graph:__tostring() -- todo: how to display empty graphs and empty nodes (no edges)?
    -- todo: rules to string as well
    local result = "Graph object:"
    for node, edges in pairs(self.edgesPerNode) do
        local edgeStrings = {} -- array
        for i, edge in ipairs(edges) do
            edgeStrings[i] = string.format("%s(%s)", edge[1], table.concat(edge, ", ", 2))
        end

        result = string.format("%s\n%s: %s", result, node, table.concat(edgeStrings, ", "))
    end

    return result
end