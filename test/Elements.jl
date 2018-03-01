using CLI
using Base.Test

@testset "CLI Elements" begin

@testset "basic flags" begin

# NOTE: isoption only captures prefix
@test CLI.isoption("-h") == true
@test CLI.isoption("--help") == true
@test CLI.isoption("cmd") == false
@test CLI.isoption("@file") == false
@test CLI.isoption(nothing) == false

@test CLI.islong("-h") == false
@test CLI.islong("--help") == true
@test CLI.islong("cmd") == false
@test CLI.islong("@file") == false
@test CLI.islong(nothing) == false

end # basic flags

@testset "Option Compare" begin
    testop = Option("help", :help, "No Doc")
    @test "--help" == testop
    @test "-h" != testop

    testop = ShortOption('h', "help", :help, "No Doc")
    @test "--help" == testop
    @test "-h" == testop
end # Option Compare

# @testset "Option Search" begin
#     options = AbstractOption[
#         Option("foo", :foo, "No Doc"),
#         ShortOption('c', "cool", :cool, "No Doc"),
#         Option("aaa-aaa", :aaa_aaa, "No Doc")
#     ]

#     @test CLI.findoption("--foo", options) == options[1]
#     @test CLI.findoption("-f", options) == nothing

#     @test CLI.findoption("-c", options) == options[2]
#     @test CLI.findoption("-cool", options) == nothing
#     @test CLI.findoption("--cool", options) == options[2]

#     @test CLI.findoption("aaa-aaa", options) == options[3]
#     @test CLI.findoption("--aaa-aaa", options) == options[3]
#     @test CLI.findoption("aaa_aaa", options) == nothing
#     @test CLI.findoption("--aaa_aaa", options) == nothing

# end # Option Search

end # CLI Elements