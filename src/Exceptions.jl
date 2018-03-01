import Base: show, push!

"""
    CLIException

Command line interface exceptions, contains a member
`cmdstack` for command backtrace.
"""
abstract type CLIException <: Exception end
push!(e::CLIException, cmdname::String) = push!(e.cmdstack, cmdname)
cmdtrace(e::CLIException) = join(e.cmdstack[end:-1:1], " ")

function helpguide(io::IO, msg::CLIException)
    cmd = cmdtrace(msg)
    println(io, "Try '$(cmd) --help/-h' for more information")
end

function errorinfo(io::IO, e::Exception)
    println(io, e)
    println(io, "Try 'option --help/-h' for more information")
end

function errorinfo(io::IO, msg::CLIException)
    println(io, msg)
    helpguide(io, msg)
end

errorinfo(msg::CLIException) = errorinfo(STDERR, msg)

struct OptionError <: CLIException
    cmdstack::Vector{String}
    option::String
end

OptionError(option::String) = OptionError([], option)
OptionError(init::String, option::String) = OptionError([init], option)

function show(io::IO, msg::OptionError)
    print(io, "unrecognized option `$(msg.option)`")
end

"""
Input command error.
"""
struct CmdError <: CLIException
    cmdstack::Vector{String}
    cmdname::String
end

CmdError(cmdname::String) = CmdError([], cmdname)
CmdError(init::String, cmdname::String) = CmdError([init], cmdname)

function show(io::IO, msg::CmdError)
    print(io, "unrecognized command `$(msg.cmdname)`")
end

"""
Invalid CLI argument (type)
"""
struct CLIArgError{SIG, GOT} <: CLIException
    cmdstack::Vector{String}
end

CLIArgError(::Type{S}, ::Type{T}) where {S, T} = CLIArgError{S, T}([])
CLIArgError(init::String, ::Type{S}, ::Type{T}) where {S, T} = CLIArgError{S, T}([init])

function show(io::IO, msg::CLIArgError{S, T}) where {S, T}
    print(io, "Unknown type: $(T) (expect $(S))")
end

"""
General CLI error message
"""
struct CLIError <: CLIException
    cmdstack::Vector{String}
    msg::String
end

CLIError(msg::String) = CLIError([], msg)

function show(io::IO, msg::CLIError)
    print(msg.msg)
end