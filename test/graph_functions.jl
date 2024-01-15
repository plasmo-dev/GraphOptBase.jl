module TestGraphFunctions

import GraphOptBase as GOB
using Graphs
using SparseArrays
using Test

function test_hypergraph()

    hyper = GOB.HyperGraph()
    Graphs.add_vertex!(hyper)
    Graphs.add_vertex!(hyper)
    Graphs.add_vertex!(hyper)
    Graphs.add_vertex!(hyper)
    Graphs.add_vertex!(hyper)
    Graphs.add_vertex!(hyper)
    @test Graphs.vertices(hyper) == [1, 2, 3, 4, 5, 6]
    @test length(hyper.vertices) == 6

    Graphs.add_edge!(hyper, 1, 2, 3)
    Graphs.add_edge!(hyper, 1, 2)
    Graphs.add_edge!(hyper, 4, 1, 3)
    Graphs.add_edge!(hyper, 4, 5, 6)
    @test length(hyper.hyperedge_map) == 4
    @test hyper.hyperedge_map[1] == GOB.HyperEdge(1, 2, 3)
    @test hyper.hyperedge_map[2] == GOB.HyperEdge(1, 2)
    @test hyper.hyperedge_map[3] == GOB.HyperEdge(1, 3, 4)
    @test collect(Graphs.edges(hyper)) == [1, 2, 3, 4]

    e1 = GOB.get_hyperedge(hyper, 1)
    e2 = GOB.get_hyperedge(hyper, 2)
    e3 = GOB.get_hyperedge(hyper, 3)
    @test_throws Exception Base.reverse(e1)
    @test Graphs.vertices(e1) == Set([1, 2, 3])
    @test Graphs.vertices(e2) == Set([1, 2])
    @test Graphs.vertices(e3) == Set([1, 3, 4])
    @test Base.getindex(hyper, e1) == 1

    @test Graphs.edgetype(hyper) == GOB.HyperEdge
    @test Graphs.has_edge(hyper, e1) == true
    @test Graphs.has_edge(hyper, Set([1, 2, 3])) == true
    @test Graphs.has_vertex(hyper, 1) == true
    @test Graphs.has_vertex(hyper, 10) == false
    @test Graphs.is_directed(hyper) == false
    @test Graphs.ne(hyper) == 4
    @test Graphs.nv(hyper) == 6
    @test Graphs.degree(hyper, 1) == 3
    @test Graphs.all_neighbors(hyper, 1) == [2, 3, 4]

    #4 vertices are connected by 3 hyperedges
    A = Graphs.incidence_matrix(hyper)
    @test size(A) == (6, 4)
    @test SparseArrays.nnz(A) == 11

    B = Graphs.adjacency_matrix(hyper)
    @test SparseArrays.nnz(B) == 16

    @test SparseArrays.sparse(hyper) == A

    @test GOB.incident_edges(hyper, 1) ==
        [GOB.HyperEdge(1, 2, 3), GOB.HyperEdge(1, 2), GOB.HyperEdge(1, 3, 4)]

    @test GOB.induced_edges(hyper, [1, 2, 3]) ==
        [GOB.HyperEdge(1, 2, 3), GOB.HyperEdge(1, 2)]

    @test GOB.incident_edges(hyper, [1, 2]) ==
        [GOB.HyperEdge(1, 2, 3), GOB.HyperEdge(1, 3, 4)]

    partition_vector = [[1, 2, 3], [4, 5, 6]]
    p, cross = GOB.identify_edges(hyper, partition_vector)
    @test p ==
        [[GOB.HyperEdge(1, 2, 3), GOB.HyperEdge(1, 2)], [GOB.HyperEdge(4, 5, 6)]]
    @test cross == GOB.HyperEdge[GOB.HyperEdge(1, 3, 4)]
    @test GOB.induced_elements(hyper, partition_vector) == partition_vector

    hedges = collect(values(hyper.hyperedge_map))
    partition_vector = [hedges[1:2], hedges[3:4]]
    p, cross = GOB.identify_nodes(hyper, partition_vector)
    @test p == [[2], [4, 5, 6]]
    @test cross == [1, 3]

    @test GOB.neighborhood(hyper, [1, 2], 1) == [1, 2, 3, 4]
    @test GOB.neighborhood(hyper, [1, 2], 2) == [1, 2, 3, 4, 5, 6]

    new_nodes, new_edges = GOB.expand(hyper, [1, 2], 1)
    @test new_nodes == [1, 2, 3, 4]
    @test new_edges == hedges[1:3]

    @test_throws Exception Graphs.rem_edge!(hyper, e1)
    @test_throws Exception Graphs.rem_vertex!(hyper, 1)
end

function test_bipartite_graph()
    graph = GOB.BipartiteGraph()

    #optinodes => vertices
    add_vertex!(graph; bipartite=1)
    add_vertex!(graph; bipartite=1)
    add_vertex!(graph; bipartite=1)
    @test nv(graph) == 3

    add_vertex!(graph; bipartite=2)
    add_vertex!(graph; bipartite=2)
    @test nv(graph) == 5
    @test Graphs.vertices(graph) == Base.OneTo(5)

    @test_throws Exception add_edge!(graph, 1, 2)
    add_edge!(graph, 1, 4)
    add_edge!(graph, 2, 4)
    add_edge!(graph, 2, 5)
    add_edge!(graph, 3, 5)
    @test ne(graph) == 4

    @test length(Graphs.edges(graph)) == 4
    @test Graphs.edgetype(graph) == Graphs.SimpleGraphs.SimpleEdge{Int64}
    @test Graphs.has_edge(graph, 1, 4) == true
    @test Graphs.has_edge(graph, 1, 2) == false
    @test Graphs.is_directed(graph) == false

    A = Graphs.adjacency_matrix(graph)
    @test length(A) == 6
    @test SparseArrays.nnz(A) == 4

    #nodes [1 and 2 and edge 4], [node 3 and edge 5]
    part_vector = [[1, 2, 4], [3, 5]]
    p, cross = GOB._identify_separators(
        graph, part_vector; cut_selector=Graphs.degree
    )
    @test p == [[1, 4], [3, 5]]
    @test cross == [2]

    part = GOB.induced_elements(graph, part_vector; cut_selector=Graphs.degree)
    @test part == p

    p, cross = GOB._identify_separators(graph, part_vector; cut_selector=:vertex)
    @test p == [[1, 4], [3, 5]]
    @test cross == [2]

    p, cross = GOB._identify_separators(graph, part_vector; cut_selector=:edge)
    @test p == [[1, 2, 4], [3]]
    @test cross == [5]
end

function run_tests()
    for name in names(@__MODULE__; all=true)
        if !startswith("$(name)", "test_")
            continue
        end
        @testset "$(name)" begin
            getfield(@__MODULE__, name)()
        end
    end
end

end

TestGraphFunctions.run_tests()
