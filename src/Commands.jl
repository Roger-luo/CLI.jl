import Base: show

# Commands
export AbstractCommand, LeafCommand, NodeCommand, MainCommand

const DocString = Union{String, Markdown.MD}

"""
Abstract type for Commands

## Interface
- `name(cmd)`: returns the name of this cmd.
- `docstring`: returns the docstring
- all subtype of `AbstractCommand` should be callable (like a function).
- overload `show` to support `help`
"""
abstract type AbstractCommand end

"""
    name(cmd) -> String

get a command's name
"""
name(cmd::AbstractCommand) = string(cmd.name)

"""
    docstring(cmd) -> Union{String, Markdown.MD}

get command's docstring
"""
docstring(cmd::AbstractCommand) = cmd.doc

"""
    findcmd(s, cmds)

find a command in `cmds` named `s`, return `nothing` if it does not
in `cmds`.
"""
function findcmd(s::AbstractString, cmds::Vector{AbstractCommand})
    for cmd in cmds
        if s == name(cmd)
            return cmd
        end
    end
    return nothing
end

"""
default command call. accepts an option `:help` and exits when receives
option `:help`.
"""
function eval_default_command(cmd::AbstractCommand;kwargs...)
    for (key, val) in kwargs
        if key == :help
            print(cmd)
            exit()
        end
    end
end

"""
The last sub-command in a CLI
"""
mutable struct LeafCommand{D<:DocString} <: AbstractCommand
    name::Symbol
    callable::Function
    sig::Signature
    doc::D
end

LeafCommand(name::Symbol, callable::Function, sig::Signature) =
    LeafCommand(name, callable, sig, "No Document")

function (cmd::LeafCommand)(args...;kwargs...)
    eval_default_command(cmd;kwargs...)

    if length(args) != length(cmd.sig.args)
        throw(
            CLIError(
                "expect $(length(cmd.sig.args)) arguments, got $(length(args))"
            )
        )
    end

    cmd.callable(args...;kwargs...)
end

# TODO: use Strong for SYNOPSIS
function show(io::IO, cmd::LeafCommand)
    print(io, "[SYNOPSIS]\n")
    print(io, "\t$(cmd.name) ")
    for op in cmd.sig.options
        print(io, "[$(optionstring(op))] ")
    end

    if length(cmd.sig.args) > 0
        print(io, "<args>\n")
    end
    
    print(io, "[DESCRIPTION]\n")
    print(io, "\t$(cmd.doc)")
end

mutable struct NodeCommand{C<:AbstractCommand, D<:DocString} <: AbstractCommand
    name::String
    cmds::Vector{C}
    doc::D
end

NodeCommand(name::String) = NodeCommand(name, AbstractCommand[])
NodeCommand(name::String, cmds::Vector) = NodeCommand(name, cmds, "No Document")

function (cmd::NodeCommand)(;kwargs...)
    for (key, val) in kwargs
        if key == :help
            print(cmd)
            exit()
        else
            throw(CLIError("Unknown flag $(key)"))
        end
    end
end

function show(io::IO, cmd::NodeCommand)
    println(io, "[SYNOPSIS]")
    println(io, "\t$(cmd.name) <command>")

    println(io, "[DESCRIPTION]")
    println(io, "\t$(cmd.doc)")

    println(io, "[COMMANDS]")
    # TODO: print doc in one block
    for subcmd in cmd.cmds
        println(io, "\t$(name(subcmd))")
        println(io, "\t  $(docstring(subcmd))")
    end
end

"""
```shell
> julia script.jl -a -b<arg> --option --option=arg cmd1 cmd2 arg1 arg2 -c -d<arg> --option 
```

`-a` is equivalent to `-atrue`
`--option` is equivalent to `--option=true`

each short option (start with `-` followed with a letter) must have
corresponding option (start with `--` followed with ascii letter and
`-`, e.g `--long-option-xxx`)

a command line interface has three part

<main command options> <command node> <command node> ... <leaf command> <leaf command args and options>

main command only accepts options
<main> is followed by some <command node> or <leaf command>, e.g

```shell
> git remote add <url>
```

here `git` is the main command name, determined by your script name
`remote` is a <command node>, and `add` is the <leaf node>

## Invalid Syntax

`-c arg` is not allowed


N: number of arguments
"""
mutable struct MainCommand{O<:AbstractOption, C<:AbstractCommand, D<:DocString} <: AbstractCommand
    name::String
    options::Vector{O}
    cmds::Vector{C}
    doc::D
    version::VersionNumber
    entry::Function
end

__EMPTY__(;) = nothing

MainCommand() = MainCommand(AbstractOption[], AbstractCommand[])
MainCommand(name::String, options::Vector, cmds::Vector) = 
    MainCommand(name, [options..., help, version], cmds, "", v"0.0.1", __EMPTY__)
MainCommand(options::Vector, cmds::Vector) = MainCommand("main", options, cmds)

function eval_default_command(cmd::MainCommand;kwargs...)
    for (key, val) in kwargs
        if key == :help
            print(cmd)
            exit()
        end

        if key == :version
            print("$(cmd.name) $(cmd.version)")
            exit()
        end
    end
end

function (cmd::MainCommand)(;kwargs...)
    eval_default_command(cmd;kwargs...)
    return cmd.entry(;kwargs...)
end

function show(io::IO, cmd::MainCommand)
    println(io, "[SYNOPSIS]")

    print(io, "\t$(cmd.name) ")
    for op in cmd.options
        print(io, "[$(optionstring(op))] ")
    end

    println(io, "<command>")

    println(io, "[DESCRIPTION]")
    println(io, "\t$(cmd.doc)")

    println(io, "[COMMANDS]")
    # TODO: print doc in one block
    for subcmd in cmd.cmds
        println(io, "\t$(name(subcmd))")
        println(io, "\t  $(docstring(subcmd))")
    end
end
