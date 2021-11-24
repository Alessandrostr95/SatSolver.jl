# SatSolver.jl
Yet another Sat Solver, but in Julia

## Installation
The package is available in the official General registry, and therefore can be downloaded directly from the julia package manager.
``` Julia
julia> ]
(@v1.6) pkg> add SatSolver
```
or
``` Julia
julia> import Pkg; Pkg.add("SatSolver")
```

## Description
This is a package completely written in Julia which solves the satisfiability problem for formulas in [CNF](https://en.wikipedia.org/wiki/Conjunctive_normal_form) form.

The algorithmic technique used to solve this problem is the intelligent exhaustive search of the solution space, better known as [Backtracking](https://en.wikipedia.org/wiki/Backtracking)

## Representation of Formula
Conventionally, formulas can be expressed with strings in the following format:
- each row represents a clause
- each literal is separated by one (or more) whitespace
- each negated literal is preceded by the symbol ```~```, which represents the logical negation

Example: the logical CNF formula ```(A or not B or not C) and (not D or E or F)``` must be written as
``` Julia
formula = """
A ~B ~C
~D E F
"""
```

## Initialize an instance of SAT
Given a string representing a sat formula according to the previous description, we can instantiate an instance of sat as follow
``` Julia
I::SatSolver.Instance = SatSolver.parseInstance(formula)
```
We can also specify the path to a file that contains the string representation of a formula
``` Julia
I::SatSolver.Instance = SatSolver.parseInstanceFromFile("path/to/file.txt")
```

## Solve an instance
Function ```sat``` determines if the given instance is satisfiable, and returns the set of assignments that satisfy the instance, ```false``` otherwise.
``` Julia
julia> formula = """
       A ~B ~C
       ~D E F
       """;

julia> I = parseInstance(formula);

julia> sat(I)
Dict{String, Bool} with 2 entries:
  "B" => 0
  "D" => 0
  
julia> formula = """
       A
       ~A
       """;
       
julia> J = parseInstance(formula);

julia> sat(J)
false
```

We can also call the funcion ```isSatisfiable``` to determine if a given instance is satisfiable or not.
``` Julia
julia> isSatisfiable(I)
true

julia> isSatisfiable(J)
false
```

## Visualize
Function `printInstance` prints a human readable representation of the logical formula
``` Julia
julia> printInstance(I)
(A ~B ~C) (~D E F)
```

Given an assignment that satisfies an instance, a "pretty" representation of that assignment can be printed on the screen with functions `printSolutionTable` and `printRawTable`
``` Julia
julia> solution = sat(I);

julia> printSolutionTable(I, solution)
┌──────────┬───────┐
│ Variable │ Value │
├──────────┼───────┤
│        B │ false │
│        A │   Any │
│        C │   Any │
│        D │ false │
│        E │   Any │
│        F │   Any │
└──────────┴───────┘

julia> printRawTable(I, solution)
B : false
A : Any
C : Any
D : false
E : Any
F : Any
```
The `Any` value indicates that any interpretation (true or false) can be given to the respective variable.

-----
## TODO list
- [x] write simple documentation
- [ ] write exhaustive documentation
- [ ] test the correctness
