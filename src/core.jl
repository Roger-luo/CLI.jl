# module Core

# export main, @fire, @register, Command, Entry, Parser, current_module_name

function current_module_name()
    mname = fullname(current_module())
    mname = String[string(m) for m in mname]
    if mname == []
        insert!(mname, 1, "Main")
    end
    return join(mname, ".")
end

struct Command
    root::Vector
    name::Symbol
    args::Vector
    options::Vector
end

struct Entry{T}
    name::Union{Symbol, Expr}
    fullname::Expr # module name
end

struct Parser{T}
    f::Function
end

ENVS = Dict()
ENVS["entries"] = Entry[]
ENVS["parsers"] = Dict{Type, Function}()

Command(root) = Command(root, :nothing, [], [])

function Command()
    root = []
    while !isempty(ARGS)
        cmd = keyword(ARGS[1])
        if cmd == nothing
            break
        else
            push!(root, cmd)
            shift!(ARGS)
        end
    end

    args = []
    options = []
    arg_help = false
    for each in ARGS
        cmd = keyword(each)
        if cmd == nothing
            push!(args, parse(each))
        else
            push!(options, cmd)
        end
    end

    if isempty(root)
        if isempty(args) || !isa(args[1], Symbol)
            error("command name needed, use --help/-h to see help info")
        end
    end

    if isempty(args)
        return Command(root)
    else
        return Command(root, shift!(args), args, options)
    end
end

function Entry{T}(::Type{T}, name)
    mname = current_module_name()
    fullname = join([mname, name], ".")
    return Entry{T}(name, parse(fullname))
end

function keyword(text::AbstractString)
    if startswith(text, "--")
        text = text[3:end]
    elseif startswith(text, "-") && length(text) == 2
        warn("do not support shorthand at the moment")
    else 
        return nothing
    end

    expr = parse(text)
    if isa(expr, Expr)
        expr.head = :kw
    else
        expr = Expr(:kw, expr, true)
    end
    return expr
end

macro register(f::Expr)
    if f.head != :function 
        error("Can only register a function")
    end
    sig = f.args[1]
    f.args[1] = sig.args[1]
    name = sig.args[1] 
    name.args[1] = parse(join([name.args[1], "_" ,length(ENVS["parsers"])]))
    name = name.args[1]

    dtype = sig.args[2]
    return quote
        esc($f)
        ENVS["parsers"][$dtype] = $name
    end
end

macro fire(obj)
    min_match = Any
    m = nothing
    for (t, f) in ENVS["parsers"]
        m = f(obj)
        if m != nothing
            # find min_match
            if t <: min_match
                min_match = t
            end
        end
    end
    if m != nothing
        push!(ENVS["entries"], m)
    end
    return esc(obj)
end

# end