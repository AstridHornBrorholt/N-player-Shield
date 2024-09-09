### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 488ee430-40cf-11ee-3160-1f10b20c5be6
begin
	using JSON
	using Glob
	using ArgParse
end;

# ╔═╡ d2d9ca40-af15-4a65-910e-0319065cd6bf
# ╠═╡ skip_as_script = true
#=╠═╡
using PlutoUI
  ╠═╡ =#

# ╔═╡ 6373d2dc-e88f-4d65-bd3b-296210a0055c
md"""
# Create Fleet under Centralized Controller

## Main Feature
"""

# ╔═╡ 6d7cd65d-eb80-44e9-96a2-4a550bcf880b
@doc create_fleet

# ╔═╡ cd5910a1-5956-4521-865b-8f6b09665528
#=╠═╡
@bind fleet_size NumberField(2:100)
  ╠═╡ =#

# ╔═╡ 5da6f4cd-96fa-4d58-9381-ca32b917efe5
#=╠═╡
@bind output_dir TextField(70, default=mktempdir())
  ╠═╡ =#

# ╔═╡ a2ecd75b-532e-4d58-95a7-ff43407f2c69
#=╠═╡
readdir(output_dir)
  ╠═╡ =#

# ╔═╡ b579c580-c53a-4120-8eaa-2f5eeb122482
#=╠═╡
output_dir |> readdir
  ╠═╡ =#

# ╔═╡ 7cdd144c-a7b1-43cc-8529-5444968da708
md"""
## Preliminaries
"""

# ╔═╡ 7c3274af-4e24-4bcb-9766-e9e7e4f14422
html"""
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@400&display=swap" rel="stylesheet">
<style>

.cm-editor .cm-tooltip-autocomplete .cm-completionLabel, pluto-input .cm-editor .cm-content, pluto-input .cm-editor .cm-scroller {
  font-family: 'Fira Code' !important;
  font-size: .75rem;
  font-variant-ligatures: common-ligatures;
}
pluto-log-dot pre, pluto-output pre {
  display: inline-block;
  font-family: 'Fira Code' !important;
  font-size: .75rem;
  font-variant-ligatures: common-ligatures;
  margin: 0;
  tab-size: 4;
  -moz-tab-size: 4;
  white-space: pre-wrap;
  word-break: break-all;
}
</style>

<pre>Fira Code Loaded. Ligature check: -> --> <> == === !==|> </pre>
"""

# ╔═╡ 8edd344e-f194-4247-88a2-229a5cae24e5
← = push!

# ╔═╡ 872039bc-fec7-4338-b466-9faa353be1f0
⨝ = joinpath

# ╔═╡ 73225f3b-eed4-403b-a564-dad605862566
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

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
@bind shield_path TextField(80, default = "/home/asger/Documents/Files/AAU/PhD/Artikler/Multi-agent Shielding/N-player Experiments/CC Shield/libshield.so")
  ╠═╡ =#

# ╔═╡ b8e7846b-e9aa-4d8f-a175-0c596f1ea4fb
#=╠═╡
isfile(shield_path)
  ╠═╡ =#

# ╔═╡ 41bd6a0e-d6ff-4e40-8eb7-313eb069c74a
function system_declaration(fleet_size)
	result = String[]
	result ← "Random0 = Random(0);"
	for i in 1:fleet_size - 1
		result ← "Shield$i = Shield($i);"
		result ← "Learner$i = Learner($i);"
	end
	
	system = String[]
	system ← "system Dynamics"
	system ← "Decisions"
	system ← "Random0"
	for i in 1:fleet_size - 1
		system ← "Learner$i"
		system ← "Shield$i"
	end
	
	result ← join(system, ", ") * ";"
	
	join(result, "\n")
end

# ╔═╡ 09bf3c4b-acc9-4bcc-a730-b98bd3c27e36
system_declaration(1) |> multiline

# ╔═╡ ca86cb1d-4fab-4fe7-b89e-7c8e785a9de2
system_declaration(4) |> multiline

# ╔═╡ 87e6dab6-d7b4-4cfa-a2ca-64bb68fd86c8
function distances(fleet_size)
	join(["50" for i in 1:fleet_size - 1], ", ")
end

# ╔═╡ e2b8060b-b9cd-4123-a0dc-7317d5177fe3
distances(2)

# ╔═╡ 37ebb59c-2fe6-4a2e-8e41-fedf162c57c9
distances(4)

# ╔═╡ 02e79c81-018d-4362-996a-17ad7da9ce5d
md"""
## The query files

These will be easiest to generate in the same swoop.
"""

# ╔═╡ c7baa1ea-5252-4319-adfd-d003aa8ee0df
function queries(fleet_size, output_path; checks=1000, skip_training=false)
	result = String[]
	# Training or loading strategy

	statevars = ["velocity[$i]" for i in 0:fleet_size - 1]
	statevars = vcat(statevars, ["distance[$i]" for i in 0:fleet_size - 2])
	statevars = join(statevars, ", ")
	if !skip_training
		result ← "strategy centralized = minE(sum (i:int[0, fleetSize - 2]) D[i]) [<=100] {}->{$statevars}: <> time >= 100"
		result ← "saveStrategy(\"$output_path/centralized.json\", centralized)"
	else
		result ← "strategy centralized = loadStrategy{}->{$statevars} (\"$output_path/centralized.json\")"
	end
	# Learned performance
	for i in 0:fleet_size - 2
		result ← "E[<=100;$checks](max:D[$(i)]) under centralized"
	end
	# Probability of safety violation
	result ← "Pr[<=100;$checks]([] forall (i : int[0, fleetSize - 2]) (distance[i] > minDistance || distance[i] < maxDistance)) under centralized"

	join(result, "\n")
end

# ╔═╡ c5a94d34-c472-49ed-aeda-6b902ec2d173
queries(2, "/some/path") |> multiline

# ╔═╡ 2c37d3cb-4829-4e05-8ab7-15cf908b09ad
queries(4, "/some/path") |> multiline

# ╔═╡ a87b61c0-fbf3-464c-ae7c-6aced2b0674d
md"""
## Applying it to the Blueprint
"""

# ╔═╡ fade61a9-8136-4a4c-99a2-dee9bf79fd32
#=╠═╡
@bind blueprint_path TextField(80, default="/home/asger/Documents/Files/AAU/PhD/Artikler/Multi-agent Shielding/N-player Experiments/Fleet_blueprint.xml")
  ╠═╡ =#

# ╔═╡ a0e02d1a-0355-4496-9b18-70f53c67a389
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
- `shield_path`: Path to the compiled safety strategy, `libshield.so`.
- `fleet_size`: Total number of cars in the fleet. There will be `fleet_size - 1` cars controlled by the central learner, and 1 random car.
- `destination`: Output folder.
- `checks`: Number of traces to check in query files. (`E[<=100;\$checks] ...`).

Create model and query files "`Fleet of fleet_size Cars.xml`" and "`Fleet of fleet_size Cars.q`" at `destination`. 
"""
function create_fleet(blueprint_path,
		shield_path, 
		fleet_size,
		destination; 
		checks=100,
		skip_training=false)
	
	shield_path = abspath(shield_path) # UPPAAL wants absolute paths
	
	# Create output dir
	if destination |> isdir
	elseif destination |> dirname |> isdir
		mkdir(destination)
	else
		error("Invalid destination"; destination)
	end
	isdir(destination) || mkdir(destination)

	# Compute replacements
	replacements = Dict{String, String}()
	replacements["%shield path%"] = "\"$shield_path\""
	replacements["%fleet size%"] = fleet_size |> string
	replacements["%distances%"] = distances(fleet_size)
	replacements["%imports%"] = ""
	replacements["%agent selector%"] = ""
	replacements["%system declaration%"] = system_declaration(fleet_size)
	

	# Apply replacements to blueprint
	model_path = destination ⨝ "Fleet of $fleet_size Cars.xml"
	search_and_replace(blueprint_path, model_path, replacements)
	
	error_on_regex_in(model_path, r"%")

	# Save queries, too
	queries_path = destination ⨝ "Fleet of $fleet_size Cars.q"
	open(queries_path, "w") do query_file
		q = queries(fleet_size, destination; checks, skip_training)
		print(query_file, q)
	end

	model_path, queries_path
end;

# ╔═╡ dfac541d-214e-4ec5-8b78-b7cbe9b740ad
#=╠═╡
create_fleet(blueprint_path, shield_path, fleet_size, output_dir)
  ╠═╡ =#

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
ArgParse = "c7e460c6-2fb9-53a9-8c5b-16f535851c63"
Glob = "c27321d9-0574-5035-807b-f59d2c89b15c"
JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
ArgParse = "~1.1.4"
Glob = "~1.3.1"
JSON = "~0.21.4"
PlutoUI = "~0.7.52"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.2"
manifest_format = "2.0"
project_hash = "cd3176838ef7b2a62c9199d3401fcf1fa4c6fb3b"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "91bd53c39b9cbfb5ef4b015e8b582d344532bd0a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.0"

[[deps.ArgParse]]
deps = ["Logging", "TextWrap"]
git-tree-sha1 = "3102bce13da501c9104df33549f511cd25264d7d"
uuid = "c7e460c6-2fb9-53a9-8c5b-16f535851c63"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Glob]]
git-tree-sha1 = "97285bbd5230dd766e9ef6749b80fc617126d496"
uuid = "c27321d9-0574-5035-807b-f59d2c89b15c"
version = "1.3.1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "d75853a0bdbfb1ac815478bacd89cd27b550ace6"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.3"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "716e24b21538abc91f6205fd1d8363f39b442851"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.7.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "e47cd150dbe0443c3a3651bc5b9cbd5576ab75b7"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.52"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "7eb1686b4f04b82f96ed7a4ea5890a4f0c7a09f1"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TextWrap]]
git-tree-sha1 = "9250ef9b01b66667380cf3275b3f7488d0e25faf"
uuid = "b718987f-49a8-5099-9789-dcd902bef87d"
version = "1.0.1"

[[deps.Tricks]]
git-tree-sha1 = "aadb748be58b492045b4f56166b5188aa63ce549"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.7"

[[deps.URIs]]
git-tree-sha1 = "b7a5e99f24892b6824a954199a45e9ffcc1c70f0"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─6373d2dc-e88f-4d65-bd3b-296210a0055c
# ╠═6d7cd65d-eb80-44e9-96a2-4a550bcf880b
# ╠═cd5910a1-5956-4521-865b-8f6b09665528
# ╠═5da6f4cd-96fa-4d58-9381-ca32b917efe5
# ╠═a2ecd75b-532e-4d58-95a7-ff43407f2c69
# ╠═b579c580-c53a-4120-8eaa-2f5eeb122482
# ╟─7cdd144c-a7b1-43cc-8529-5444968da708
# ╠═488ee430-40cf-11ee-3160-1f10b20c5be6
# ╟─7c3274af-4e24-4bcb-9766-e9e7e4f14422
# ╠═d2d9ca40-af15-4a65-910e-0319065cd6bf
# ╠═8edd344e-f194-4247-88a2-229a5cae24e5
# ╠═872039bc-fec7-4338-b466-9faa353be1f0
# ╟─73225f3b-eed4-403b-a564-dad605862566
# ╠═695ffd13-dc54-48e0-a8a4-364cd938e640
# ╟─c5f3e21f-b929-41e1-81e2-7b0ec2dd0f28
# ╠═6ba15d9e-1490-47a3-ac77-288eae1dc281
# ╠═b8e7846b-e9aa-4d8f-a175-0c596f1ea4fb
# ╠═41bd6a0e-d6ff-4e40-8eb7-313eb069c74a
# ╠═09bf3c4b-acc9-4bcc-a730-b98bd3c27e36
# ╠═ca86cb1d-4fab-4fe7-b89e-7c8e785a9de2
# ╠═87e6dab6-d7b4-4cfa-a2ca-64bb68fd86c8
# ╠═e2b8060b-b9cd-4123-a0dc-7317d5177fe3
# ╠═37ebb59c-2fe6-4a2e-8e41-fedf162c57c9
# ╟─02e79c81-018d-4362-996a-17ad7da9ce5d
# ╠═c7baa1ea-5252-4319-adfd-d003aa8ee0df
# ╠═c5a94d34-c472-49ed-aeda-6b902ec2d173
# ╠═2c37d3cb-4829-4e05-8ab7-15cf908b09ad
# ╟─a87b61c0-fbf3-464c-ae7c-6aced2b0674d
# ╠═fade61a9-8136-4a4c-99a2-dee9bf79fd32
# ╠═a0e02d1a-0355-4496-9b18-70f53c67a389
# ╠═9baf5bef-2632-4d4d-8ee6-17a58db86c1a
# ╠═a05921d4-4765-44bf-9592-b9d54de3ac65
# ╠═96aaff55-db70-4e32-b405-decad1a887c0
# ╠═dfac541d-214e-4ec5-8b78-b7cbe9b740ad
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
