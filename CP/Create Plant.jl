### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# ╔═╡ 488ee430-40cf-11ee-3160-1f10b20c5be6
begin
	using Pkg
	Pkg.activate("..")
	using JSON
	using Glob
	using ArgParse
	using NaturalSort
	include("./Strategy to C.jl")
end;

# ╔═╡ d2d9ca40-af15-4a65-910e-0319065cd6bf
# ╠═╡ skip_as_script = true
#=╠═╡
using PlutoUI; TableOfContents(title="Create Plant")
  ╠═╡ =#

# ╔═╡ 5da6f4cd-96fa-4d58-9381-ca32b917efe5
#=╠═╡
@bind output_dir TextField(70, default=mktempdir())
  ╠═╡ =#

# ╔═╡ c9ec1aaa-3a82-4013-bd40-23ec4f06c900
#=╠═╡
@bind open_output_dir_button CounterButton("Open output_dir")
  ╠═╡ =#

# ╔═╡ 7e71404f-d60f-4042-9098-5522cfd5ee37
#=╠═╡
if open_output_dir_button > 0
	run(`nautilus $output_dir`, wait=false);
else
	"code that opens output_dir"
end
  ╠═╡ =#

# ╔═╡ 73225f3b-eed4-403b-a564-dad605862566
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

# ╔═╡ 1368afef-875a-4ca0-86eb-ba724a5213f4
const N_UNITS = 10

# ╔═╡ 627b26ba-0479-41fd-9b0d-94df3c1d3ae0
#=╠═╡
@bind number_of_strategies NumberField(0:10, default=2)
  ╠═╡ =#

# ╔═╡ 7c2cdf08-7180-423a-9c36-55f4fc2ecc02
const ← = push!

# ╔═╡ a3f96a93-0f91-4b0e-8202-b52be3d7e14f
const ⨝ = joinpath

# ╔═╡ 18664fb8-d399-4fc0-ba01-96ffe552a8ce
md"""
## Compiling the Strategies
"""

# ╔═╡ 303b180c-274c-4a29-b786-660fae7209b8
#=╠═╡
function strategy_paths_input(number_of_strategies)
	
	return PlutoUI.combine() do Child
		names = ["$i" for i in 10:-1:number_of_strategies]
		inputs = [
			md""" $(name): $(
				Child(name, TextField(70, default = homedir() ⨝ "Results/N-player CP/5000 Runs/Repetition 1/Models/unit" * name * ".json"))
			)"""
			
			for name in names
		]
		
		md"""
		#### Strategy paths
		$(inputs)
		"""
	end
end
  ╠═╡ =#

# ╔═╡ 5daa0ac6-d6c5-4ca7-8f7c-d3efdf89d66b
#=╠═╡
@bind strategy_paths strategy_paths_input(number_of_strategies)
  ╠═╡ =#

# ╔═╡ 9c5f6402-1cc5-4922-a3b3-02676c15b36d
#=╠═╡
[isfile(s) for s in strategy_paths]
  ╠═╡ =#

# ╔═╡ efadb6e4-e1ea-4d5f-87f0-85e4532d3fbc
# Ok so the function strategy_to_c takes this `vars` argument. It is the observable point variables of the exported strategy. The `get_action_unitX` function will include these vars as arguments, in addition to the set of allowed actions.
vars = [
	"t",
	"stored"
]
#=
vars = [
	"t",
	"stored1",
	"stored2",
	"stored3",
	"stored4",
	"stored5",
	"stored6",
	"stored7",
	"stored8",
	"stored9",
	"stored10",
]
=#

# ╔═╡ 9228d33d-bfe8-4c96-9e11-815fa674a5b6
# From "Strategy to C.jl"
actions

# ╔═╡ 265701e4-9cd6-4834-af7d-df02bbd976ec
function strategies_to_c(strategy_paths, vars, output_dir)
	result = Tuple{String, String}[]
	for strategy_path in strategy_paths
		!isfile(strategy_path) && error("No such file: $strategy_path")
		result ← strategy_to_c(strategy_path, vars, actions, output_dir)
		strategy_path == output_dir ⨝ basename(strategy_path) || 		cp(strategy_path, output_dir ⨝ basename(strategy_path), force=true)
	end
	result
end

# ╔═╡ 91f00f7e-43b7-47c5-970b-ee4f0c6100b4
#=╠═╡
if all(isfile(strategy_path) for strategy_path in strategy_paths) && isdir(output_dir)
	strategies = strategies_to_c(strategy_paths, vars, output_dir)
else
	strategies = [
		("int get_action_somestrategy1(double velocity, etc etc)", "path/to/lib1.so")
		("int get_action_somestrategy2(double velocity, etc etc)", "path/to/lib2.so")
		("int get_action_somestrategy3(double velocity, etc etc)", "path/to/lib3.so")
		("int get_action_somestrategy4(double velocity, etc etc)", "path/to/lib4.so")
	]
	"One or more strat paths invalid, or output dir invalid."
end
  ╠═╡ =#

# ╔═╡ 695ffd13-dc54-48e0-a8a4-364cd938e640
#=╠═╡
readdir(output_dir)
  ╠═╡ =#

# ╔═╡ c5f3e21f-b929-41e1-81e2-7b0ec2dd0f28
md"""
## Filling out the Template Fields

Fields in the blueprint surrouned with `%`. Functions or variable names here are meant to correspond to field names.
"""

# ╔═╡ 6ba15d9e-1490-47a3-ac77-288eae1dc281
#=╠═╡
@bind shield_path TextField(80, default = pwd() ⨝ "libcpshield.so")
  ╠═╡ =#

# ╔═╡ e5d66dda-5deb-473e-bac7-bb06a1dc769f
#=╠═╡
@bind one_outgoing_shield_path TextField(80, default = pwd() ⨝ "libcponeoutgoingshield.so")
  ╠═╡ =#

# ╔═╡ b8e7846b-e9aa-4d8f-a175-0c596f1ea4fb
#=╠═╡
isfile(shield_path)
  ╠═╡ =#

# ╔═╡ b8cbdf1d-d4fd-48cc-b38c-3d603a632efd
#=╠═╡
isfile(one_outgoing_shield_path)
  ╠═╡ =#

# ╔═╡ 3e9b8c0e-c014-4052-8031-4cd4b8c91177
md"""
### Imports
"""

# ╔═╡ e5e56986-4728-480e-8c07-cb78c61e9579
function imports(strategies::T) where T <: AbstractVector{Tuple{String, String}}
	result = String[]
	for (signature, path) in strategies |> unique
		result ← "import \"$path\""
		result ← "{"
		result ← "\t" * signature * ";"
		result ← "};\n"
	end
	join(result, "\n")
end

# ╔═╡ d642235d-8da6-4a9c-b346-1c01ba5ef885
#=╠═╡
imports(strategies) |> multiline
  ╠═╡ =#

# ╔═╡ bb6cbc9e-0782-4fcb-9c4a-708494afba4c
md"""
### Agent Selector
"""

# ╔═╡ 468c1f4a-a306-4a16-aa42-dc7e7728d959
function name_from_signature(signature)
	# Trust me on this one.
	without_type = signature[findfirst((==)(' '), signature) + 1:end]
	without_type[1:findfirst((==)('('), without_type) - 1]
end

# ╔═╡ dcf332e0-2f37-4354-9e71-68529882f2b2
#=╠═╡
signature = strategies[1][1]
  ╠═╡ =#

# ╔═╡ 90043fd6-5214-4d4b-8e3f-cd2427a90b28
#=╠═╡
name_from_signature(signature)
  ╠═╡ =#

# ╔═╡ 654632ba-3f6a-4453-81fb-24d7bc566a69
function agent_selector(strategies)
	if length(strategies) == 0
		return "if (false) { return 0; }"
	end
	result = String[]
	for (i, (signature, path)) in enumerate(strategies)
		fname = name_from_signature(signature)
		j = N_UNITS - i + 1 # count down not up
		if j == N_UNITS
			result ← "    if (id == $N_UNITS)"
		else
			result ← "    else if (id == $j)"
		end
		result ←     "        return $fname(t, stored[$j], allowed.wait,  allowed.input_one, allowed.input_two, allowed.input_three);"
	end
	join(result, "\n")
end

# ╔═╡ 8b72ad52-5e5f-4321-9834-027c8739a215
agent_selector([]) |> multiline

# ╔═╡ 81a2de17-4954-4110-a39b-b775c85c9dfb
#=╠═╡
agent_selector(strategies) |> multiline
  ╠═╡ =#

# ╔═╡ fb092fa8-f26d-42c0-b868-93433809ab36
md"""
### System Declaration
"""

# ╔═╡ 41bd6a0e-d6ff-4e40-8eb7-313eb069c74a
function units(number_of_strategies)
	result = Dict()
	for i in 1:number_of_strategies
			result["%unit $(N_UNITS - i + 1)%"] = "PreTrainedProductionUnit"
	end
	result["%unit $(N_UNITS - number_of_strategies)%"] = "ControllableProductionUnit"
	for i in (N_UNITS - number_of_strategies - 1):-1:1
		result["%unit $i%"] = "RandomProductionUnit"
	end
	result
end

# ╔═╡ 960489b5-d302-4317-bdbe-de8491eaba94
function pretty_dict(dict)
	sort(collect(dict), by=x -> x[1], lt=natural)
end

# ╔═╡ c9c5938f-13ec-496f-afbf-a05f85f32376
units(0) |> pretty_dict

# ╔═╡ 09bf3c4b-acc9-4bcc-a730-b98bd3c27e36
units(1) |> pretty_dict

# ╔═╡ ca86cb1d-4fab-4fe7-b89e-7c8e785a9de2
units(4) |> pretty_dict

# ╔═╡ 02e79c81-018d-4362-996a-17ad7da9ce5d
md"""
### The query files

These will be easiest to generate in the same swoop.
"""

# ╔═╡ c7baa1ea-5252-4319-adfd-d003aa8ee0df
function queries(number_of_strategies, output_path; 
		checks=1000, 
		skip_training=false)
	
	result = String[]
	# Index of the unit that will be trained/loaded
	i = N_UNITS - number_of_strategies
	# Cross-checking outcomes of previous (c-compiled) strategies
	result ← "E[<=100;$checks](max:cost[$i])"
	result ← "E[<=100;$checks](max:sum (i : providerid_t) cost[i])"
	if !skip_training
		result ← "strategy unit$i = minE(cost[$i]) [<=100] {}->{t, stored[$i]}: <> time >= 100"
		result ← "saveStrategy(\"$output_path/unit$i.json\", unit$i)"
	else
		result ← "strategy unit$i = loadStrategy{}->{t, stored[$i]} (\"$output_path/unit$i.json\")"
	end
	# Learned performance
	result ← "E[<=100;$checks](max:cost[$i]) under unit$i"
	result ← "E[<=100;$checks](max:sum (i : providerid_t) cost[i]) under unit$i"
	# Probability of safety violation
	result ← "Pr[<=100;$checks] (<> forall (i : unitid_t) (MIN_STORED < stored[i] && stored[i] < MAX_STORED)) under unit$i"

	join(result, "\n")
end

# ╔═╡ b4a1cd41-d5ea-4256-9639-6eba84c6d356
queries(0, "/some/path") |> multiline

# ╔═╡ c5a94d34-c472-49ed-aeda-6b902ec2d173
queries(1, "/some/path") |> multiline

# ╔═╡ 2c37d3cb-4829-4e05-8ab7-15cf908b09ad
queries(4, "/some/path") |> multiline

# ╔═╡ 97088511-1745-46c0-8e78-4670bac3ce18
queries(4, "/some/path", skip_training=true) |> multiline

# ╔═╡ a87b61c0-fbf3-464c-ae7c-6aced2b0674d
md"""
## Applying it to the Blueprint
"""

# ╔═╡ fade61a9-8136-4a4c-99a2-dee9bf79fd32
#=╠═╡
@bind blueprint_path TextField(80, default=pwd() ⨝ "Plant_blueprint.xml")
  ╠═╡ =#

# ╔═╡ 499824b9-3f5e-4a77-9f0f-8637b3aa34f6
#=╠═╡
isfile(blueprint_path)
  ╠═╡ =#

# ╔═╡ 9baf5bef-2632-4d4d-8ee6-17a58db86c1a
function search_and_replace(input_path, output_path, replacements)
	file = input_path |> read |> String
	outfile = output_path
	
	open(outfile, "w") do io
		for line in split(file, "\n")
			line′ = replace(line, replacements...)
			println(io, line′)
		end
	end
end

# ╔═╡ a05921d4-4765-44bf-9592-b9d54de3ac65
# Use to check that everything's been serach-and-replace'd.
# r"%[a-zA-Z_ ]+%" to match %template_variables%
function error_on_regex_in(dir, expression, glob_pattern="*")
	pattern_found = false
	if isdir(dir)
		for filename in glob(glob_pattern, dir)
			
			file = filename |> read |> String
			line_number = 1
			for line in split(file, "\n")
				m = match(expression, line)
				if m != nothing
					@error("Pattern found", line, filename, line_number)
				end
				line_number += 1
			end
		end
	elseif isfile(dir)
		file = dir |> read |> String
		line_number = 1
		for line in split(file, "\n")
			m = match(expression, line)
			if m != nothing
				@error("Pattern found", line, dir, line_number)
			end
			line_number += 1
		end
	else
		error("Invalid path"; dir)
	end
	if pattern_found
		error("A pattern was found wich indicates an error. See previous error logs.")
	end
end

# ╔═╡ 96aaff55-db70-4e32-b405-decad1a887c0
"""
	create_plant(blueprint_path, strategy_paths, destination; [checks])

**Arguments:**
- `blueprint_path`: Path to the blueprint for the Cruise Control "Fleet" UPPAAL model. It contains a number of `%template fields%` to be filled in by this function.
- `strategy_paths`: Vector of zero or more paths to exported UPPAAL strategies in json format. Strategies are applied in reverse order, i.e. the first strategy in the array is applied to the highest ID unit.
- `shield_path`: Path to the compiled safety strategy, `libshield.so`.
- `destination`: Output folder.
- `checks`: Number of traces to check in query files. (`E[<=100;\$checks] ...`).
- `skip_training`: If true, will attempt to load an existing strategy rather than train and save one.

Create model and query files `Plant n.xml` and `Plant n.q` at `destination`. `n` is given by the number of strategies provided. 
"""
function create_plant(blueprint_path, 
		strategy_paths, 
		shield_path,
		one_outgoing_shield_path,
		destination; 
		checks=100,
		skip_training=false)
	
	# UPPAAL wants absolute paths
	strategy_paths = [abspath(p) for p in strategy_paths if p != ""]
	shield_path = abspath(shield_path)
	
	# Create output dir
	if destination |> isdir
	elseif destination |> dirname |> isdir
		mkdir(destination)
	else
		error("Invalid destination"; destination)
	end
	isdir(destination) || mkdir(destination)
	

	# Compile strategies
	strategies = strategies_to_c(strategy_paths, vars, destination)

	# Compute replacements
	replacements = Dict{String, String}()
	replacements["%shield path%"] = shield_path
	replacements["%one outgoing shield path%"] = one_outgoing_shield_path
	number_of_strategies = length(strategy_paths)
	replacements["%strategy imports%"] = imports(strategies)
	replacements["%agent selector%"] = agent_selector(strategies;)
	replacements = merge(replacements, units(number_of_strategies))

	# Apply replacements to blueprint
	model_path = destination ⨝ "Plant $number_of_strategies.xml"
	search_and_replace(blueprint_path, model_path, replacements)
	
	error_on_regex_in(model_path, r"%")

	# Save queries, too
	queries_path = destination ⨝ "Plant $number_of_strategies.q"
	open(queries_path, "w") do query_file
		q = queries(number_of_strategies, destination; checks, skip_training)
		print(query_file, q)
	end

	model_path, queries_path
end;

# ╔═╡ 86082ab2-b9c3-4575-b878-b2734044e7d6
#=╠═╡
create_plant(blueprint_path,
	strategy_paths,
	shield_path,
	one_outgoing_shield_path,
	output_dir)
  ╠═╡ =#

# ╔═╡ 2f3b6b52-56bb-4324-9dd1-1c08921bc2f2
#=╠═╡
@bind open_folder_button CounterButton("Open Folder")
  ╠═╡ =#

# ╔═╡ df983779-baf4-419a-81be-999e3cd9493a
#=╠═╡
if open_folder_button > 0
	run(`nautilus $output_dir`, wait=false)
end; Markdown.parse("    nautilus $output_dir")
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═488ee430-40cf-11ee-3160-1f10b20c5be6
# ╠═5da6f4cd-96fa-4d58-9381-ca32b917efe5
# ╠═c9ec1aaa-3a82-4013-bd40-23ec4f06c900
# ╟─7e71404f-d60f-4042-9098-5522cfd5ee37
# ╠═d2d9ca40-af15-4a65-910e-0319065cd6bf
# ╟─73225f3b-eed4-403b-a564-dad605862566
# ╠═1368afef-875a-4ca0-86eb-ba724a5213f4
# ╠═627b26ba-0479-41fd-9b0d-94df3c1d3ae0
# ╠═7c2cdf08-7180-423a-9c36-55f4fc2ecc02
# ╠═a3f96a93-0f91-4b0e-8202-b52be3d7e14f
# ╟─18664fb8-d399-4fc0-ba01-96ffe552a8ce
# ╠═5daa0ac6-d6c5-4ca7-8f7c-d3efdf89d66b
# ╠═9c5f6402-1cc5-4922-a3b3-02676c15b36d
# ╟─303b180c-274c-4a29-b786-660fae7209b8
# ╠═efadb6e4-e1ea-4d5f-87f0-85e4532d3fbc
# ╠═9228d33d-bfe8-4c96-9e11-815fa674a5b6
# ╠═265701e4-9cd6-4834-af7d-df02bbd976ec
# ╠═91f00f7e-43b7-47c5-970b-ee4f0c6100b4
# ╠═695ffd13-dc54-48e0-a8a4-364cd938e640
# ╟─c5f3e21f-b929-41e1-81e2-7b0ec2dd0f28
# ╠═6ba15d9e-1490-47a3-ac77-288eae1dc281
# ╠═e5d66dda-5deb-473e-bac7-bb06a1dc769f
# ╠═b8e7846b-e9aa-4d8f-a175-0c596f1ea4fb
# ╠═b8cbdf1d-d4fd-48cc-b38c-3d603a632efd
# ╟─3e9b8c0e-c014-4052-8031-4cd4b8c91177
# ╠═e5e56986-4728-480e-8c07-cb78c61e9579
# ╠═d642235d-8da6-4a9c-b346-1c01ba5ef885
# ╟─bb6cbc9e-0782-4fcb-9c4a-708494afba4c
# ╠═468c1f4a-a306-4a16-aa42-dc7e7728d959
# ╠═dcf332e0-2f37-4354-9e71-68529882f2b2
# ╠═90043fd6-5214-4d4b-8e3f-cd2427a90b28
# ╠═654632ba-3f6a-4453-81fb-24d7bc566a69
# ╠═8b72ad52-5e5f-4321-9834-027c8739a215
# ╠═81a2de17-4954-4110-a39b-b775c85c9dfb
# ╟─fb092fa8-f26d-42c0-b868-93433809ab36
# ╠═41bd6a0e-d6ff-4e40-8eb7-313eb069c74a
# ╠═960489b5-d302-4317-bdbe-de8491eaba94
# ╠═c9c5938f-13ec-496f-afbf-a05f85f32376
# ╠═09bf3c4b-acc9-4bcc-a730-b98bd3c27e36
# ╠═ca86cb1d-4fab-4fe7-b89e-7c8e785a9de2
# ╟─02e79c81-018d-4362-996a-17ad7da9ce5d
# ╠═c7baa1ea-5252-4319-adfd-d003aa8ee0df
# ╠═b4a1cd41-d5ea-4256-9639-6eba84c6d356
# ╠═c5a94d34-c472-49ed-aeda-6b902ec2d173
# ╠═2c37d3cb-4829-4e05-8ab7-15cf908b09ad
# ╠═97088511-1745-46c0-8e78-4670bac3ce18
# ╟─a87b61c0-fbf3-464c-ae7c-6aced2b0674d
# ╠═fade61a9-8136-4a4c-99a2-dee9bf79fd32
# ╠═499824b9-3f5e-4a77-9f0f-8637b3aa34f6
# ╠═9baf5bef-2632-4d4d-8ee6-17a58db86c1a
# ╠═a05921d4-4765-44bf-9592-b9d54de3ac65
# ╠═96aaff55-db70-4e32-b405-decad1a887c0
# ╠═86082ab2-b9c3-4575-b878-b2734044e7d6
# ╟─2f3b6b52-56bb-4324-9dd1-1c08921bc2f2
# ╟─df983779-baf4-419a-81be-999e3cd9493a
