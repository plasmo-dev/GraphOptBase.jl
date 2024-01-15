module GraphOptBase

using DataStructures
using Graphs
import Base: ==,

include("hypergraph.jl")

include("bipartite.jl")

end
