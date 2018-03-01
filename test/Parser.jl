using CLI
using Base.Test

@test parse(CLI.CLILongFlag, "--help") == CLI.CLILongFlag("help", "")
@test parse(CLI.CLILongFlag, "--help=true") == CLI.CLILongFlag("help", "true")
@test parse(CLI.CLILongFlag, "help=true") == nothing

@test parse(CLI.CLIShortFlag, "-h") == CLI.CLIShortFlag('h', "")
@test parse(CLI.CLIShortFlag, "-h=true") == CLI.CLIShortFlag('h', "true")
@test parse(CLI.CLIShortFlag, "-htrue") == CLI.CLIShortFlag('h', "true")
@test parse(CLI.CLIShortFlag, "help=true") == nothing
