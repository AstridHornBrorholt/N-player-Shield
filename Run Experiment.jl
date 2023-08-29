using Dates
# The fruit is there to distinguish different runs writing to the same output concurrently. This doesn't seem to be a problem after all but I enjoy the splash of colour.
🍎 = rand("🍇🍈🍉🍊🍋🍌🍍🥭🍎🍏🍐🍑🍒🍓🫐🥝🍅🫒🥥")
function status(str) 
    time = Dates.Time(Dates.now())
    println("$time $🍎 $str")
end
status("Starting...")
using Pkg
Pkg.activate(".")

using ArgParse
include("Create Fleet.jl")

⨝ = joinpath
← = push!

begin
	s = ArgParseSettings()
	@add_arg_table s begin
	     "--runs"
			arg_type=Int
			required=true
		"--checks"
			arg_type=Int
			required=true
        "--max-cars"
            arg_type=Int
            required=true
        "--repetitions"
            arg_type=Int
            required=true
		"--results-dir"
			default=homedir() ⨝ "Results/N-player CC"
        "--verifyta-path"
            default=homedir() ⨝ "opt/uppaal-5.0.0-linux64/bin/verifyta.sh"
        "--blueprint-path"  
            default=pwd() ⨝ "Fleet_blueprint.xml"
        "--shield-path"  
            default=pwd() ⨝ "Shield/libshield.so"
        "--skip-training"
            action=:store_true
            help="Use car1.json for all cars in the fleets (must exist) without training any strategies."
	end
end;

args = parse_args(s)

runs = args["runs"]
checks = args["checks"]
max_cars = args["max-cars"]
repetitions = args["repetitions"]
results_dir = args["results-dir"]
verifyta_path = args["verifyta-path"]
skip_training = args["skip-training"]

isdir(results_dir) || mkdir(results_dir) # Provoke error if path is invalid
isfile(verifyta_path) || error("File verifyta not found at path $verifyta_path")

verifyta_args = "-s --epsilon 0.001 --max-iterations 1 --good-runs $runs --total-runs $runs --runs-pr-state $runs"

blueprint_path = args["blueprint-path"]
shield_path = args["shield-path"]

isfile(shield_path) || error("Shield file not found at $shield_path")

shield_path′ = results_dir ⨝ basename(shield_path)
cp(shield_path, shield_path′, force=true)
shield_path = shield_path′

verifyta_call = String[
    verifyta_path,
    split(verifyta_args, " ")...
]

for repetition in 1:repetitions
    working_dir = results_dir ⨝ "$runs Runs"
    working_dir = working_dir ⨝ "Repetition $repetition"
    isdir(working_dir) || mkpath(working_dir)
    query_results_dir = working_dir ⨝ "Query Results"
    isdir(query_results_dir) || mkpath(query_results_dir)
    models_dir = working_dir ⨝ "Models"
    isdir(models_dir) || mkpath(models_dir)

    strategy_paths = String[]
    for N in 2:max_cars
        status("Running Fleet of $N Cars...")
        outfile = query_results_dir ⨝ "Fleet of $N Cars.txt"
        model_path, queries_path = create_fleet(blueprint_path, strategy_paths, shield_path, models_dir; checks, skip_training)
        if skip_training
            strategy_paths ← (working_dir ⨝ "Models/car1.json")
        else
            strategy_paths ← (working_dir ⨝ "Models/car$(N - 1).json")
        end
        open(outfile, "w") do io
            result = [verifyta_call..., model_path, queries_path] |> Cmd |> read |> String
            write(io, result)
        end
    end
end

status("All done.")