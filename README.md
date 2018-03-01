# CLI

CLI.jl is a library for automatically generating command line interfaces from 
absolutely Julia object. Is is highly inspired by [python-fire](https://github.com/google/python-fire). But thanks to Julia's powerful metaprogramming, we are able to do this in a much easier way. CLI.jl make use of Julia's metaprogramming and multiple dispatch feature.

**warning** It only supports *nix systems at the moment. I have not tested it
for **Windows**. Julia v0.6+ is required.

## Features

- modular implementation
- compile to binary with [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl)

# Installation

```julia
Pkg.clone(git@github.com:Roger-luo/CLI.jl.git)
```

# Basic Usage

You can call `@command` on julia functions.

```julia
#demo.jl

using CLI

@command """
this is a demo CLI
"""


"""
add up
"""
@command function add(x::Int, y::Int; extra::Int=1)
    x + y + extra
end

main()
```

```shell
> demo.jl --help
[SYNOPSIS]
	demo2.jl [-h,--help] [-v,--version] <command>
[DESCRIPTION]
	this is a demo CLI

[COMMANDS]
	add
	  add up

```

# Advanced

You can create subcommands using Julia's modules. And then you can compile it
to a binary application by [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl)

## Use subcommands and Compile to Binary

```julia
# demo.jl
module demo
using CLI

@command """
this is a demo CLI
"""

module math
using CLI

@command """
math calculations
"""

"""
add up
"""
@command function add(x::Int, y::Int; extra::Int=1)
    x + y + extra
end

"""
multiply two integers
"""
@command mul(x::Int, y::Int) = x * y

end # math

"""
plus two integers
"""
@command function plus(x::Int, y::Int)
    x + y    
end

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    main()
end

end
```

then open a Julia REPL, type
```julia-repl
> julia using PackageCompiler; build_executable("demo.jl")
```

you will get an binary `demo`, simply copy it to where you want and use it.
This will reduce your CLI start time significantly. Enjoy!

## Advanced Customize

**CLI.jl** offers several types to store your CLI application. You can directly
use them to build a CLI application.

```julia
using CLI

add(x::Int, y::Int) = x + y
mul(x::Int, y::Int) = x * y

leaf1 = LeafCommand(:add, add, Signature([Int, Int], []))
leaf2 = LeafCommand(:mul, mul, Signature([Int, Int], []))
node = NodeCommand("math", [leaf1, leaf2])

maincmd = MainCommand("cal", [], [node])

stream = ARGStream(ARGS)
resolve(stream, maincmd; debug=false)
```

## CLI Design Guidance

**CLI.jl** accepts most CLI design syntax from [GNU CLI Standard](https://www.gnu.org/prep/standards/standards.html#Command_002dLine-Interfaces), [IEEE](http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html) and other \*nix external programs, e.g `git`, `ls`, etc.

## Future Plans

- [ ] support `@command` for arbitrary Julia objects
- [ ] further performance improvements (CLI start time)


## Author

Roger Luo