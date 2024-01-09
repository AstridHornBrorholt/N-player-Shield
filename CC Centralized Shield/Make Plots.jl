### A Pluto.jl notebook ###
# v0.19.36

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
	Pkg.activate("..")
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
function safety_violation_occured(query_result)
	re_safe = r"\(0/\d+ runs\)"
	if occursin(re_safe, query_result)
		return false
	else
		re_check = r"\(\d+/\d+ runs\)"
		matches = match(re_check, query_result)
		@warn "Didn't find a query showing no safety violations. This could be because of a failed regex, or it could be because of an actual safety violation. Check query file." matches
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
	header = "runs;repetition;variant;car;reward"
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

# ╔═╡ ff7d843d-1426-4cf3-8407-531e97e1960d
cleandata = let
	cleandata = raw_data
	
	cleandata = transform(cleandata, :reward => (
		xs -> [-x/100 for x in xs]
	) => :reward)
end

# ╔═╡ aea564f9-6fc5-4f1d-8699-1ce77be3a38d
means = let	
	grouping =  groupby(cleandata, [:runs, :variant, :car])
	
	means = combine(grouping, 
		:reward => mean,
		renamecols=false)
end

# ╔═╡ 1bf14dff-08e3-4a32-9e5e-dba6438bc670
standard_deviations = let	
	grouping =  groupby(cleandata, [:runs, :variant, :car])
	
	standard_deviations = combine(grouping, 
		:reward => std,
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
	df = filter(:runs => r -> r == runs, means)
	
	df = transform(df, :car => (
		xs -> ["Car $x" for x in xs]
	) => :car)
	
	@df df groupedbar(:variant, :reward, group=:car,
		bar_width=0.6,
		color=[colors.TURQUOISE colors.CARROT],
		linewidth=4,
		linecolor=:white)
	
	ylim = (min(df[!, :reward]...) - 5, 0)
	
	plot!(;
		size,
		ylim,
		legend=:outertop,
		ylabel="reward",
	)
end

# ╔═╡ Cell order:
# ╠═d6481c1f-3020-4a26-b4aa-83aaa14f33e5
# ╟─6a2ada61-1cf9-4e1d-a69f-ec49897fc133
# ╟─717470cb-3660-47b1-99f2-103e876b40a9
# ╠═68bf3bf7-71fe-433f-9552-f243e6e74c69
# ╠═5ee442ef-5c0c-41fa-98f7-d81019fd330a
# ╠═0664e58a-5d05-497c-8203-eceef193e4cb
# ╠═6565e283-22b5-495f-8635-a49e9af36d37
# ╠═6ea2994d-83af-493c-802a-7ba687395b2e
# ╠═89e83c9a-74cf-11ee-0c31-0f29a93be587
# ╠═cc09735c-596f-480b-aecf-86e4a811615d
# ╠═b8188561-e6ff-4d4e-8b79-8897a79f8977
# ╠═f54beb3d-da04-4c5f-8a66-b4bbe6289c54
# ╠═ff7d843d-1426-4cf3-8407-531e97e1960d
# ╠═aea564f9-6fc5-4f1d-8699-1ce77be3a38d
# ╠═1bf14dff-08e3-4a32-9e5e-dba6438bc670
# ╠═d4e45474-6def-4e02-9fe2-43e6f4fb1bb2
# ╠═207c5c24-8d48-4beb-b703-83ba13fd3697
# ╠═1962f0d8-be1f-490f-b377-ff2019625f4d
# ╠═337afbf0-cf51-4068-b3ea-6f759c76a5ce
# ╠═7f059d13-41f5-4d6c-8468-1de130d66901
