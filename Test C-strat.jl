### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 27a09f6e-4644-11ee-0715-5b50bd2615fc
begin
	using PlutoUI
	using PlutoTest
	using JSON
	using Distributions
	TableOfContents()
end

# ╔═╡ c38dfd32-4062-4590-9f2f-1b0f0141c790
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

# ╔═╡ 43612312-e274-47ab-b97e-00b8d4348216
⨝ = joinpath

# ╔═╡ 7d9da7e1-3638-4ab7-8a49-791f469f4d6a
md"""
# Choose your own values

`v =` $(@bind v NumberField(-10:2:20))
`vf =` $(@bind vf NumberField(-10:2:20))
`d =` $(@bind d NumberField(0:1:200))
"""

# ╔═╡ ecf48bb1-fe70-4fa9-bf3b-76b4a6c5ecb4
md"""
# The C library
"""

# ╔═╡ 2f2dfdb2-09c5-4be9-9f8a-a3aa771f2686
md"""

	const int PositiveAcceleration = 1;
	const int NegativeAcceleration = 0;
	const int NoAcceleration = 2;
"""

# ╔═╡ a299f1b8-957d-4a33-a81c-a24423e58d4a
@bind libcar1_path TextField(80, default=homedir() ⨝ "Results/N-player CC/20000 Runs/Repetition 1/Models/libcar1.so")

# ╔═╡ 8ecaecf7-aff7-46fd-b47a-c4ea9a42e0c8
const libcar1 = libcar1_path

# ╔═╡ 0c061dba-3a78-44de-bb5b-c897c2d43b1e
ispath(libcar1_path)

# ╔═╡ fcc61401-22ef-4335-afd0-299bd3781c0f
get_action_car1(velocity, velocity_front, distance) = 
	@ccall libcar1.get_action_car1(velocity::Float64, velocity_front::Float64, distance::Float64)::Int64

# ╔═╡ ebe6991f-486f-4f36-b8fb-00e057f3741e
get_action_car1(v, vf, d)

# ╔═╡ 1c14fb15-909b-4a24-8891-b26adfb29c0a
get_action_car1(2, 2, 80)

# ╔═╡ ea7a4d6d-8317-49c6-83b9-6911e3de7e95
@bind json_path TextField(80, default=homedir() ⨝ "Results/N-player CC/20000 Runs/Repetition 1/Models/car1.json")

# ╔═╡ 39f1caba-a482-4ab3-8ba6-57650b8ee1e7
md"""
# The original exported strategy
"""

# ╔═╡ bf7f10cb-f20d-42e0-b252-8a6c453ed30a
json = JSON.parse(String(read(json_path)))

# ╔═╡ 2963f6e1-3279-4f27-a422-d4e407c83b9e
json["actions"]

# ╔═╡ 23227e71-0773-4099-bc62-5a1a609cd28e
json["pointvars"]

# ╔═╡ bb21f176-6cd4-4358-9159-63017b5833d2
json["regressors"]["(1)"]

# ╔═╡ 4df2b00e-033b-4b1e-8036-95acd2bb2fbe
varnames = json["pointvars"]

# ╔═╡ e108decd-1a7f-4a53-a4e9-304d487a5ae5
begin
	function expected_outcome(json::Dict, vars; verbose=false)
		varname = varnames[json["var"] + 1]
		var = vars[json["var"] + 1]
		bound = json["bound"]
		verbose && print("$varname -- $var <= $bound")
		if vars[json["var"] + 1] <= json["bound"]
			verbose && println("\ttrue")
			return expected_outcome(json["low"], vars; verbose)
		else
			verbose && println("\tfalse")
			return expected_outcome(json["high"], vars; verbose)
		end
	end
	
	function expected_outcome(result::Number, x; verbose=false)
		return result
	end
end

# ╔═╡ debd8b36-a6b5-4c34-8fd3-9ca1a5f27235
function get_action(json::Dict, vars; verbose=false)
	if haskey(json, "regressors")
		return get_action(json["regressors"]["(1)"]["regressor"], vars; verbose)
	end
	verbose && println("👉")
	expected0 = (expected_outcome(json["0"], vars; verbose), 0)
	verbose && println("👉")
	expected1 = (expected_outcome(json["1"], vars; verbose), 1)
	verbose && println("👉")
	expected2 = (expected_outcome(json["2"], vars; verbose), 2)

	# Yes.
	return sort([expected0, expected1, expected2], by=x -> x[1])[1][2]
end

# ╔═╡ 5e7a5511-ca87-4dbd-9616-352287315b31
get_action(json, (2, 2, 80))

# ╔═╡ 36079a76-a707-4d0a-a591-15728cda8265
get_action_car1′(velocity, velocity_front, distance; verbose=false) = get_action(json, (velocity, velocity_front, distance); verbose)

# ╔═╡ 4f4179df-b279-40eb-829a-3b3cb783bd91
get_action_car1′(v, vf, d)

# ╔═╡ 252f677e-1958-4b28-8d4b-82abc51398ca
get_action_car1′(0, 0, 50, verbose=true)

# ╔═╡ e61032af-5c5d-4de6-b323-8dbafe29fe6f
md"""
# The actual tests
"""

# ╔═╡ 30b2e1c1-802c-4e50-bd64-bc78bc0b55f9
@test get_action_car1(0, 0, 50) == get_action_car1′(0, 0, 50)

# ╔═╡ a0463729-b67f-48c5-9b01-42a263a48765
@test get_action_car1(-1.9, -1.0, 66) == get_action_car1′(-1.9, -1.0, 66)

# ╔═╡ 22eed987-f6e3-414a-8475-a3ddabd3be03
@test get_action_car1(-1.3, 5.8, 166) == get_action_car1′(-1.3, 5.8, 166)

# ╔═╡ b2602340-bb9e-4050-8515-24ea7c646918
@test get_action_car1(16, 20, 180) == get_action_car1′(16, 20, 180)

# ╔═╡ bce58aca-2da5-4931-81cd-930f4af54170
@test get_action_car1(2, 2, 80) == get_action_car1′(2, 2, 80)

# ╔═╡ ea912adf-cb5e-429b-9712-bf23c4dd2096
@test get_action_car1(2, 2, 2) == get_action_car1′(2, 2, 2)

# ╔═╡ e2df12a3-9ca0-4300-83cf-038502dc1788
test_values = [
	(rand(-10:0.1:20), rand(-10:0.1:20), rand(0:200))
	for _ in 1:10
]

# ╔═╡ 53ffd79a-7a89-4d0a-a0a5-5140addf22c9
# Expand list to view results
testresults = [
	@test get_action_car1(v...) == get_action_car1′(v...)
	for v in test_values
]

# ╔═╡ 6dce90ea-7c75-4f3e-9e05-51c7a36a6e28
# fails
[t for t in testresults if t isa PlutoTest.Fail]

# ╔═╡ 5e5d30e8-988b-4383-981f-314b0cd13010
v_min = -10; v_max = 20; distance_min = 0; distance_max = 200;

# ╔═╡ 82f6c9a1-17ae-42b3-975d-575c3a1786c1
get_action_car1(rand(Uniform(v_min, v_max)), 
	rand(Uniform(v_min, v_max)), 
	rand(Uniform(distance_min, distance_max)))

# ╔═╡ 6cb1573c-8078-4be4-98ab-6c6fb1556b5f
@time for _ in 1:10000
	get_action_car1(rand(Uniform(v_min, v_max)), 
		rand(Uniform(v_min, v_max)), 
		rand(Uniform(distance_min, distance_max)))
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
PlutoTest = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Distributions = "~0.25.104"
JSON = "~0.21.4"
PlutoTest = "~0.2.2"
PlutoUI = "~0.7.52"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.2"
manifest_format = "2.0"
project_hash = "4bf4b5516d73c86ba5f739a4b0c5ee16de6d13da"

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

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "886826d76ea9e72b35fcd000e535588f7b60f21d"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.10.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3dbd312d370723b6bb43ba9d02fc36abade4518d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.15"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Distributions]]
deps = ["FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "9242eec9b7e2e14f9952e8ea1c7e31a50501d587"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.104"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random"]
git-tree-sha1 = "5b93957f6dcd33fc343044af3d48c215be2562f1"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.9.3"
weakdeps = ["PDMats", "SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "f218fe3736ddf977e0e772bc9a586b2383da2685"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.23"

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

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

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

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "7d6dd4e9212aebaeed356de34ccf262a3cd415aa"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.26"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

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

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "949347156c25054de2db3b166c52ac4728cbad65"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.31"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "716e24b21538abc91f6205fd1d8363f39b442851"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.7.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.PlutoTest]]
deps = ["HypertextLiteral", "InteractiveUtils", "Markdown", "Test"]
git-tree-sha1 = "17aa9b81106e661cffa1c4c36c17ee1c50a86eda"
uuid = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
version = "0.2.2"

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

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "9ebcd48c498668c7fa0e97a9cae873fbee7bfee1"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.9.1"

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

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "f65dcb5fa46aee0cf9ed6274ccbd597adc49aa7b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.1"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6ed52fdd3382cf21947b15e8870ac0ddbff736da"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.4.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "5165dfb9fd131cf0c6957a3a7605dede376e7b63"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e2cfc4012a19088254b3950b85c3c1d8882d864d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.3.1"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "1d77abd07f617c4868c33d4f5b9e1dbb2643c9cf"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.2"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "f625d686d5a88bcd2b15cd81f18f98186fdc0c9a"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.3.0"

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

    [deps.StatsFuns.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

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
# ╠═27a09f6e-4644-11ee-0715-5b50bd2615fc
# ╟─c38dfd32-4062-4590-9f2f-1b0f0141c790
# ╠═43612312-e274-47ab-b97e-00b8d4348216
# ╟─7d9da7e1-3638-4ab7-8a49-791f469f4d6a
# ╠═ebe6991f-486f-4f36-b8fb-00e057f3741e
# ╠═4f4179df-b279-40eb-829a-3b3cb783bd91
# ╟─ecf48bb1-fe70-4fa9-bf3b-76b4a6c5ecb4
# ╟─2f2dfdb2-09c5-4be9-9f8a-a3aa771f2686
# ╠═8ecaecf7-aff7-46fd-b47a-c4ea9a42e0c8
# ╠═a299f1b8-957d-4a33-a81c-a24423e58d4a
# ╠═0c061dba-3a78-44de-bb5b-c897c2d43b1e
# ╠═fcc61401-22ef-4335-afd0-299bd3781c0f
# ╠═1c14fb15-909b-4a24-8891-b26adfb29c0a
# ╠═ea7a4d6d-8317-49c6-83b9-6911e3de7e95
# ╟─39f1caba-a482-4ab3-8ba6-57650b8ee1e7
# ╠═2963f6e1-3279-4f27-a422-d4e407c83b9e
# ╠═23227e71-0773-4099-bc62-5a1a609cd28e
# ╠═bb21f176-6cd4-4358-9159-63017b5833d2
# ╠═bf7f10cb-f20d-42e0-b252-8a6c453ed30a
# ╠═debd8b36-a6b5-4c34-8fd3-9ca1a5f27235
# ╠═4df2b00e-033b-4b1e-8036-95acd2bb2fbe
# ╠═e108decd-1a7f-4a53-a4e9-304d487a5ae5
# ╠═5e7a5511-ca87-4dbd-9616-352287315b31
# ╠═36079a76-a707-4d0a-a591-15728cda8265
# ╠═252f677e-1958-4b28-8d4b-82abc51398ca
# ╟─e61032af-5c5d-4de6-b323-8dbafe29fe6f
# ╠═30b2e1c1-802c-4e50-bd64-bc78bc0b55f9
# ╠═a0463729-b67f-48c5-9b01-42a263a48765
# ╠═22eed987-f6e3-414a-8475-a3ddabd3be03
# ╠═b2602340-bb9e-4050-8515-24ea7c646918
# ╠═bce58aca-2da5-4931-81cd-930f4af54170
# ╠═ea912adf-cb5e-429b-9712-bf23c4dd2096
# ╠═e2df12a3-9ca0-4300-83cf-038502dc1788
# ╠═53ffd79a-7a89-4d0a-a0a5-5140addf22c9
# ╠═6dce90ea-7c75-4f3e-9e05-51c7a36a6e28
# ╠═5e5d30e8-988b-4383-981f-314b0cd13010
# ╠═82f6c9a1-17ae-42b3-975d-575c3a1786c1
# ╠═6cb1573c-8078-4be4-98ab-6c6fb1556b5f
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
