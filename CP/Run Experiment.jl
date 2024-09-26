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
        "--n-units"
            help="number of units"
            arg_type=Int
            default=10
        "--repetition"
            arg_type=Int
            required=true
		"--results-dir"
			default=homedir() ⨝ "Results/N-player $(basename(pwd()))"
        "--verifyta-path"
            default=homedir() ⨝ "opt/uppaal-5.0.0-linux64/bin/verifyta.sh"
        "--blueprint-path"  
            default=pwd() ⨝ "Plant_blueprint.xml"
        "--shield-path"  
            default=pwd() ⨝ "libcpshield.so"
        "--one-outgoing-shield-path"  
            default=pwd() ⨝ "libcponeoutgoingshield.so"
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

runs_per_unit = round(Int64, runs/n_units)

isdir(results_dir) || mkdir(results_dir) # Error if path is invalid except if it is only the last folder missing.
isfile(verifyta_path) || error("File verifyta not found at path $verifyta_path")

verifyta_args = "-s --epsilon 0.001 --max-iterations 1 --good-runs $runs_per_unit --total-runs $runs_per_unit --runs-pr-state $runs_per_unit"

verifyta_call = String[
    verifyta_path,
    split(verifyta_args, " ")...
]

blueprint_path = args["blueprint-path"]
shield_path = args["shield-path"]
one_outgoing_shield_path = args["one-outgoing-shield-path"]

## Resolving Paths ##
isfile(shield_path) || error("Shield file not found at $shield_path")
isfile(one_outgoing_shield_path) || error("Shield file not found at $one_outgoing_shield_path")

shield_path′ = results_dir ⨝ basename(shield_path)
cp(shield_path, shield_path′, force=true)
shield_path = shield_path′

one_outgoing_shield_path′ = results_dir ⨝ basename(one_outgoing_shield_path)
cp(one_outgoing_shield_path, one_outgoing_shield_path′, force=true)
one_outgoing_shield_path = one_outgoing_shield_path′

working_dir = results_dir ⨝ "$runs Runs" ⨝ "Repetition $repetition"
mkpath(working_dir)
query_results_dir = working_dir ⨝ "Query Results"
mkpath(query_results_dir)
models_dir = working_dir ⨝ "Models"
mkpath(models_dir)

## Mainmatter ##
strategy_paths = String[]
for N in n_units:-1:1
    status("Running plant with $(n_units - N) optimized produciton units...  (repetition=$repetition)")
    outfile = query_results_dir ⨝ "Plant $(length(strategy_paths)).txt"

    model_path, queries_path = create_plant(blueprint_path,
        strategy_paths,
        shield_path,
        one_outgoing_shield_path,
        models_dir;
        checks,
        skip_training)

    strategy_paths ← (working_dir ⨝ "Models/unit$N.json")
    open(outfile, "w") do io
        result = [verifyta_call..., model_path, queries_path] |> Cmd |> read |> String
        write(io, result)
    end
    status("Done running plant with $(n_units - N) optimized production units.  (repetition=$repetition)")
end

status("All done.")