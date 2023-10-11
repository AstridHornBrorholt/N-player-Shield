using Dates
# The emoji are there to distinguish different runs writing to the same output concurrently. This doesn't seem to be a problem after all but I enjoy the splash of colour.
emoji = "🌈🌟✨🌌🌍💧⛅🌊🌞🌛"
🌈🌞 = join(rand(emoji, 2), "")
function status(str) 
    time = Dates.Time(Dates.now())
    println("$time $🌈🌞 $str")
    flush(stdout)
end
using Pkg
Pkg.activate("..")

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
        "--fleet-size"
            arg_type=Int
            required=true
        "--repetition"
            arg_type=Int
            required=true
		"--results-dir"
			default=homedir() ⨝ "Results/N-player CC Centralized"
        "--verifyta-path"
            default=homedir() ⨝ "opt/uppaal-5.0.0-linux64/bin/verifyta.sh"
        "--blueprint-path"  
            default=pwd() ⨝ "../Fleet_blueprint.xml"
        "--shield-path"  
            default=pwd() ⨝ "../Shield/libshield.so"
        "--skip-training"
            action=:store_true
	end
end;

args = parse_args(s)

runs = args["runs"]
checks = args["checks"]
fleet_size = args["fleet-size"]
repetition = args["repetition"]
results_dir = args["results-dir"]
verifyta_path = args["verifyta-path"]
skip_training = args["skip-training"]
status("Starting... $((;runs, fleet_size, repetition, skip_training))")

isdir(results_dir) || mkdir(results_dir) # Provoke error if path is invalid
isfile(verifyta_path) || error("File verifyta not found at path $verifyta_path")


blueprint_path = args["blueprint-path"]
shield_path = args["shield-path"]

isfile(shield_path) || error("Shield file not found at $shield_path")

shield_path′ = results_dir ⨝ basename(shield_path)
cp(shield_path, shield_path′, force=true)
shield_path = shield_path′

working_dir = results_dir ⨝ "$runs Runs"
working_dir = working_dir ⨝ "Repetition $repetition"
isdir(working_dir) || mkpath(working_dir)
query_results_dir = working_dir ⨝ "Query Results"
isdir(query_results_dir) || mkpath(query_results_dir)
models_dir = working_dir ⨝ "Models"
isdir(models_dir) || mkpath(models_dir)

status("Running Fleet of $fleet_size Cars...  (repetition=$repetition)")
outfile = query_results_dir ⨝ "Fleet of $fleet_size Cars.txt"
model_path, queries_path = create_fleet(blueprint_path, shield_path, fleet_size, models_dir; checks, skip_training)

runs′ = runs*(fleet_size - 1) # Same number of training runs as would have been spent training each car after the other.
verifyta_args = "-s --epsilon 0.001 --max-iterations 1 --good-runs $runs′ --total-runs $runs′ --runs-pr-state $runs′"
verifyta_call = String[
    verifyta_path,
    split(verifyta_args, " ")...
]
open(outfile, "w") do io
    result = [verifyta_call..., model_path, queries_path] |> Cmd |> read |> String
    write(io, result)
end
status("Done running Fleet of $fleet_size Cars.  (repetition=$repetition)")

status("All done.")