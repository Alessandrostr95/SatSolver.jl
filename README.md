# SatSolver.jl
Yet another Sat Solver, but in Julia

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
We can also call the funcion ```isSatisfiable``` to determine if a given instance is satisfiable or not.

-----
## TODO list
- [x] write simple documentation
- [ ] write exhaustive documentation
- [ ] test the correctness
