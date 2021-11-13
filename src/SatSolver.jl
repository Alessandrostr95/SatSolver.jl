module SatSolver

###### EXPORTS
export Instance,
    parseClause!, parseInstance, parseInstanceFromFile,
    int2variable, clause2string, printInstance, printSolutionTable, printRawTable,
    assign, clauseSatisfied, literalSatisfied,
    simplify, sat, isSatisfiable

###### STRUCTS

"""
    Utility struct for representing a node in the solution search tree.
"""
mutable struct Predecessor
    instance::Any
    variable::String
    value::Bool
    function Predecessor(instance, variable::String, value::Bool)::Predecessor
        return new(instance, variable, value)
    end
end

"""
    Each variable `x` is represented with an integer from `1` to `n`, where `n` is the number of variables.
    Each literal `l` is represented with an integer from `1` to `2n`, where `n` is the number of variables.
    More precisely, the variable `x_1` is represented literal `l_1`, and its negation is represented with the literal `~l_1`.
    Thus, the literal `l` is represented with the integer `2*x` if it is positive, and with the integer `2*x+1` if it is negative.

    Each clause `c` is represented with a list of integers `[l_1, l_2, ..., l_k]`, where `l_i` is a literal in the clause.
    E.g.
    variables = [x_1, x_2, x_3] = [1, 2, 3]
    `c` = (~x_1 or x_2 or ~x_3) = [3, 4, 7]
"""
mutable struct Instance
    variables_table::Dict{String, Int64}
    clauses::Vector{Vector{Int64}}
    father::Union{Predecessor, Nothing}
    function Instance()
        return new(Dict{String, Int64}(), Vector{Vector{Int64}}(), nothing)
    end
end

###### FUNCTIONS

"""
    Function `parseClause!` parses a CNF clause from a string, and adds it to the given instance.
    The string must be in the format `l_1 l_2 ... l_k`, where `l_i` is a literal in the clause.
    E.g.
    `clause` = (~x_1 or x_2 or ~x_3) = [3, 4, 7]
"""
function parseClause!(instance::Instance, clause::AbstractString)
    try
        push!(instance.clauses, parseClause(instance, clause))
    catch
        parseClauseError(clause)
    end
end

"""
    Function `parseClause` parses a CNF clause from a string, and returns the parsed clause.
"""
function parseClause(instance::Instance, clause::AbstractString)::Vector{Int64}
    try
        c = Int64[]
        for l in split(strip(clause), " ")
            variable_name = startswith(l, "~") ? l[2:end] : l
            variable_name ≠ "" &&  begin
                variable_name ∈ keys(instance.variables_table) || begin instance.variables_table[variable_name] = length(instance.variables_table) + 1 end
                push!(c, instance.variables_table[variable_name] << 1 | startswith(l, "~"))
            end 
        end
        return sort(c)
    catch
        parseClauseError(clause)
    end
end

"""
    Utility function `string2clause` parses a CNF clause from a string, according to the set of variables of `instance`.
"""
function string2clause(instance::Instance, s::AbstractString)::Vector{Int64}
    try
        c = Vector{Int64}()
        for l in split(strip(s), " ")
            x::Int64
            if startswith(l, "~")
                x = instance.variables_table[l[2:end]]
                push!(c, 2x + 1)
            else
                x = instance.variables_table[l]
                c.push!(2x)
            end
        end
        return sort(c)
    catch
        parseClauseError(s)
    end
end

"""
    This function parses a CNF instance from a string, and returns the parsed instance.
    The string must be in the format of a CNF instance, where each clause is separated by a newline.
    E.g.
        X Y ~Z\\n
        ~X ~Y\\n
        ~X W ~Z
"""
function parseInstance(s::AbstractString)::Instance
    instance = Instance()
    for c in split(s, "\n")
        if c != ""
            parseClause!(instance, c)
        end
    end
    return instance
end


"""
    This function reads a CNF instance from a file, and returns the parsed instance.
    The file should be in the format of a CNF instance, where each line is a clause.
    A clause is represented with a list of integers `l_1, l_2, ..., l_k`, where `l_i` is a literal in the clause.
    E.g.
        X Y ~Z
        ~X ~Y
        ~X W ~Z
"""
function parseInstanceFromFile(filename::String)::Instance
    try
        return parseInstance(string((read(filename) .|> Char)...))
    catch
        parseInstanceError(filename)
    end
end

"""
    Given an integer `x`, this function returns the literal `l` that is represented by `x`, according to the set of variables of `instance`.
    E.g.
        variables_table = {"X": 1, "Y": 2, "Z": 3, "W": 4}

        l = 2x
        ~l = 2x + 1

        2 -> "X"
        3 -> "~X"
        4 -> "Y"
        5 -> "~Y"
        6 -> "Z"
        7 -> "~Z"
        8 -> "W"
        9 -> "~W" 
"""
function int2variable(instance::Instance, x::Int64)::String
    2 ≤ x ≤ 2*length(instance.variables_table) + 1 || begin
        parseLiteralError("x ∉ [2, ..., 2n + 1], x=$x given.")
    end
    neg = (x & 1) == 1 ? "~" : ""
    return neg * sort([keys(instance.variables_table)...]; by= (k -> instance.variables_table[k]))[x >> 1]  # remove sorting for performance
end

"""
    Given a sequence of integers `xs`, this function returns the sequence of literals `ls` that are represented by `xs`, according to the set of variables of `instance`.
    E.g.
        [1, 2, 3] -> "X ~X Y"
        [4, 5, 6] -> "~Y Z ~Z"
        [1, 3, 7] -> "X ~Z W"
"""
function clause2string(instace::Instance, xs::Vector{Int64})::String
    return join(xs .|> (x -> int2variable(instace, x)), " ")
end

"""
    Function that prints the given instance.
"""
function printInstance(instance::Instance)
    for c in instance.clauses
        print("($(clause2string(instance, c))) ")
    end
    println()
end

"""
    Function that given an assignment `a`, returns only the clauses satisfied by `a`.
    E.g.
        a = {"X": true, "Y": false, "Z": true, "W": false}
        instance = parseInstance("X Y ~Z\\n~X ~Y\\n~X W ~Z")
        sat(instance, a) = [[2, 4, 7], [3, 5]]
"""
function assign(instance::Instance, a::Dict{String, Bool})
    return filter(c -> clauseSatisfied(instance, c, a), instance.clauses)
end

"""
    Function `clauseSatisfied` returns true if the given clause `c` is satisfied by the given assignment `a`.
"""
function clauseSatisfied(instance::Instance, c::Vector{Int64}, a::Dict{String, Bool})::Bool
    return c .|> (x -> literalSatisfied(instance, x, a)) |> iszero |> !
end

"""
    Function `literalSatisfied` returns true if the literal `l` is satisfied by the assignment `a`.
"""
function literalSatisfied(instance::Instance, x::Int64, a::Dict{String, Bool})
    l::String = replace(int2variable(instance, x), "~" => "")
    return (x & 1) == 1 ? !a[l] : a[l]
end

"""
    Function that given a single truth assignment `x = v` returns a new instance, where all clauses satisfied by the assignment are removed.
    Furthermore, the new instance is simplified: all clauses that are satisfied by the assignment are removed, and all clauses that are not satisfied by the assignment are simplified.
    E.g.
        instance = parseInstance("X Y ~Z\\n~X ~Y\\n~X W ~Z")
        simplify(instance, "X", true) = parseInstance("~Y\\nW ~Z")
"""
function simplify(instance::Instance, x::String, v::Bool)::Instance
    new_instance = Instance()
    variable = instance.variables_table[x]

    for c in instance.clauses
        if variable << 1 ∈ c && v == false
            # in the clause, the variable is positive and the value is false
            # so simply remove the variable from the clause
            # removed code : push!(new_instance.clauses, [x for x in c if x ≠ variable])
            parseClause!(new_instance, clause2string(instance, [y for y in c if y >> 1 ≠ variable]))
        elseif variable << 1 | 1 ∈ c && v == true
            # in the clause, the variable is negative and the value is true
            # so simply remove the variable from the clause
            # removed code : push!(new_instance.clauses, [x for x in c if x ≠ variable])
            parseClause!(new_instance, clause2string(instance, [y for y in c if y >> 1 ≠ variable]))
        elseif variable << 1 ∉ c && variable << 1 | 1 ∉ c
            # there is no variable in the clause
            # so simply add the clause to the new instance
            # removed code : push!(new_instance.clauses, c)
            parseClause!(new_instance, clause2string(instance, c))
        end
    end
        # if no previous condition is satisfied, then the clause is satisfied by the assignment
        # so simply ignore (do not add) the clause to the new instance
    return new_instance
end

"""
    Function `sat` determines if the given instance is satisfiable, and returns the set of assignments that satisfy the instance, false otherwise.
    E.g.
        instance = parseInstance("X Y ~Z\\n~X ~Y\\n~X W ~Z")
        sat(instance) = {"X": true, "Y": false, "Z": true, "W": false}
"""
function sat(instance::Instance)::Union{Dict{String, Bool}, Bool}
    S = [instance]

    while !isempty(S)
        # choose a random instance from the set of instances
        P = pop!(S)

        # choose a random variable from the set of variables
        x = first([keys(P.variables_table)...]) # [rand(1:length(P.variables_table))]

        for v in [true, false]
            # assign the variable to the value
            Pᵢ = simplify(P, x, v)
            Pᵢ.father = Predecessor(P, x, v)

            # if the instance is empty, then the assignment is a solution
            if isempty(Pᵢ.clauses)
                return obtainTruthAssignment(Pᵢ)
            # else if the instance has not empty clauses, then add it to the set of instances
            elseif [] ∉ Pᵢ.clauses
                push!(S, Pᵢ)
            end

            # otherwise I'm in the case where the instance has an empty clause, so it has no solution (just ignore it)
        end
    end
    return false 
end

predecessor(I::Instance)::Union{Predecessor,Nothing} = I.father
hasPredecessor(I::Instance)::Bool = predecessor(I) !== nothing

function obtainTruthAssignment(instance::Instance)::Dict{String, Bool}
    solution = Dict{String, Bool}()
    father = predecessor(instance)
    while father !== nothing
        solution[father.variable] = father.value
        father = predecessor(father.instance)
    end
    return solution
end

"""
    Function that given an instance `instance`, returns true if the instance is satisfiable, false otherwise.
"""
isSatisfiable(instance::Instance)::Bool = sat(instance) != false

###### ERRORS
parseClauseError(clause::String) = throw(error("Error while parsing clause: " * clause))
parseInstanceError(filename::String) = throw(error("Error while parsing instance from file: " * filename))
parseLiteralError(msg::String) = throw(error("Error while parsing literal: " * msg))


###### TABLES

import PrettyTables.pretty_table

"""
    Function that prints the solution of the instance `instance` in a pretty table.
"""
function printSolutionTable(instance::Instance, solution::Dict{String, Bool})
    data = Dict{String, Any}()
    for x in keys(instance.variables_table)
        data[x] = x ∈ keys(solution) ? solution[x] : "Any"
    end
    pretty_table(
        hcat([e.first for e in data], [e.second for e in data]);
        header = (["Variable", "Value"]),
        nosubheader = true
        )
end

"""
    Function that prints the solution of the instance `instance` in format `variable` : `value`.
    E.g.
        instance = parseInstance("X Y ~Z\\n~X ~Y\\n~X W ~Z")
        solution = sat(instance)
        printSolution(instance, solution) =
        "
            X : Any
            Y : false
            Z : false
            W : Any
        "
"""
function printRawTable(instance::Instance, solution::Dict{String, Bool})
    for x in keys(instance.variables_table)
        println("$x : $(x ∈ keys(solution) ? solution[x] : "Any")")
    end
end

end # module