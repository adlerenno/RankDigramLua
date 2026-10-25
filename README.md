# RandDigram-RePair

This implementation is written in Lua 5.4.6 and compatible with LuaJIT 2.1.0-beta3. The latter is recommended for
running this program, especially when working with big graphs.

### Files

The following table gives an overview over the files and their use:

| Filename        | Purpose                                                                                                                               |
|-----------------|---------------------------------------------------------------------------------------------------------------------------------------|
| helpers         | Contains small functions that are used throughout the project                                                                         |
| snapConverter   | Converts graphs from the SNAP database to the format used in this project                                                             |
| testbench       | Compresses the specified graph with both versions and returns the compressed graphs as well as the runtimes and compression strengths |
| randomTestbench | Same as `testbench`, but generates and uses random graphs with the specified parameters                                               |
| benchmark       | Analyses the runtimes of the implemented algorithms with random graphs                                                                |
| Graph           | Specifies the graph class an implements the compression                                                                               |
| main            | Provides all functionality trough the command line                                                                                    |

### Graph format

In order for the program to interpret a given graph correctly, a few rules must be met by the file that contains the
graph. Firstly, the graph needs to be in a plain text file (the file extension doesn't matter, but all graphs generated
by this program use `.grph`) and every line should contain exactly one rule of the graph that follows the following
format:
```text
RULENAME    EDGENAME_1  NODE_1  NODE_2      EDGENAME_2  NODE_1  NODE_2
```
The delimiter between two values is a single tab character `\t` while edges are seperated with two tab characters
`\t\t`. After all rules have been specified, the file should contain the following line:
```text
Base:
```
After this line, the edges of the graph can be specified in a format similar to the rules:
```text
EDGENAME    NODE_1  NODE_2
```
The delimiter is a single tab character `\t` and more nodes can be added if needed (same goes for the node and edge
amounts in the rule format). The program will ignore empty lines and lines beginning with a `#`, which can be useful for
comments. All nodes need to be positive integers.

### Usage

In order to interact with the program, run the `main.lua` file and pass a set of valid arguments. For a list of valid
arguments and other tips, please run `lua main.lua help` or `luajit main.lua help`.
