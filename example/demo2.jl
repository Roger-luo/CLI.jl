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