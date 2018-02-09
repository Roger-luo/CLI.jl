# CLI

CLI.jl is a library for automatically generating command line interfaces from 
absolutely Julia object. Is is highly inspired by [python-fire](https://github.com/google/python-fire). But thanks to Julia's powerful metaprogramming, we are able to do this in a much easier way. CLI.jl make use of Julia's metaprogramming and multiple dispatch feature. It converts amost everything to CLI commands.

## Features

- modular implementation
- converts most of the julia objects to CLI commands

# Installation

```julia
Pkg.clone()
```

# Basic Usage

You can call `@fire` on any Julia Object.

```julia
@fire struct Foo
    x
end

main()
```

```bash
> julia foo.jl Foo 2
Foo(2)
```

```julia
@fire function add(x, y; z=2)
    return x + y + z
end

main()
```

```bash
> julia add.jl add 1 2
5
> julia add.jl add 1 2 --z=5
8
```

```julia
hello = "hello there!"
@fire hello

main()
```

```bash
> julia hello.jl hello
hello there!
```

# Advanced

CLI.jl implements two macros `register` and `fire`. The macro `@fire` is used to register entries and `@register` is used to register customed expression parsers, which will convert certain type of expression to an `Entry{T}` object.

To define a parse rule, you have to specific which kind of expression it will parse by add type specification to the function, and the function should take only one arguement.

```julia
@register function parse(obj)::Function
    if isa(obj, Expr)
        if obj.head == :function
            sig = obj.args[1]
            name = sig.args[1]
            return Entry(Function, name)
        end
    end
end
```

By overloading `exec` method, one can tweak the way of executing certain type. The following is an example for executing `Function` entries.

```julia
function exec(entry::Entry{Function}, cmd::Command)
    expr = Expr(:call, entry.fullname, Tuple(cmd.args)..., Tuple(cmd.options)...)
    return eval(expr)
end
```

## Author

Roger Luo