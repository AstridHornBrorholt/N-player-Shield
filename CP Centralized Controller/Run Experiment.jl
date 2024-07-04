## Preface ##
using Dates
using Unicode
# The fruit is there to distinguish different runs writing to the same output concurrently. This doesn't seem to be a problem after all but I enjoy the splash of colour.
emoji = ["🧪", "🥽", "🥼", "⚗️", "💊", "🧫", "👨‍🔬", "👩‍🔬", "🧬", "🌡️", "⏳", "💉", "🔬", "💡", "📊"]
🧪📊 = join(rand(emoji, 2), "")
function status(str) 
    time = Dates.format(Dates.now(), "dd/mm HH:MM")
    println("$time $🧪📊 $str")
    flush(stdout)
end
using Pkg
Pkg.activate("..")

using ArgParse
include("Create Plant.jl")

## Args and Constants ##
const ⨝ = joinpath
const ← = push!

begin
	s = ArgParseSettings()
	@add_arg_table s begin
	     "--runs"
			arg_type=Int
			required=true
		"--checks"
			arg_type=Int
			required=true
        "--repetition"
            arg_type=Int
            required=true
		"--results-dir"
			default=homedir() ⨝ "Results/N-player $(basename(pwd()))"
        "--verifyta-path"
            default=homedir() ⨝ "opt/uppaal-5.1.0-beta5-linux64/bin/verifyta.sh"
        "--blueprint-path"  
            default=pwd() ⨝ "Plant_blueprint.xml"
        "--shield-path"  
            default=pwd() ⨝ "libcpshield.so"
	end
end;

args = parse_args(s)

runs = args["runs"]
checks = args["checks"]
repetition = args["repetition"]
results_dir = args["results-dir"]
verifyta_path = args["verifyta-path"]
status("Starting... $((;runs, repetition))")

isdir(results_dir) || mkdir(results_dir) # Error if path is invalid except if it is only the last folder missing.
isfile(verifyta_path) || error("File verifyta not found at path $verifyta_path")

verifyta_args = "-s --epsilon 0.001 --max-iterations 1 --good-runs $runs --total-runs $runs --runs-pr-state $runs"

verifyta_call = String[
    verifyta_path,
    split(verifyta_args, " ")...
]

blueprint_path = args["blueprint-path"]
shield_path = args["shield-path"]

## Resolving Paths ##
isfile(shield_path) || error("Shield file not found at $shield_path")

shield_path′ = results_dir ⨝ basename(shield_path)
cp(shield_path, shield_path′, force=true)
shield_path = shield_path′

working_dir = results_dir ⨝ "$runs Runs" ⨝ "Repetition $repetition"
mkpath(working_dir)
query_results_dir = working_dir ⨝ "Query Results"
mkpath(query_results_dir)
models_dir = working_dir ⨝ "Models"
mkpath(models_dir)

## Mainmatter ##

status("Running plant with centralized control over all produciton units...  $((;repetition, runs))")
outfile = query_results_dir ⨝ "Plant.txt"
model_path = create_plant(blueprint_path, shield_path, models_dir; checks)
open(outfile, "w") do io
    result = [verifyta_call..., model_path] |> Cmd |> read |> String
    write(io, result)
end
status("Done running plant with centralized control over all production units.  $((;repetition, runs))")

status("All done.")