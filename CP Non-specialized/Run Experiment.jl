## Preface ##
using Dates
using Unicode
# The fruit is there to distinguish different runs writing to the same output concurrently. This doesn't seem to be a problem after all but I enjoy the splash of colour.
emoji = ["🅰️", "🆎", "🅱️", "🆑", "🅾️", "🆗", "🆒", "🆙", "🆔", "🔣", "🆚"]
🆎🆒 = join(rand(emoji, 2), "")
function status(str) 
    time = Dates.format(Dates.now(), "dd/mm HH:MM")
    println("$time $🆎🆒 $str")
    flush(stdout)
end
using Pkg
Pkg.activate("..")

using ArgParse
include("../CP/Create Plant.jl")

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
        "--n-units"
            help="number of units"
            arg_type=Int
            default=10
        "--repetition"
            arg_type=Int
            required=true
		"--results-dir"
			default=homedir() ⨝ "Results/N-player CP Non-specialized"
        "--verifyta-path"
            default=homedir() ⨝ "opt/uppaal-5.0.0-linux64/bin/verifyta.sh"
        "--blueprint-path"  
            default=pwd() ⨝ "../CP/Plant_blueprint.xml"
        "--shield-path"  
            default=pwd() ⨝ "../CP/libcpshield.so"
        "--skip-training"
            action=:store_true
	end
end;

args = parse_args(s)

runs = args["runs"]
checks = args["checks"]
n_units = args["n-units"]
repetition = args["repetition"]
results_dir = args["results-dir"]
verifyta_path = args["verifyta-path"]
skip_training = args["skip-training"]
status("Starting... $((;runs, repetition, skip_training))")

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

function do_run(strategy_paths; skip_training)
    N = length(strategy_paths) + 1
    status("Running plant with $N optimized produciton units...  (repetition=$repetition)")
    outfile = query_results_dir ⨝ "Plant $(N - 1).txt"
    model_path, queries_path = create_fleet(blueprint_path, strategy_paths, shield_path, models_dir; checks, skip_training)
    strategy_paths ← (working_dir ⨝ "Models/unit$N.json")
    open(outfile, "w") do io
    result = [verifyta_call..., model_path, queries_path] |> Cmd |> read |> String
    write(io, result)
    end
    status("Done running plant with $N optimized production units.  (repetition=$repetition)")
end

## Mainmatter ##

# Start by training a strategy for the first unit. This strategy will be applied to all units.
do_run([], skip_training=false)
strategy_path = working_dir ⨝ "Models/unit1.json"
strategy_paths = [strategy_path for _ in 0:n_units - 2]

# Hack: When skip_training==true, the function will look for a strategy with the appropriate number.
#This is a quick way to ensure that the last car in the fleet also uses the strategy of car1.
strategy_path′ = working_dir ⨝ "Models/unit$n_units.json"
cp(strategy_path, strategy_path′, force=true)

# Advanced technique: And as it turns out, the strategy file doesn't match because 
#it applies to an automaton called U1 and not U10. Nothing a little search-and-replace can't fix.
search_and_replace(strategy_path′, strategy_path′, Dict(
    "U1.Working" => "U$n_units.Working",
    "U1.Choosing" => "U$n_units.Choosing",
))

# Run the actual experiment where all units uses the strategy learned for unit1.
do_run(strategy_paths, skip_training=true)
status("All done.")