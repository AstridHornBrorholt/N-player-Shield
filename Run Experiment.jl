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
		"--results-dir"
			default=homedir() ⨝ "Results/N-player CC"
        "--verifyta-path"
            default=homedir() ⨝ "opt/uppaal-5.0.0-linux64/bin/verifyta.sh"
        "--blueprint-path"  
            default=pwd() ⨝ "Fleet_blueprint.xml"
        "--shield-path"  
            default=pwd() ⨝ "Shield/libshield.so"
	end
end;

args = parse_args(s)

runs = args["runs"]
checks = args["checks"]
max_cars = args["max-cars"]
results_dir = args["results-dir"]
verifyta_path = args["verifyta-path"]

verifyta_args = "-s --epsilon 0.001 --max-iterations 1 --good-runs $runs --total-runs $runs --runs-pr-state $runs"

blueprint_path = args["blueprint-path"]
shield_path = args["shield-path"]

verifyta_call = String[
    verifyta_path,
    split(verifyta_args, " ")...
]

isdir(results_dir) || mkdir(results_dir)
results_dir = results_dir ⨝ "$runs"
isdir(results_dir) || mkdir(results_dir)
query_results_dir = results_dir ⨝ "Query Results"
isdir(query_results_dir) || mkpath(query_results_dir)

strategy_paths = String[]
for N in 2:max_cars
    status("Running Fleet of $N Cars...")
    outfile = query_results_dir ⨝ "Fleet of $N Cars.txt"
    model_path, queries_path = create_fleet(blueprint_path, strategy_paths, shield_path, results_dir; checks)
    strategy_paths ← (results_dir ⨝ "Models/car$(N - 1).json")
    open(outfile, "w") do io
        result = [verifyta_call..., model_path, queries_path] |> Cmd |> read |> String
        write(io, result)
    end
end

status("All done.")