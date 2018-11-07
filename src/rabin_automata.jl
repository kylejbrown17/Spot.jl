#= 
From the spot documentation: 
"An ω-automaton can be defined as a labeled directed graph, plus an initial state and an acceptance condition. "
=#

"""
    DeterministicRabinAutomata
Datastructure representing a deterministic Rabin Automata. It is parameterized by the state type Q.
"""
struct DeterministicRabinAutomata <: AbstractAutomata
    initial_state::Int64
    states::AbstractVector{Int64}
    transition::MetaGraph{Int64}
    APs::Vector{Symbol}
    fin_set::Set{Int64}
    inf_set::Set{Int64}
end

# extract a Rabin Automata from an LTL formula using Spot.jl
function DeterministicRabinAutomata(ltl::AbstractString, 
                                    translator::LTLTranslator = LTLTranslator(deterministic=true, generic=true, state_based_acceptance=true))
    aut = SpotAutomata(translate(ltl, translator))
    dra = to_generalized_rabin(aut)
    dra = spot.split_edges(dra)
    @assert is_deterministic(dra)
    states = 1:num_states(dra)
    initial_state = get_initial_state_number(dra) 
    APs = atomic_propositions(dra)
    edges, labels = get_edges_labels(dra)
    sdg = SimpleDiGraph(num_states(dra))
    for e in edges
        add_edge!(sdg, e)
    end
    transition = MetaGraph(sdg)
    conditions = label_to_array.(labels)
    conditions = broadcast(x -> tuple(x...), conditions)
    for (e, l) in zip(edges, conditions)
        set_prop!(mg, Edge(e[1], e[2]), :cond, l)
    end
    inf_set, fin_set = parse_inf_fin_sets(dra)
    return DeterministicRabinAutomata(initial_state, states, transition, APs, fin_set, inf_set)
end

num_states(aut::DeterministicRabinAutomata) = length(aut.states)

get_init_state_number(aut::DeterministicRabinAutomata) = aut.initial_state

