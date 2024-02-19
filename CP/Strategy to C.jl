### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ fc499f82-3c3c-11ee-109a-f534985c8341
begin
	using JSON
	using Printf
end

# ╔═╡ 5615668e-7020-43b2-9a97-07dbca4aa115
# ╠═╡ skip_as_script = true
#=╠═╡
using PlutoUI
  ╠═╡ =#

# ╔═╡ 7161e853-49b1-468e-a4ba-949c34ef2da2
md"""
# Strategy to C

Turn a UPPAAL strategy exported as JSON into a C shared object which can be loaded back into UPPAAL.

This Pluto notebook is also a valid julia-script which provides the following funciton: 
## `strategy_to_c`
$(@doc strategy_to_c)
"""

# ╔═╡ a63ee558-5b46-4827-ae1a-95fa633e30d5
html"""
<style>
pluto-editor {
	background-image: url("https://www.freevector.com/uploads/vector/preview/30278/Red_Flower_Pattern.jpg");
}
pluto-notebook {
	background: none;
}

pluto-output  {
	border-radius: 4pt;
	padding: 4pt;
}

pluto-input .cm-editor {
	background: #fafafafa;
}

pluto-cell.code_differs .cm-editor .cm-gutters {
	background: #c8dcfa;
}

body:not(.___) pluto-cell.code_differs > pluto-trafficlight {
	background: #b4caed;
	border-left-color: #b4caed;
}

body:not(.___) pluto-cell.errored > pluto-trafficlight {
	background: #ffa18a;
}

body:not(.___) pluto-cell:focus-within > pluto-trafficlight {
	background: #b4caed;
}
</style>

<p>🎨 Custom style sheet loaded.</p>
"""

# ╔═╡ c5cde56e-cd4b-4509-a739-d8281a7c5248
const ⨝ = joinpath

# ╔═╡ b727f3d0-11a2-4150-80ad-e6bccd2b7017
#=╠═╡
@bind strategy_path TextField(80, default=pwd() ⨝ "../Strategies/moneydollars.json")
  ╠═╡ =#

# ╔═╡ 451b36a9-9712-42ac-b53e-e2031c978ec2
#=╠═╡
text = strategy_path |> read |> String
  ╠═╡ =#

# ╔═╡ 46d36365-2146-4094-9bd7-15310269e746
#=╠═╡
json = JSON.parse(text)
  ╠═╡ =#

# ╔═╡ c78f40f4-945c-4ee0-ad4e-8b47a734f222
#=╠═╡
Markdown.parse("""
!!! info "Actions" 
$(join(["    **$k** => $v" for (k,v) in sort(collect(json["actions"]), by=((k) ->  parse(Int, k[1])))], "\n\n"))
""")
  ╠═╡ =#

# ╔═╡ f2b82444-77da-4ec5-9991-186f609d9576
# "Closed", "Open" for each of the 3 pipes
actions = Dict(
	"0" => "CCO",
	"1" => "COC",
	"2" => "OCC",
	"3" => "CCC",
	"4" => "OOC",
	"5" => "COO",
	"6" => "OCO",
	"7" => "OOO",
)

# ╔═╡ 74ff2ba2-dbf6-45c4-bba9-ea7c38269666
# Check if the action given in the "actions" dictionary
# matches the edge descriptions given in the strategy.
function matches(action::String, uppaal_action::String; show_msg=true)
	for (i, pipe_status) in enumerate(action)
		# The UPPAAL action contains this string if the pipe is open.
		pipe_enabled = "pipe$i := pipe$i +"
		if pipe_status == 'C'
			if occursin(pipe_enabled, uppaal_action)
				show_msg && @error "Pipe $i is closed in action $action, but open in UPPAAL action."
				
				return false
			end
		elseif pipe_status == 'O'
			if !occursin(pipe_enabled, uppaal_action)
				show_msg && @error "Pipe $i is open in action $action, but closed in UPPAAL action."
				
				return false
			end
		else
			error("Unexpected character $pipe_status in action name")
		end
	end
	return true
end

# ╔═╡ 8f6f9a4a-19d6-4a6f-b7f2-14bf6f47490e
function matches(actions::Dict, uppaal_actions::Dict; show_msg=true)
	for k in keys(actions)
		action = actions[k]
		uppaal_action = uppaal_actions[k]
		if !matches(action, uppaal_action; show_msg)
			show_msg && @error "Mismatch in action number $k, $action and UPPAAL action $uppaal_action."
			return false
		end
	end
	return true
end

# ╔═╡ 0981acdc-1c81-4e64-8542-c0686eb5f618
#=╠═╡
if !(matches(actions, json["actions"]))
	md"""
	!!! danger "Discrepancy Detected"
		See the error outputs.
	"""
else
	md"The action mapping is fine 👍"
end
  ╠═╡ =#

# ╔═╡ 36031e3c-ff0d-4f29-99f3-316b7b2992e5
#=╠═╡
Markdown.parse("""
!!! info "Point variables"
$(join(["    **$k** => $v" for (k,v) in enumerate(json["pointvars"])], "\n\n"))
""")
  ╠═╡ =#

# ╔═╡ 4de463bf-8e89-4aa8-ac89-872bc9399d78
# The newest version of the experiment may have other observations, e.g. just t and stored[i].
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

# ╔═╡ f9f09026-dc0d-41cd-af2c-6ca18d3768d0
#=╠═╡
regressor = json["regressors"]["(1)"]["regressor"]
  ╠═╡ =#

# ╔═╡ 9f83ff3e-33ff-4a2a-b87d-58476b422686
#=╠═╡
regressor["1"]
  ╠═╡ =#

# ╔═╡ b10ccf72-c9f9-4c7a-855f-aed16ca5a794
function indentation(io::IO, indent)
	print(io, "  "^indent)
end

# ╔═╡ b1129b94-6ad6-4d50-9155-10821419fb62
begin
	# An if/else chain making up the core of the decision process.
	# On the same format as the JSON regressor, i.e. it returns an expected
	# value of taking the action corresponding to the given regressor.
	function if_chain(io::IO, regressor::Dict, vars::AbstractArray, indent)
		threshold = regressor["bound"]
		var = vars[regressor["var"] + 1]
		
		indentation(io, indent)
		# 17 digits used: https://stackoverflow.com/a/8990831
		@printf io "if (%s >= %.17f)\n" var threshold
		
		indent += 1
		if_chain(io, regressor["high"], vars, indent)
	
		indent -= 1
		indentation(io, indent)
		@printf io "else\n"
		indent += 1
		
		if_chain(io, regressor["low"], vars, indent)
		
		indent -= 1
	end
	
	function if_chain(io, regressor::Number, _, indent)
		indentation(io, indent)
		@printf io "return %.17f;\n" regressor
	end
	
	function if_chain(regressor::Dict, vars::AbstractArray, indent)
		buf = IOBuffer()
		if_chain(buf, regressor, vars, indent)
		return String(take!(buf))
	end
end

# ╔═╡ c8f10474-12a8-4c71-8325-86fd600b4daf
#=╠═╡
if_chain_1 = if_chain(regressor["1"], vars, 0);
  ╠═╡ =#

# ╔═╡ 490df7d6-a79b-4d3e-8e9b-a302d1e359db
#=╠═╡
if length(if_chain_1) > 1000
	@info if_chain_1[1:1000]*"\n..." 
else @info if_chain_1 end
  ╠═╡ =#

# ╔═╡ 308aa994-8cf5-4393-9631-4f4baac64c6a
begin
	# A C-function for each regressor which returns the expected outcome
	# of its corresponding aciton.
	function all_regressors(regressors::Dict, 
			vars::AbstractArray, 
			actions::Dict, 
			indent)
		
		buf = IOBuffer()
		all_regressors(buf, regressors, vars, actions, indent)
		return String(take!(buf))
	end
	
	function all_regressors(io::IO, 
			regressors::Dict, 
			vars::AbstractArray, 
			actions::Dict, 
			indent)
		
		for (k, v) in regressors
			args = join(["double $var" for var in vars], ", ")
			
			indentation(io, indent)
			@printf io "double expected_%s(%s) {\n" actions[k] args
	
			indent += 1
	
			if_chain(io, v, vars, indent)
			
			indent -= 1
			
			@printf io "}\n\n"
		end
	end
end

# ╔═╡ 67978236-9ffa-49e0-a3b0-d4c3f4985d3a
function action_decider_signature(name, vars::AbstractArray) 
	args = join(["double $var" for var in vars], ", ")
	"int get_action_$name($args, bool allowed_wait, bool allowed_input_one, bool allowed_input_two, bool allowed_input_three)"
end

# ╔═╡ ad9435f6-a6c9-402f-ab7e-ee039fd0174d
allowed = Dict(
	"OOC" => "allowed_input_two",
	"COC" => "allowed_input_one",
	"COO" => "allowed_input_two",
	"CCO" => "allowed_input_one",
	"OCC" => "allowed_input_one",
	"OCO" => "allowed_input_two",
	"OOO" => "allowed_input_three",
	"CCC" => "allowed_wait",
)

# ╔═╡ 407ec72c-3a55-4d42-96e2-19f3b0a853c9
all(v ∈ keys(allowed) for (k, v) in actions)

# ╔═╡ 879a90ad-f58a-4c38-aef6-8b8363016651
begin
	# A C-function which returns the best action according to the regressors.
	# At the moment, *lowest* is considered "best". 
	# `name`: Name of the strategy. Function name will be `get_action_$name()`
	function action_decider(regressors::Dict, 
			vars::AbstractArray, 
			actions::Dict,
			name, 
			indent)
		
		buf = IOBuffer()
		action_decider(buf, regressors, vars, actions, name, indent)
		return String(take!(buf))
	end

	function action_decider(io::IO, 
			regressors::Dict, 
			vars::AbstractArray, 
			actions::Dict,
			name, 
			indent)
		
		
		indentation(io, indent)
		print(io, action_decider_signature(name, vars))
		@printf io " {\n"

		indent += 1
		indentation(io, indent)
		@printf io "double best = INFINITY;\n"
		indentation(io, indent)
		@printf io "int result = 0;\n"
		indentation(io, indent)
		@printf io "double expected;\n"
		
		args = join(["$var" for var in vars], ", ")
		
		for (k, v) in regressors
			action = actions[k]
			@printf io "\n"
			indentation(io, indent)
			@printf io "expected = expected_%s(%s);\n" action args
			
			indentation(io, indent)
			@printf io "if (%s && expected < best) {\n" allowed[action]
			indent += 1
			
			indentation(io, indent)
			@printf io "best = expected;\n"
			indentation(io, indent)
			@printf io "result = %s;\n" action
			
			indent -= 1
			indentation(io, indent)
			@printf io "}\n"
			
		end

		indent -= 1
		indentation(io, indent)
		@printf io "return result;\n"
		indentation(io, indent)
		@printf io "}\n"
	end
end

# ╔═╡ df870b5a-7232-4195-9d9a-4d92cba2cec2
# Various header-stuff.
function header(io::IO, name, actions::Dict)
	# A comment with compile instructions
	println(io, "/* Compile as:\n\tgcc -c -fPIC $name.c -o $name.o\n\tgcc -shared -o lib$name.so $name.o\n*/")

	# Includes
	@printf io "#include <math.h>\n\n"
	@printf io "#include <stdbool.h>\n\n"

	# Constants representing the given actions.
	for (k, v) in actions
		@printf io "const int %s = %s;\n" v k
	end

	@printf io "\n"
end

# ╔═╡ eb410fb5-2677-4168-8c1b-aceddf47e994
begin
	# This is it. 
	function entire_file(regressors::Dict, 
			vars::AbstractArray, 
			actions::Dict, 
			name)
		
		buf = IOBuffer()
		entire_file(buf, regressors, name)
		return String(take!(buf))
	end

	function entire_file(io::IO, 
			regressors::Dict, 
			vars::AbstractArray, 
			actions::Dict, 
			name)
		
		header(io, name, actions)
		all_regressors(io, regressors, vars, actions, 0)
		action_decider(io, regressors, vars, actions, name, 0)
		@printf io "\nint main() {}"
	end
end

# ╔═╡ 4a05ce54-e3fe-4017-b642-699747bb96ac
#=╠═╡
@bind name TextField(60, default="unit1")
  ╠═╡ =#

# ╔═╡ d1663eca-6f1f-4026-a036-da8016815977
#=╠═╡
@info action_decider(json["regressors"]["(1)"]["regressor"], vars, actions, name, 0)
  ╠═╡ =#

# ╔═╡ 5e7f42a5-7292-440c-a8e0-57b84b357955
#=╠═╡
begin
	save_buffer = IOBuffer()
	
	entire_file(save_buffer, 
		json["regressors"]["(1)"]["regressor"], 
		vars,
		actions,
		name)
	
	DownloadButton(take!(save_buffer), "$name.c")
end
  ╠═╡ =#

# ╔═╡ b80ec1d9-6975-4198-b1c7-46acd5c84544
excluding_extension(file::String) = file[1:findlast(==('.'), file) - 1]

# ╔═╡ 3058c083-d9de-4b55-aa91-b5b7ded5abca
excluding_extension("foo.bar.baz")

# ╔═╡ a9e5461c-7495-476b-a9d9-e18c6912e6f5
"""
	strategy_to_C(strategy_path, 
			vars::AbstractArray, 
			actions::Dict, 
			output_dir;
			name=nothing)

Take a JSON format UPPAAL strategy, and create a C shared-object which exports a corresponding decision function. 

**Returns:** `(function_signature, output_path)`
- `function_signature`: Full signature of the function which returns the action according to the strategy.
- `output_path`: Path to the `.so` file that was created.

**Arguments:**
- `strategy_path`: Path to the JSON format strategy.
- `vars`: User-chosen names for the strategy's point variables. Must be valid C variable names.
- `actions`: A Dict{String, String}("0" => "turnLeft" ...) pair of actions and their corresponding desired names.
- `output_dir`: Output. Default: `"lib\$name.so"` and same folder as `strategy_path`.
- `name`: User-chosen name that will be used in a bunch of ways. Default: Input strategy's file name excluding the .json extension.
"""
function strategy_to_c(strategy_path, 
		vars::AbstractArray, 
		actions::Dict, 
		output_dir;
		working_dir=mktempdir(),
		name=nothing)

	name = something(name, strategy_path |> basename |> excluding_extension)
	if isdir(output_dir)
		output_dir = output_dir ⨝ "lib$name.so"
	elseif !isfile(output_dir)
		throw("Invalid output_dir '$output_dir'")
	end

	# Load JSON
	json = nothing
	open(strategy_path, "r") do strategy_file
		json = JSON.parse(strategy_file)
	end
	previous_working_dir = pwd() # pun: pwd() is "print working dir"
	try
		cd(working_dir)
		
		# Create C-file
		open("$name.c", "w") do c_file
			entire_file(c_file, 
				json["regressors"]["(1)"]["regressor"],
				vars, 
				actions,
				name)
			
		end
		
		destination = pwd() ⨝ "lib$name.so"
		
		# Compile C-file and export library
		run(`gcc -c -fPIC $name.c -o $name.o`)
		run(`gcc -shared -o $destination $name.o`)
		if destination != output_dir
			cp(destination, output_dir, force=true)
		end
	catch
		cd(previous_working_dir)
		rethrow()
	end
	cd(previous_working_dir)
	return action_decider_signature(name, vars), output_dir
end;

# ╔═╡ ae547020-fdda-47c4-baf6-40b69001d7a5
#=╠═╡
@bind savepath TextField(80, default=mktempdir())
  ╠═╡ =#

# ╔═╡ 2a410a3a-b427-4da4-9e7e-3f86a0ee7365
working_dir = mktempdir()

# ╔═╡ 96d0609b-87a4-428d-aadf-8c996089e6f0
#=╠═╡
if isfile(strategy_path)
	const signature, savefile = strategy_to_c(strategy_path, vars, actions, savepath; working_dir)
end
  ╠═╡ =#

# ╔═╡ d0e68988-6e25-47bf-8352-7fda76a7f2fe
#=╠═╡
get_action_unit1(t, stored) = 
	@ccall savefile.get_action_car1(t::Float64, stored::Float64, true::Bool, true::Bool, true::Bool, true::Bool)::Int64
  ╠═╡ =#

# ╔═╡ b49c646e-5e1a-40c3-bac5-66599b5225fe
#=╠═╡
get_action_unit1(0, 10)
  ╠═╡ =#

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[compat]
JSON = "~0.21.4"
PlutoUI = "~0.7.52"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.2"
manifest_format = "2.0"
project_hash = "e499a61a289ea191061827d24008593cc8ca02ae"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "91bd53c39b9cbfb5ef4b015e8b582d344532bd0a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.0"

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
git-tree-sha1 = "9673d39decc5feece56ef3940e5dafba15ba0f81"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.1.2"

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
# ╟─7161e853-49b1-468e-a4ba-949c34ef2da2
# ╠═fc499f82-3c3c-11ee-109a-f534985c8341
# ╠═5615668e-7020-43b2-9a97-07dbca4aa115
# ╟─a63ee558-5b46-4827-ae1a-95fa633e30d5
# ╠═c5cde56e-cd4b-4509-a739-d8281a7c5248
# ╠═b727f3d0-11a2-4150-80ad-e6bccd2b7017
# ╠═451b36a9-9712-42ac-b53e-e2031c978ec2
# ╠═46d36365-2146-4094-9bd7-15310269e746
# ╟─c78f40f4-945c-4ee0-ad4e-8b47a734f222
# ╠═f2b82444-77da-4ec5-9991-186f609d9576
# ╟─74ff2ba2-dbf6-45c4-bba9-ea7c38269666
# ╠═8f6f9a4a-19d6-4a6f-b7f2-14bf6f47490e
# ╟─0981acdc-1c81-4e64-8542-c0686eb5f618
# ╟─36031e3c-ff0d-4f29-99f3-316b7b2992e5
# ╠═4de463bf-8e89-4aa8-ac89-872bc9399d78
# ╠═f9f09026-dc0d-41cd-af2c-6ca18d3768d0
# ╠═9f83ff3e-33ff-4a2a-b87d-58476b422686
# ╠═b10ccf72-c9f9-4c7a-855f-aed16ca5a794
# ╠═b1129b94-6ad6-4d50-9155-10821419fb62
# ╠═c8f10474-12a8-4c71-8325-86fd600b4daf
# ╠═490df7d6-a79b-4d3e-8e9b-a302d1e359db
# ╠═308aa994-8cf5-4393-9631-4f4baac64c6a
# ╠═67978236-9ffa-49e0-a3b0-d4c3f4985d3a
# ╠═ad9435f6-a6c9-402f-ab7e-ee039fd0174d
# ╠═407ec72c-3a55-4d42-96e2-19f3b0a853c9
# ╠═879a90ad-f58a-4c38-aef6-8b8363016651
# ╠═d1663eca-6f1f-4026-a036-da8016815977
# ╠═df870b5a-7232-4195-9d9a-4d92cba2cec2
# ╠═eb410fb5-2677-4168-8c1b-aceddf47e994
# ╠═4a05ce54-e3fe-4017-b642-699747bb96ac
# ╠═5e7f42a5-7292-440c-a8e0-57b84b357955
# ╠═b80ec1d9-6975-4198-b1c7-46acd5c84544
# ╠═3058c083-d9de-4b55-aa91-b5b7ded5abca
# ╠═a9e5461c-7495-476b-a9d9-e18c6912e6f5
# ╠═ae547020-fdda-47c4-baf6-40b69001d7a5
# ╠═2a410a3a-b427-4da4-9e7e-3f86a0ee7365
# ╠═96d0609b-87a4-428d-aadf-8c996089e6f0
# ╠═d0e68988-6e25-47bf-8352-7fda76a7f2fe
# ╠═b49c646e-5e1a-40c3-bac5-66599b5225fe
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
