require("Graph")
require("helpers")

local nodeAmount = tonumber(arg[1])
local edgeAmount = tonumber(arg[2])
local differentEdgeNameAmount = tonumber(arg[3])

local function benchmark(nodes, edges, differentEdgeNames)
    local normalGraph = Graph:newRandom(nodes, edges, differentEdgeNames)

    -- this part is a quick deep copy workaround
    normalGraph:saveToFile("temp.grph")
    local generalGraph = Graph:newFromFile("temp.grph")
    os.remove("temp.grph")

    local stats = {
        normal = {},
        general = {}
    }

    local amountOfNodes, amountOfNodesTime = helpers.smallBenchmark(Graph.getAmountOfNodes, normalGraph)
    amountOfNodes = amountOfNodes[1]
    stats.normal.amountOfNodes = amountOfNodesTime
    stats.general.amountOfNodes = amountOfNodesTime

    local amountOfEdges, amountOfEdgesTime = helpers.smallBenchmark(Graph.getAmountOfEdges, normalGraph)
    amountOfEdges = amountOfEdges[1]
    stats.normal.amountOfNodes = amountOfEdgesTime
    stats.general.amountOfNodes = amountOfEdgesTime

    local adjacencyTypes, adjacencyTypesTime = helpers.smallBenchmark(Graph.calculateAdjacencyTypesPerNode, normalGraph)
    adjacencyTypes = adjacencyTypes[1]
    stats.normal.adjacencyTypes = adjacencyTypesTime

    local adjacencyTypesWithRank, adjacencyTypesWithRankTime = helpers.smallBenchmark(Graph.calculateAdjacencyTypesPerNodeWithRank, generalGraph)
    adjacencyTypesWithRank = adjacencyTypesWithRank[1]
    stats.general.adjacencyTypes = adjacencyTypesWithRankTime

    local digrams, digramsTime = helpers.smallBenchmark(Graph.calculateDigrams, normalGraph)
    digrams = digrams[1]
    stats.normal.digrams = digramsTime

    local generalDigrams, generalDigramsTime = helpers.smallBenchmark(Graph.calculateGeneralDigrams, generalGraph)
    generalDigrams = generalDigrams[1]
    stats.general.digrams = generalDigramsTime

    local rule, ruleTime = helpers.smallBenchmark(Graph.replaceDigram, normalGraph, digrams[1], "A")
    rule = rule[1]
    stats.normal.rule = ruleTime

    local generalRule, generalRuleTime = helpers.smallBenchmark(Graph.replaceGeneralDigram, generalGraph, generalDigrams[1], "A")
    generalRule = generalRule[1]
    stats.general.rule = generalRuleTime

    print("----------------------")
    print(string.format("RandomGraph: Nodes=%i Edges=%i Names=%i", nodes, edges, differentEdgeNames))
    print("Runtimes:")
    print(string.format("           adjacencyTypes     digrams     rule"))
    print(string.format("Normal:    %s             %s      %s", string.format("%.4f", stats.normal.adjacencyTypes), string.format("%.4f", stats.normal.digrams - stats.normal.adjacencyTypes), string.format("%.4f", stats.normal.rule)))
    print(string.format("General:   %s             %s      %s", string.format("%.4f", stats.general.adjacencyTypes), string.format("%.4f", stats.general.digrams - stats.general.adjacencyTypes), string.format("%.4f", stats.general.rule)))
    print("----------------------")
end

benchmark(nodeAmount, edgeAmount, differentEdgeNameAmount)