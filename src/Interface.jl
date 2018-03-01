const __MAIN__ = MainCommand()

function make(main::String)
    if main != name(__MAIN__)
        __MAIN__.name = main
    end
end

function make(name::Symbol, cmd::T) where {T <: Union{MainCommand, NodeCommand}}
    name = string(name)
    leaf = findcmd(name, cmd.cmds)
    if leaf === nothing
        leaf = NodeCommand(name)
        push!(cmd.cmds, leaf)
    end
    return leaf
end

function make(name::NTuple{N, Symbol}, cmd::T) where {N, T <: Union{MainCommand, NodeCommand}}
    child = make(first(name), cmd)
    make(Base.tail(name), child)
end

function make(name::Tuple{}, cmd::T) where {T <: Union{MainCommand, NodeCommand}}
    return cmd
end

isparameter(expr::Expr) = expr.head == :parameters

# TODO: support user-defined short/long options
function getoption(expr::Expr)
    key = expr.args[1].args[1]
    dtype = eval(expr.args[1].args[2])
    ShortOption(dtype, key)
end

function gettype(expr::Expr)
    eval(expr.args[2])
end

function parameter(expr::Expr)
    kwds = AbstractOption[]
    for each in expr.args
        push!(kwds, getoption(each))
    end
    kwds
end

function arguments(expr::Vector)
    args = DataType[]
    for each in expr
        push!(args, gettype(each))
    end
    args
end

function signature(expr::Expr)
    args = DataType[]; kwds = AbstractOption[]

    if isa(expr.args[2], Expr) && isparameter(expr.args[2])
        kwds = parameter(expr.args[2])
        args = arguments(expr.args[3:end])
    else
        args = arguments(expr.args[2:end])
    end

    Signature(args, kwds)
end

import Base.Docs: Binding, DocStr, MultiDoc, parsedoc, catdoc, meta, getdoc, defined

function commanddoc(var::Symbol)
    results, groups = DocStr[], MultiDoc[]
    m = current_module()
    binding = Binding(m, var)

    if defined(binding)
        result = getdoc(binding)
        result === nothing || return result
    end

    dict = meta(m)
    if haskey(dict, binding)
        multidoc = dict[binding]
        push!(groups, multidoc)

        for msig in multidoc.order
            push!(results, multidoc.docs[msig])
        end
    end

    if isempty(groups)
        return "No Documents"
    end

    md = catdoc(map(parsedoc, results)...)

    if isa(md, Markdown.MD)
        md.meta[:results] = results
        md.meta[:binding] = binding
        md.meta[:typesig] = Union{}
    end
    return md
end

"""
    @command "..."

add docstring (description) to main command/node command

    @command

add a function to the CLI tree, like:

    @command function add(x, y)
        x + y
    end

or just

    @command add(x, y) = x + y

```julia
module math
@command "math operations"

module add
@command "add numbers"

@command function plus(x::Int, y::Int)
    # some code for plus
end

end

end
```

and when this CLI is executed in command line with `-h`/`--help`,
will looks like

```shell
> math --help
[SYNOPSIS]
	math [-h,--help] [-v,--version] <command>
[DESCRIPTION]
	math operations

[COMMANDS]
	add
	  add numbers
```
"""
:(@command)

function module_filename(m::Module)
    basename(m.eval(parse("@__FILE__")))
end

macro command(doc::String)
    m = current_module()
    nodes = fullname(m)

    if isempty(nodes)
        name = module_filename(m)
        make(name)
        __MAIN__.doc = doc
    else
        make(string(first(nodes)))
        tail = make(Base.tail(nodes), __MAIN__)
        tail.doc = doc
    end

end

import Core: @__doc__

macro command(expr::Expr)
    m = current_module()
    nodes = fullname(m)
    
    if !isempty(nodes)
        make(string(first(nodes)))
        tail = make(Base.tail(nodes), __MAIN__)
    else
        tail = __MAIN__
    end

    # insert leaf
    name = expr.args[1].args[1]
    
    sig = signature(expr.args[1])
    
    namestr = string(name)
    quote
        # f = $(esc(expr))
        @__doc__ $(esc(expr))
        f = $(esc(name))
        docstring = commanddoc(Symbol($namestr))
        push!($(tail.cmds), LeafCommand(Symbol($namestr), f, $sig, docstring))
    end
end

export @command