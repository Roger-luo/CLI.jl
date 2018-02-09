__precompile__()

module CLI

include("core.jl")

export main, @fire, @register, Callable

# copy from stackoverflow
# https://stackoverflow.com/questions/41658692

# we need add absolute module path
function iscallable(obj::Symbol)
    mname = current_module_name()
    name = parse(join([mname, obj], "."))
    return !isempty(methods(eval(name)))
end


abstract type Callable end

function default_root(;help=false)
    # println("help: $(help)")
end

function main()
    cli = Command()
    if isdefined(:root)
        expr = Expr(:call, :root, Tuple(cli.root))
    else
        expr = Expr(:call, :default_root, Tuple(cli.root)...)
    end
    out = eval(expr)
    if out != nothing
        println(out)
    end

    for each in ENVS["entries"]
        if cli.name == each.name
            out = exec(each, cli)
            if out != nothing
                println(out)
            end
            break
        end
    end
    return 0
end

@register function parse(obj)::Function
    if isa(obj, Expr)
        if obj.head == :function
            sig = obj.args[1]
            name = sig.args[1]
            return Entry(Function, name)
        end
    end
end

function exec(entry::Entry{Function}, cmd::Command)
    expr = Expr(:call, entry.fullname, Tuple(cmd.args)..., Tuple(cmd.options)...)
    return eval(expr)
end

@register function parse(obj)::Callable
    if isa(obj, Symbol)
        if isdefined(obj) && Main.CLI.iscallable(obj)
            return Entry(Main.CLI.Callable, obj)
        end
    end
end


function exec(entry::Entry{Callable}, cmd::Command)
    expr = Expr(:call, entry.fullname, Tuple(cmd.args)..., Tuple(cmd.options)...)
    return eval(expr)
end

@register function parse(obj)::Any
    if isa(obj, Symbol)
        mname = current_module_name()
        fullname = parse(join([mname, obj], "."))
        return Entry{Any}(obj, nothing, eval(fullname))
    end
end

function exec(entry::Entry{Any}, cmd::Command)
    return entry.value
end

@register function parse(obj)::Type
    if isa(obj, Expr)
        if obj.head == :type
            return Entry(Type, obj.args[2])
        end
    end
end

function exec(entry::Entry{Type}, cmd::Command)
    expr = Expr(:call, entry.fullname, Tuple(cmd.args)..., Tuple(cmd.options)...)
    return eval(expr)
end

end # module
