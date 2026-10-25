require("Graph")

local helpCommands = {["help"]=true, ["h"]=true}
local compressCommands = {["compress"]=true, ["c"]=true}
local decompressCommands = {["decompress"]=true, ["d"]=true}
local convertCommands = {["convert"]=true}
local testCommands = {["test"]=true, ["t"]=true}
local randomTestCommands = {["randomTest"]=true, ["r"]=true}
local benchmarkCommands = {["benchmark"]=true, ["b"]=true}

if #arg == 0 then
    print('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
else
    if helpCommands[arg[1]] then
        if #arg == 1 then
            print("Please use one of the following options:")
            print()
            print("compress <FILENAME> <METHOD> [OCCURRENCES] --> Compresses file with method")
            print("decompress <FILENAME> <METHOD>             --> Decompresses file with method")
            print("convert <FILENAME>                         --> Converts SNAP graph to valid format")
            print("test <FILENAME> [METHOD] [OCCURRENCES]     --> Tests the specified compression (or both) and returns the files as well as performance statistics")
            print("randomTest <N> <E> <B> <RUNS>              --> Same as test but with both compressions and random graphs with specified properties")
            print("benchmark <N> <E> <B>                      --> Returns runtimes of algorithms with specified random graph")
            print("help                                       --> Shows this help message")
            print()
            print("All parameters in <angle brackets> are mandatory, all parameters in [square brackets] are optional. See below for more information on their meaning.")
            print()
            print("The FILENAME needs to be the path to the graph file.")
            print('The METHOD can only be "old" for the old compression or "new" for the new, general compression.')
            print('The amount of OCCURRENCES overwrite the compression heuristic and make the compression stop when the most frequent digram has less then OCCURRENCES occurrences.')
            print('N is the amount of nodes a random graph will have.')
            print('E is the amount of edges a random graph will have.')
            print('B is the amount of different edge names a random graph will have.')
            print('The RUNS are the amount of random graphs that will be generated with the specified properties. Result is the median over all runs.')
        else
            error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
        end
    elseif compressCommands[arg[1]] then
        if #arg >= 3 then
            local graph = Graph:newFromFile(arg[2])
            local minOccs = tonumber(arg[4]) or nil
            if arg[3] == "old" then
                graph:compress(minOccs)
                local newName, _ = arg[2]:gsub("%..-$", "Comp.grph")
                graph:saveToFile(newName)
            elseif arg[3] == "new" then
                graph:compressGeneral(minOccs)
                local newName, _ = arg[2]:gsub("%..-$", "GeneralComp.grph")
                graph:saveToFile(newName)
            else
                error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
            end
        else
            error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
        end
    elseif decompressCommands[arg[1]] then
        if #arg == 3 then
            local graph = Graph:newFromFile(arg[2])
            if arg[3] == "old" then
                graph:decompress()
                local newName, _ = arg[2]:gsub("%..-$", "Decomp.grph")
                graph:saveToFile(newName)
            elseif arg[3] == "new" then
                graph:decompressGeneral()
                local newName, _ = arg[2]:gsub("%..-$", "GeneralDecomp.grph")
                graph:saveToFile(newName)
            else
                error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
            end
        else
            error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
        end
    elseif convertCommands[arg[1]] then
        if #arg == 2 then
            arg = {arg[2]} -- create arguments for snapConverter file
            dofile("snapConverter.lua")
        else
            error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
        end
    elseif testCommands[arg[1]] then
        if  #arg >= 2 then
            local method = nil
            local minOccs = nil
            if #arg == 4 then
                method = arg[3]
                minOccs = tonumber(arg[4])
                if minOccs == nil then -- could be nil if arg[4] was a string
                    error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
                end
            elseif #arg == 3 then
                if arg[3] == "old" or arg[3] == "new" then
                    method = arg[3]
                else
                    minOccs = tonumber(arg[3])
                    if minOccs == nil then -- could be nil if arg[3] was a string
                        error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
                    end
                end
            end

            arg = {arg[2], method, minOccs} -- create arguments for testbench file
            dofile("testbench.lua")
        else
            error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
        end
    elseif randomTestCommands[arg[1]] then
        if #arg == 5 then
            arg = {arg[2], arg[3], arg[4], arg[5]} -- create arguments for randomTestbench file
            dofile("randomTestbench.lua")
        else
            error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
        end
    elseif benchmarkCommands[arg[1]] then
        if #arg == 4 then
            arg = {arg[2], arg[3], arg[4]} -- create arguments for benchmark file
            dofile("benchmark.lua")
        else
            error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
        end
    else
        error('Please enter a valid set of arguments. Use argument "help" for a small user-guide.')
    end
end