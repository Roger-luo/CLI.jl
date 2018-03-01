using CLI

add(x::Int, y::Int) = x + y
mul(x::Int, y::Int) = x * y

leaf1 = LeafCommand(:add, add, Signature([Int, Int], []))
leaf2 = LeafCommand(:mul, mul, Signature([Int, Int], []))
node = NodeCommand("math", [leaf1, leaf2])

maincmd = MainCommand("cal", [], [node])

stream = ARGStream(ARGS)
resolve(stream, maincmd; debug=false)
