# This file supports both the version with the centralized shield and the non-centralized shield
# That is, 3-Car_blueprint as well as 3-Car Centralized_blueprint. 
# Now also the 3-Car Declared_blueprint. 

using Dates
# The emoji are there to distinguish different runs writing to the same output concurrently. This doesn't seem to be a problem after all but I enjoy the splash of colour.
emoji = ["🍭", "🎃", "😱", "👿", "👺", "👻", "💀", "👽", "🔮", "🕷", "🕸", "🍫", "🍬", "🖤", "🦇", "🦉", "🥀", "⛓", "🎭", "🗡", "🩸", "🪦", "🥸", "🫀"]
🍭🎃 = join(rand(emoji, 2), "")
function status(str) 
    time = Dates.format(Dates.now(), "dd/mm HH:MM")
    println("$time $🍭🎃 $str")
    flush(stdout)
end
using Pkg
Pkg.activate("..", io=devnull)

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
        "--repetition"
            arg_type=Int
            required=true
		"--results-dir"
			default=homedir() ⨝ "Results/N-player $(basename(pwd()))"
        "--verifyta-path"
            default=homedir() ⨝ "opt/uppaal-5.1.0-beta5-linux64/bin/verifyta.sh"
        "--blueprint-path"  
            default=pwd() ⨝ "../Centralized Shield/3-Car_blueprint.xml"
        "--shield-path"  
            default=pwd() ⨝ "./3-car.so"
        "--declared-action-shield-path"  
            default=pwd() ⨝ "./2-car-declared-action.so"
	end
end;

args = parse_args(s)

runs = args["runs"]
checks = args["checks"]
repetition = args["repetition"]
results_dir = args["results-dir"]
verifyta_path = args["verifyta-path"]
status("Starting... $((;runs, repetition))")

isdir(results_dir) || mkdir(results_dir) # Provoke error if path is invalid
isfile(verifyta_path) || error("File verifyta not found at path $verifyta_path")

blueprint_path = args["blueprint-path"]
shield_path = args["shield-path"]
declared_action_shield_path = args["declared-action-shield-path"]

isfile(shield_path) || error("Shield file not found at $shield_path")

shield_path′ = results_dir ⨝ basename(shield_path)
if !isfile(shield_path′) # All of a sudden it seems the tasks get sad when they overwrite each others' shield files
    cp(shield_path, shield_path′, force=true)
end
shield_path = shield_path′

isfile(declared_action_shield_path) || error("Shield file not found at $declared_action_shield_path")

shield_path′ = results_dir ⨝ basename(declared_action_shield_path)
if !isfile(shield_path′) # All of a sudden it seems the tasks get sad when they overwrite each others' shield files
    cp(declared_action_shield_path, shield_path′, force=true)
end
declared_action_shield_path = shield_path′

working_dir = results_dir ⨝ "$runs Runs"
working_dir = working_dir ⨝ "Repetition $repetition"
isdir(working_dir) || mkpath(working_dir)
query_results_dir = working_dir ⨝ "Query Results"
isdir(query_results_dir) || mkpath(query_results_dir)
models_dir = working_dir ⨝ "Models"
isdir(models_dir) || mkpath(models_dir)

name = replace(basename(blueprint_path), "_blueprint.xml" => "")

status("Running $name  (repetition=$repetition)")
outfile = query_results_dir ⨝ "$name.txt"
model_path, queries_path = create_fleet(blueprint_path, shield_path, declared_action_shield_path, models_dir; checks, name)

verifyta_args = "-s --epsilon 0.001 --max-iterations 1 --good-runs $runs --total-runs $runs --runs-pr-state $runs"
verifyta_call = String[
    verifyta_path,
    split(verifyta_args, " ")...
]
open(outfile, "w") do io
    result = [verifyta_call..., model_path, queries_path] |> Cmd |> read |> String
    write(io, result)
end
status("Done running $name.  (repetition=$repetition)")

status("All done.")