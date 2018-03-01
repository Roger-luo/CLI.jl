export ARGStream

# TODO: support Base.IO interface

"""
CLI Arguement Stream. Acts like a stream and a Array (support indexing),
it takes in a list of `String` and return an `String` each time
you move its `ptr`.
"""
mutable struct ARGStream
    head::Int
    data::Vector{String}
end

ARGStream(data::Vector{String}) = ARGStream(1, data)

# Stream Interface
import Base: eof
eof(stream::ARGStream) = stream.head > endof(stream.data)
position(stream::ARGStream) = stream.head
function seek(stream::ARGStream, pos::Int)
    # @assert 1 <= pos <= length(stream.data)
    stream.head = pos
    return stream
end
close(stream::ARGStream) = 0

"""
Copyed from Base.Docs for ARGStream. It keeps the `ptr` position
if function `f` returns `nothing` or `false`.
"""
function withstream(f::Function, stream::ARGStream)
    pos = position(stream)
    result = f()
    (result === nothing || result == false) && seek(stream, pos)
    return result
end

"""
flush the rest arguemnts
"""
function flush(stream::ARGStream)
    head = stream.head
    stream.head = endof(stream.data)
    return stream.data[head:end]
end

# Array Interface
import Base: eltype, length, size, getindex, eachindex, endof
eltype(stream::ARGStream) = String
length(stream::ARGStream) = length(stream.data) - stream.head
size(stream::ARGStream) = (length(stream), )
getindex(stream::ARGStream, index) = getindex(stream.data, index)
eachindex(stream::ARGStream) = stream.head:endof(stream.data)
endof(stream::ARGStream) = endof(stream.data)

# Read
export readarg

"""
    readarg(stream::ARGStream)

read an argument
"""
function readarg(from::ARGStream)
    if eof(from)
        return nothing
    end

    head = from.head
    from.head += 1
    return from.data[head]
end

"""
    readarg(stream::ARGStream, size::Int)

read `size` arguments
"""
function readarg(from::ARGStream, size::Int)
    head = from.head
    tail = from.head + size - 1
    tail = tail > length(ARGS) ? length(ARGS) : tail
    from.head = tail + 1
    return from.data[head:tail]
end
