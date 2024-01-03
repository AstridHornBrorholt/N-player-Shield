### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 488ee430-40cf-11ee-3160-1f10b20c5be6
begin
	using Pkg
	Pkg.activate("..")
	using JSON
	using Glob
	using NaturalSort
end;

# ╔═╡ d2d9ca40-af15-4a65-910e-0319065cd6bf
# ╠═╡ skip_as_script = true
#=╠═╡
using PlutoUI; TableOfContents(title="Create Plant")
  ╠═╡ =#

# ╔═╡ 726706ba-dcd0-4816-9cec-ad63284a5cea
md"""
This is for the centralized controller as you can see in the folder this is stored in.
"""

# ╔═╡ 73225f3b-eed4-403b-a564-dad605862566
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

# ╔═╡ 7c2cdf08-7180-423a-9c36-55f4fc2ecc02
const ← = push!

# ╔═╡ a3f96a93-0f91-4b0e-8202-b52be3d7e14f
const ⨝ = joinpath

# ╔═╡ 1368afef-875a-4ca0-86eb-ba724a5213f4
const N_UNITS = 10

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

# ╔═╡ b8e7846b-e9aa-4d8f-a175-0c596f1ea4fb
#=╠═╡
isfile(shield_path)
  ╠═╡ =#

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
	create_fleet(blueprint_path, strategy_paths, destination; [checks])

**Arguments:**
- `blueprint_path`: Path to the blueprint for the Cruise Control "Fleet" UPPAAL model. It contains a number of `%template fields%` to be filled in by this function.
- `strategy_paths`: Vector of zero or more paths to exported UPPAAL strategies in json format. The number of strategies provided determines the number of cars in the fleet.
- `shield_path`: Path to the compiled safety strategy, `libshield.so`.
- `destination`: Output folder.
- `checks`: Number of traces to check in query files. (`E[<=100;\$checks] ...`).

Create model and query files `Fleet of n Cars.xml` and `Fleet of n Cars.q` at `destination`. `n` is given by the number of strategies provided. 

!!! example
		create_fleet("path/to/Fleet_blueprint.xml", ["strat1.json", "strat2.json", "strat3.json"], "libshield.so", "Output Folder")
		-> ("Output Folder/Fleet of 5 Cars.xml", "Output folder/Fleet of 5 Cars.q")
	If 3 previous strategies are provided, a fleet of 5 cars will be created: 1 random car in front, 3 pre-trained cars loaded as compiled stategies, and 1 new learner car. 
"""
function create_plant(blueprint_path,
		shield_path,
		destination;
		checks=100,
		skip_training=false)
	
	# UPPAAL wants absolute paths
	shield_path = abspath(shield_path)
	
	# Create output dir
	if destination |> isdir
	elseif destination |> dirname |> isdir
		mkdir(destination)
	else
		error("Invalid destination"; destination)
	end
	isdir(destination) || mkdir(destination)

	# Replacements.
	replacements = Dict{String, String}()
	replacements["%shield path%"] = shield_path
	replacements["%checks%"] = "$checks"

	# Apply replacements to blueprint
	model_path = destination ⨝ "Plant.xml"
	search_and_replace(blueprint_path, model_path, replacements)
	
	error_on_regex_in(model_path, r"%")

	# Note the queries are contained in the model this time.
	model_path
end;

# ╔═╡ 86082ab2-b9c3-4575-b878-b2734044e7d6
#=╠═╡
create_plant(blueprint_path, shield_path, output_dir)
  ╠═╡ =#

# ╔═╡ Cell order:
# ╟─726706ba-dcd0-4816-9cec-ad63284a5cea
# ╠═488ee430-40cf-11ee-3160-1f10b20c5be6
# ╠═d2d9ca40-af15-4a65-910e-0319065cd6bf
# ╟─73225f3b-eed4-403b-a564-dad605862566
# ╠═7c2cdf08-7180-423a-9c36-55f4fc2ecc02
# ╠═a3f96a93-0f91-4b0e-8202-b52be3d7e14f
# ╠═1368afef-875a-4ca0-86eb-ba724a5213f4
# ╠═5da6f4cd-96fa-4d58-9381-ca32b917efe5
# ╠═c9ec1aaa-3a82-4013-bd40-23ec4f06c900
# ╟─7e71404f-d60f-4042-9098-5522cfd5ee37
# ╠═695ffd13-dc54-48e0-a8a4-364cd938e640
# ╟─c5f3e21f-b929-41e1-81e2-7b0ec2dd0f28
# ╠═6ba15d9e-1490-47a3-ac77-288eae1dc281
# ╠═b8e7846b-e9aa-4d8f-a175-0c596f1ea4fb
# ╟─a87b61c0-fbf3-464c-ae7c-6aced2b0674d
# ╠═fade61a9-8136-4a4c-99a2-dee9bf79fd32
# ╠═499824b9-3f5e-4a77-9f0f-8637b3aa34f6
# ╠═9baf5bef-2632-4d4d-8ee6-17a58db86c1a
# ╟─a05921d4-4765-44bf-9592-b9d54de3ac65
# ╠═96aaff55-db70-4e32-b405-decad1a887c0
# ╠═86082ab2-b9c3-4575-b878-b2734044e7d6
