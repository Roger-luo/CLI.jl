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
    stream = ARGStream(ARGS)
    resolve(stream, CLI.__MAIN__; debug=false)
end

end

demo.julia_main(ARGS)