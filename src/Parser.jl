import Base: parse

"""
Abstract type for Command Line Interface Patterns
"""
abstract type CLIPattern end

"""
Command Line Interface Flags, e.g --flag, -f
"""
abstract type CLIFlag <: CLIPattern end

==(lhs::CLIFlag, rhs::CLIFlag) = (lhs.name == rhs.name) && (lhs.val == rhs.val)

"""
    CLILongFlag(name::String, val::String)

Command line long flags, startswith `--`. e.g `--flag`
"""
struct CLILongFlag <: CLIFlag
    name::String
    val::String
end

"""
    CLIShortFlag(name::Char, val::String)

Command line short flags, startswith `-`. e.g `-f`
"""
struct CLIShortFlag <: CLIFlag
    name::Char
    val::String
end

pattern(::Type{CLILongFlag}) = r"^--([a-zA-Z\-_]+[0-9]*)"
pattern(::Type{CLIShortFlag}) = r"^-([a-zA-Z]{1})"

islongflag(s::AbstractString) = ismatch(pattern(CLILongFlag), s)
isshortflag(s::AbstractString) = ismatch(pattern(CLIShortFlag), s)
iscmdarg(s::AbstractString) = !islongflag(s) && !isshortflag(s)

function parse(::Type{CLILongFlag}, s::AbstractString)
    m = match(pattern(CLILongFlag), s)
    m === nothing && return nothing

    name = m.captures[1]
    s = s[length(m.match)+1:end]
    m = match(r"^=(.+)", s)

    if m === nothing
        return CLILongFlag(name, "")
    else
        return CLILongFlag(name, m.captures[1])
    end
end

function parse(::Type{CLIShortFlag}, s::AbstractString)
    m = match(pattern(CLIShortFlag), s)
    m === nothing && return nothing

    name = m.captures[1]
    s = s[length(m.match)+1:end]

    m = match(r"^=(.+)", s)
    if m != nothing
        return CLIShortFlag(name[1], m.captures[1])
    end

    m = match(r"^([^=]+)", s)

    if m === nothing
        return CLIShortFlag(name[1], "")
    else
        return CLIShortFlag(name[1], m.captures[1])
    end
end

"""
get flags from an command line argument stream.

if greedy is `false`, it stops at the first non-flag
argument, or it reads all the flags and put ptr in
stream to `eof`.
"""
function getflags(stream::ARGStream; greedy=false)
    flags = []
    while !eof(stream)
        pos = position(stream)
        arg = readarg(stream)
        flag = parse(CLILongFlag, arg)
        if flag === nothing
            flag = parse(CLIShortFlag, arg)
        end

        if flag === nothing
            if !greedy
                seek(stream, pos)
                break
            end
        else
            push!(flags, flag)
        end
    end
    return flags
end

"""
get command arguments from stream. if greedy is `true`
it reads all possible arguments.
"""
function getcmds(stream::ARGStream; greedy=false)
    args = String[]
    while !eof(stream)
        pos = position(stream)
        arg = readarg(stream)
        
        if iscmdarg(arg)
            push!(args, arg)
        else
            greedy || return args
        end
    end
    return args
end

"""
find corresponding option from the list according to command line flags
"""
function findoption(clioption::CLIFlag, options::Vector{T}) where {T <: AbstractOption}
    for each in options
        if clioption.name == each
            return each
        end
    end
    return nothing
end

"""
eval and parse all arguments from command line according to signature
"""
function getargs(cmds::Vector{String}, sigs::Vector{DataType})
    if length(cmds) != length(sigs)
        throw(CLIError("Expect $(length(sigs)) positional arguments (got $(length(cmds)))"))
    end

    args = []
    for (cmd, sig) in zip(cmds, sigs)
        val = eval(parse(sig, cmd))
        isa(val, sig) || throw(CLIArgError(sig, typeof(val)))
        push!(args, val)
    end
    return args
end

"""
eval and parse all keywords according to command line flags
"""
function getkeywords(flags, options)
    keywords = []
    for each in flags
        option = findoption(each, options)
        if option === nothing
            throw(OptionError(each.name))
        else
            push!(keywords, parse(each.val, option))
        end
    end
    return keywords
end

"""
flush the error infomation to IO if the function throws. rethrow the error
if `raise` is true (default).
"""
function flusherror(f::Function, io::IO, cmd::AbstractCommand; raise=true)
    result = try
        f()
    catch e
        if isa(e, CLIException)
            push!(e, name(cmd))
        end
        raise ? rethrow(e) : errorinfo(io, e)
        !(raise) && exit(-1)
    end
    return result
end

export resolve

"""
resolve command line inputs according to registered command. throw
all the errors if `debug` is `true`.
"""
function resolve(stream::ARGStream, cmd::MainCommand; debug=false)
    flags = getflags(stream)

    flusherror(STDERR, cmd; raise=debug) do
        keywords = getkeywords(flags, cmd.options)
        isempty(keywords) ? nothing : cmd(;keywords...)
    end

    flusherror(STDERR, cmd; raise=debug) do
        resolve(stream, cmd.cmds)
    end
end

function resolve(stream::ARGStream, cmd::NodeCommand)
    flags = getflags(stream)

    flusherror(STDERR, cmd) do
        keywords = getkeywords(flags, [help])
        cmd(;keywords...)
        resolve(stream, cmd.cmds)
    end    
end

function resolve(stream::ARGStream, cmd::LeafCommand)
    start = position(stream)
    flags = getflags(stream;greedy=true)
    seek(stream, start)
    cmds = getcmds(stream;greedy=true)

    flusherror(STDERR, cmd) do
        keywords = getkeywords(flags, cmd.sig.options)
        args = getargs(cmds, cmd.sig.args)
        result = cmd(args...;keywords...)
        result === nothing ? nothing: println(STDOUT, result)
    end
end

function resolve(stream::ARGStream, cmds::Vector{AbstractCommand})
    eof(stream) && return 0

    arg = readarg(stream)
    subcmd = findcmd(arg, cmds)
    if subcmd === nothing
        throw(CmdError(arg))
    else
        resolve(stream, subcmd)
    end
    return 0
end
