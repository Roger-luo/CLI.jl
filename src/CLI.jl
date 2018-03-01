__precompile__()

module CLI

include("Exceptions.jl")
include("Stream.jl")

include("Elements.jl")
include("Commands.jl")
include("Parser.jl")

include("Interface.jl")

export main
# short hands
Base.@ccallable function main(debug=false)::Cint
    stream = ARGStream(ARGS)
    resolve(stream, __MAIN__; debug=debug)
    return 0
end

end # module
