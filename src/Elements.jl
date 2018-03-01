# Command Line Components
import Base: show
export AbstractOption, Option, ShortOption

"""
    AbstractOption{T}
"""
abstract type AbstractOption{T} end

isoption(s::AbstractString) = startswith(s, "-")
islong(s::AbstractString) = startswith(s, "--")
isoption(::Void) = false
islong(::Void) = false

import Base: ==, in, parse

function in(item::Union{AbstractString, Char}, collection::Vector{AbstractOption})
    for each in collection
        if item == each
            return true
        end
    end
    return false
end

struct Option{T} <: AbstractOption{T}
    name::String
    key::Symbol
    doc::String
end

Option(::Type{T}, name::String, key::Symbol, doc::String="") where T =
    Option{T}(name, key, doc)
Option(::Type{T}, key::Symbol, doc::String="") where T =
    Option(T, string(key), key, doc)

Option(name::String, key::Symbol, doc::String="") =
    Option(Bool, name, key, doc)
Option(key::Symbol, doc::String="") = Option(Bool, key, doc)

optionstring(op::Option{T}) where T = "--$(op.name)[=$(T)]"
optionstring(op::Option{Bool}) = "--$(op.name)"

==(s::Char, op::Option) = false
==(s::AbstractString, op::Option) = (s == op.name) || (s == "--"*op.name)

function show(io::IO, op::Option{T}) where T
    print(io, "--$(op.name)[=$(T)]")
    print(io, "\t$(op.doc)")
end

function show(io::IO, op::Option{Bool})
    print(io, "--$(op.name)")
    print(io, "\t$(op.doc)")
end

"""
    ShortOption{T} <: AbstractOption{T}

Option with Shorthand. e.g option (flag) `help`
can be declared by following commands.

```shell
> cmd -h
> cmd --help
```
"""
struct ShortOption{T} <: AbstractOption{T}
    short::Char
    long::String
    key::Symbol
    doc::String
end

ShortOption(::Type{T}, short::Char, long::String, key::Symbol, doc::String="") where T = 
    ShortOption{T}(short, long, key, doc)
ShortOption(::Type{T}, long::String, key::Symbol, doc::String="") where T = 
    ShortOption(T, long[1], long, key, doc)
ShortOption(::Type{T}, key::Symbol, doc::String="") where T =
    ShortOption(T, string(key), key, doc)

ShortOption(short::Char, long::String, key::Symbol, doc::String="") =
    ShortOption(Bool, short, long, key, doc)
ShortOption(long::String, key::Symbol, doc::String="") =
    ShortOption(long[1], long, key, doc)
ShortOption(key::Symbol, doc::String="") =
    ShortOption(string(key), key, doc)

optionstring(op::ShortOption{T}) where T = "-$(op.short)[$(T)],--$(op.long)[=$(T)]"
optionstring(op::ShortOption{Bool}) = "-$(op.short),--$(op.long)"

==(s::Char, op::ShortOption) = (s == op.short)
==(s::AbstractString, op::ShortOption) = 
    length(s) == 1? s[1] == op : ((s == op.long) || (s == "--$(op.long)")) || (s == "-$(op.short)")

function show(io::IO, op::ShortOption{T}) where T
    print(io, "-$(op.short)[$(T)],--$(op.long)[=$(T)]")
    print(io, "\t$(op.doc)")
end

function show(io::IO, op::ShortOption{Bool})
    print(io, "-$(op.short),--$(op.long)")
    print(io, "\t$(op.doc)")
end

# Preserved Options
const help = ShortOption(:help, "help information")
const version = ShortOption(:version, "version information")

# Signature
export Signature

struct Signature
    args::Vector{DataType}
    options::Vector{AbstractOption}
    doc::String
end

Signature(args::Vector{DataType}, options::Vector) =
    Signature(args, [options..., help], "\tNo Documents")

function show(io::IO, op::Signature)
    if length(op.args) > 0
        println("[arguments]:")
        println(io, "$(op.doc)")
    end

    println("[options]:")
    if length(op.options) > 0
        for each in op.options
            print(io, "  ")
            println(io, each)
        end
    end
end


# Parsers
"""
--flag is the shorthands for --flag=true
"""
function parse(val::AbstractString, opt::AbstractOption{Bool})
    val == "" && return opt.key, true
    return opt.key, parse(Bool, val)
end

function parse(val::AbstractString, opt::AbstractOption{T}) where {T <: Union{Integer, AbstractFloat}}
    return opt.key, parse(T, val)
end

function parse(val::AbstractString, opt::AbstractOption{T}) where {T <: AbstractString}
    return opt.key, T(val)
end

function parse(val::AbstractString, opt::AbstractOption{T}) where {T}
    value = try
        eval(parse(val))
    catch e
        throw(CLIError("Invalid Argument: $val"))
    end

    if !isa(value, T)
        throw(CLIArgError(T, typeof(value)))
    end
    return opt.key, value
end