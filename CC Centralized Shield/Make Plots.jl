### A Pluto.jl notebook ###
# v0.19.40

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

# ╔═╡ d6481c1f-3020-4a26-b4aa-83aaa14f33e5
begin
	using Pkg
	Pkg.activate("..", io=devnull)
	using JSON
	using CSV
	using Glob
	using Plots
	Plots.default(fontfamily="serif-roman")
	using PlutoUI
	using DataFrames
	using Statistics
	using StatsPlots
	include("../FlatUI Colors.jl")
end;

# ╔═╡ 17f541f1-fac1-4cf5-a755-7c548fd8ea20
md"""
# Plots for CC Centralized Shield
"""

# ╔═╡ 6a2ada61-1cf9-4e1d-a69f-ec49897fc133
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

# ╔═╡ 717470cb-3660-47b1-99f2-103e876b40a9
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

# ╔═╡ fec3e1ed-fe37-4097-985f-7b718e182231
TableOfContents()

# ╔═╡ 232aaa75-f6b8-4c49-94cb-a76aa7c128d7
md"""
## Loading in Raw Data
"""

# ╔═╡ 68bf3bf7-71fe-433f-9552-f243e6e74c69
@bind results_dir TextField(80, default="$(homedir())/Results/N-player CC Centralized Shield/")

# ╔═╡ 5ee442ef-5c0c-41fa-98f7-d81019fd330a
function firstcapture(re::Regex, str::AbstractString)
	m = match(re, str)
	if isnothing(m)
		error("regex $re not found in string $str")
	end
	m[1]
end

# ╔═╡ 0664e58a-5d05-497c-8203-eceef193e4cb
function extract_results(query_result)
	re_mean = r"mean=(\d+\.?\d*)"
	result = [m[1] for m in eachmatch(re_mean, query_result)]
	result = [parse(Float64, v) for v in result]
end

# ╔═╡ 6565e283-22b5-495f-8635-a49e9af36d37
# Output error if query results seem to indicate a safety violation. 
# This shit is super brittle because it counts hard on there being only ONE Pr[]
# query in the file, and that query being the safety one.
# Assuming safety query on the form 
#    Pr[<=100;100]([] forall (i : int[0, fleetSize - 2]) (distance[i] > minDistance || distance[i] < maxDistance))
function safety_violation_occured(query_result)
	re_safety_evaluation = r"\((\d+)/(\d+) runs\)"
	m = match(re_safety_evaluation, query_result)
	#return m
	if !isnothing(m) && m[1] == m[2]
		return false
	else
		safety_evaluation = isnothing(m) ? "not found!" : m.match
		@error "Didn't find a query showing no safety violations. This could be because of a failed regex, or it could be because of an actual safety violation. Check query file." safety_evaluation
		return true
	end
end

# ╔═╡ 6ea2994d-83af-493c-802a-7ba687395b2e
function get_variant(name)
	name = replace(name, ".txt" => "")
	if name == "3-Car Centralized"
		result = "Cent. Co-ord."
	elseif name == "3-Car"
		result = "Dec."
	elseif name == "3-Car Declared Action"
		result = "Dec. Co-ord."
	else
		error("Unexpected experiment name: $name")
	end

	return "\"$result\""
end

# ╔═╡ 89e83c9a-74cf-11ee-0c31-0f29a93be587
function to_csv(results_dir)
	isdir(results_dir) || error("Not found: $results_dir")
	header = "runs;repetition;variant;car;cost"
	result = String[header]
	for 🗄️ in glob("* Runs", results_dir)
		runs = firstcapture(r"(\d+) Runs", 🗄️)
		for 📁 in glob("Repetition *", 🗄️)
			repetition = firstcapture(r"Repetition (\d+)", 📁)
			for 🗎 in glob("Query Results/*.txt", 📁)
				variant = get_variant(basename(🗎))
				query_results = extract_results(🗎 |> read |> String)
				if length(query_results) != 2
					@warn "Skipping file with unexpected number of query results" file=🗎 expected=2 actual=length(query_results)
						continue
				end
				if safety_violation_occured(🗎 |> read |> String)
					@error "Safety violation detected in file" file=🗎
				end
				car1 = query_results[1]
				car2 = query_results[2]
				push!(result, "$runs;$repetition;$variant;1;$car1")
				push!(result, "$runs;$repetition;$variant;2;$car2")
			end
		end
	end
	join(result, "\n")
end

# ╔═╡ cc09735c-596f-480b-aecf-86e4a811615d
csv_string = to_csv(results_dir)

# ╔═╡ b8188561-e6ff-4d4e-8b79-8897a79f8977
csv_string |> multiline

# ╔═╡ f54beb3d-da04-4c5f-8a66-b4bbe6289c54
raw_data = DataFrame(CSV.File(IOBuffer(csv_string)))

# ╔═╡ f2799a2c-f694-4cd8-9d32-1810ccc3b7d8
const episode_length = 100

# ╔═╡ 849c4994-4ca4-4f14-91af-e5fa0f4993e0
md"""
## Computing Performance
"""

# ╔═╡ cbb415bb-23a5-4252-9cd4-f7d5a6e197cf
md"""
!!! info "Performance?"
	See also the info-box in `CC/Plots from CSV`.
	
	**Performance** is the negative mean of local cost. Local cost is the sum of observed distances over a 100-step run.

	I keep calling it `:reward` in the code, because I don't feel like refactoring.
"""

# ╔═╡ af5b1074-ac2b-43b6-b508-7196f6fe8ddd
function local_reward(cost)
	-cost
end

# ╔═╡ 5ddd2108-56a6-426f-95ca-3208b3779c06
function global_performance(costs)
	rewards = local_reward.(costs)
	mean(rewards)
end

# ╔═╡ ff7d843d-1426-4cf3-8407-531e97e1960d
cleandata = let
	cleandata = raw_data

	grouping = groupby(cleandata, [:runs, :repetition, :variant])

	cleandata = combine(grouping,
		:cost =>(c -> Ref([c...])) => :costs)
	
	cleandata = transform(cleandata, 
		:costs => ByRow(global_performance) => :performance)
end

# ╔═╡ aea564f9-6fc5-4f1d-8699-1ce77be3a38d
means = let	
	grouping =  groupby(cleandata, [:runs, :variant])
	
	means = combine(grouping, 
		:performance => mean,
		renamecols=false)
end

# ╔═╡ 12c1bf45-20fe-4332-8477-4a544b0ada2c
all_runs = cleandata[!, :runs] |> unique |> sort

# ╔═╡ 7ca58b79-9a30-4768-ac04-3562042c4a45
@bind runs_shown MultiSelect(all_runs, default=[r for r in all_runs if r <= 2000])

# ╔═╡ 68f6836e-3ba7-42ca-9650-acba6365aa55
let
	df = means
	df = filter(:runs => r -> r ∈ runs_shown, df)

	cent = filter(:variant => (==)("Cent. Co-ord."), df)
	cent = sort(cent, :runs)
	dec = filter(:variant => (==)("Dec."), df)
	dec = sort(dec, :runs)
	coord = filter(:variant => (==)("Dec. Co-ord."), df)
	coord = sort(coord, :runs)
	
	cent = (;runs=[r for r in cent[!, :runs]], 
		performance=cent[!, :performance])
	
	dec = (;runs=[r for r in dec[!, :runs]], 
		performance=dec[!, :performance])
	
	coord = (;runs=[r for r in coord[!, :runs]], 
		performance=coord[!, :performance])


	all_performances = [cent.performance..., 	
		dec.performance..., coord.performance...]

	ymin, ymax = min(all_performances...), max(all_performances...)

	ylims = (ymin - abs(ymin)*0.1, ymax + abs(ymax*0.1))
	
	stylings = (linewidth=2,
		markerstrokewidth=2,
		markerstrokecolor=:white)
	
	plot(;size=(350, 250),
		ylims,
		legend=:topleft,
		xlabel="Total episodes trained",
		ylabel="Performance")
	
	#plot!(cent.runs, cent.performance;
	#	label="Co-ordinated centralized shield",
	#	color=colors.POMEGRANATE,
	#	marker=(:pentagon, 6),
	#	stylings...)
		
	plot!(coord.runs, coord.performance;
		label="Centralized shield",
		color=colors.CONCRETE,
		marker=(:circle, 6),
		stylings...)
	
	plot!(dec.runs, dec.performance;
		label="Decentralized shield",
		color=colors.SUNFLOWER,
		marker=(:rtriangle, 9),
		stylings...)
end

# ╔═╡ 1bf14dff-08e3-4a32-9e5e-dba6438bc670
standard_deviations = let	
	standard_deviations = combine(cleandata, 
		:performance => std,
		renamecols=false)
end

# ╔═╡ d4e45474-6def-4e02-9fe2-43e6f4fb1bb2
@bind runs Select(unique(means[!, :runs]))

# ╔═╡ 207c5c24-8d48-4beb-b703-83ba13fd3697


# ╔═╡ 1962f0d8-be1f-490f-b377-ff2019625f4d
md"""
`width` = $(@bind width NumberField(0:10:typemax(Int64), default=300))

`height` = $(@bind height NumberField(0:10:typemax(Int64), default=250))
"""

# ╔═╡ 337afbf0-cf51-4068-b3ea-6f759c76a5ce
size = (width, height)

# ╔═╡ 7f059d13-41f5-4d6c-8468-1de130d66901
let
	df = filter(:runs => r -> r == runs, raw_data)
	
	df = transform(df, :car => (
		xs -> ["Car $x" for x in xs]
	) => :car)
	
	@df df groupedbar(:variant, :cost, group=:car,
		bar_width=0.6,
		color=[colors.TURQUOISE colors.CARROT],
		linewidth=4,
		linecolor=:white)
	
	ylim = (min(df[!, :cost]...) - 5, 0)
	
	plot!(;
		size,
		#ylim,
		legend=:outertop,
		ylabel="cost",
	)
end

# ╔═╡ 0960af3f-6b25-4c92-8d95-caf0029da1fc
let
	df = filter(:runs => r -> r == runs, raw_data)
	
	df = transform(df, :car => (
		xs -> ["Car $x" for x in xs]
	) => :car)

	decentralized = "Decentralized"
	centralized = "Centralized"
	cooperative = "Co-operative"
	
	df = transform(df, :variant => ByRow(v -> 
		v == "Cent. Co-ord." ? centralized :
		v == "Dec." ? decentralized :
		v == "Dec. Co-ord." ? cooperative :
		v),
		renamecols=false
	)

	sorting = [decentralized, centralized, cooperative]
	the_sort = x -> findfirst((==)(x), sorting)

	grouped = groupby(df, [:runs, :variant])

	df = combine(grouped, :cost => sum => :cost)

	df = sort(df, :variant, by=the_sort)
	
	@df df bar(:variant, :cost,
		label=nothing,
		#xrot=10,
		bar_width=0.4,
		color=colors.TURQUOISE,
		linewidth=4,
		linecolor=:white)
	
	ylim = (min(df[!, :cost]...) - 5, 0)
	hline!([0], label=nothing, color=:black, width=4)
	
	plot!(;
		size=(300,200),
		ylim,
		legend=:outertop,
		ylabel="cost",
	)
	#=
	=#
end

# ╔═╡ a23eb1ab-a3e2-4a6c-8704-51315f3600ed
let
	A = [:foo, :bar, :baz]
	findfirst(==(:bar), A)
end

# ╔═╡ Cell order:
# ╟─17f541f1-fac1-4cf5-a755-7c548fd8ea20
# ╠═d6481c1f-3020-4a26-b4aa-83aaa14f33e5
# ╟─6a2ada61-1cf9-4e1d-a69f-ec49897fc133
# ╟─717470cb-3660-47b1-99f2-103e876b40a9
# ╠═fec3e1ed-fe37-4097-985f-7b718e182231
# ╟─232aaa75-f6b8-4c49-94cb-a76aa7c128d7
# ╠═68bf3bf7-71fe-433f-9552-f243e6e74c69
# ╠═5ee442ef-5c0c-41fa-98f7-d81019fd330a
# ╠═0664e58a-5d05-497c-8203-eceef193e4cb
# ╠═6565e283-22b5-495f-8635-a49e9af36d37
# ╠═6ea2994d-83af-493c-802a-7ba687395b2e
# ╠═89e83c9a-74cf-11ee-0c31-0f29a93be587
# ╠═cc09735c-596f-480b-aecf-86e4a811615d
# ╠═b8188561-e6ff-4d4e-8b79-8897a79f8977
# ╠═f54beb3d-da04-4c5f-8a66-b4bbe6289c54
# ╠═f2799a2c-f694-4cd8-9d32-1810ccc3b7d8
# ╟─849c4994-4ca4-4f14-91af-e5fa0f4993e0
# ╟─cbb415bb-23a5-4252-9cd4-f7d5a6e197cf
# ╠═5ddd2108-56a6-426f-95ca-3208b3779c06
# ╠═af5b1074-ac2b-43b6-b508-7196f6fe8ddd
# ╠═ff7d843d-1426-4cf3-8407-531e97e1960d
# ╠═aea564f9-6fc5-4f1d-8699-1ce77be3a38d
# ╠═12c1bf45-20fe-4332-8477-4a544b0ada2c
# ╠═7ca58b79-9a30-4768-ac04-3562042c4a45
# ╠═68f6836e-3ba7-42ca-9650-acba6365aa55
# ╠═1bf14dff-08e3-4a32-9e5e-dba6438bc670
# ╠═d4e45474-6def-4e02-9fe2-43e6f4fb1bb2
# ╠═207c5c24-8d48-4beb-b703-83ba13fd3697
# ╠═1962f0d8-be1f-490f-b377-ff2019625f4d
# ╠═337afbf0-cf51-4068-b3ea-6f759c76a5ce
# ╠═7f059d13-41f5-4d6c-8468-1de130d66901
# ╠═0960af3f-6b25-4c92-8d95-caf0029da1fc
# ╠═a23eb1ab-a3e2-4a6c-8704-51315f3600ed
