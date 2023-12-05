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

# ╔═╡ bdb61d68-2ac9-11ed-1b20-9dc154fc45d0
begin
	using Pkg
	Pkg.activate(".")
	using JSON
	using PlutoUI
	using PlutoLinks
	using Random
	using Plots
	using Serialization
	using StatsBase
	using NaturalSort
	using Unzip
	using Measures
	using Distributions
	import Gaston
	include("FlatUI Colors.jl")
	TableOfContents()
end

# ╔═╡ f543bf7e-737e-4e76-8a76-e11d54997c07
begin
	Pkg.develop("GridShielding")
	@revise using GridShielding
end

# ╔═╡ 57fa5a4e-2d90-436c-a1f1-36ffa6ad7b89
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

# ╔═╡ 8894e942-b6f6-4893-bfea-ebaa2f9c58f0
md"""
## Importing the policy:
"""

# ╔═╡ eeebe049-8b0b-4e3e-8cb2-4ee89e241273
md"""
**Exported UPPAAL STRATEGO strategy:** 

`selected_strategy` = $(@bind selected_strategy PlutoUI.FilePicker([MIME("application/json")]))
"""

# ╔═╡ c426cf95-81ed-4c70-96a1-d46e05e29ddb
md"""
**Pick your shield:** 

`selected_shield` = $(@bind selected_shield PlutoUI.FilePicker([MIME("application/octet-stream")]))
"""

# ╔═╡ c870988d-96aa-4114-9901-35472f341d16
if selected_shield == nothing
	md"""
!!! danger "Error"
	# Please select file
"""
end

# ╔═╡ f334b30a-7963-4314-8a26-4f8e0c493ce9
shield = robust_grid_deserialization(selected_shield["data"] |> IOBuffer)

# ╔═╡ 9a3af469-7dc0-4d29-a375-bdc79415e950
jsondict = selected_strategy["data"] |> IOBuffer |> JSON.parse

# ╔═╡ 534968b3-b361-41e0-8e2a-c3ec9e73eef4
function show_strategy_info(s::Dict)
	pointvars = s["pointvars"]
	pointvars = join(pointvars, ", ")
	statevars = s["statevars"]
	statevars = join(statevars, ", ")
	
	locations(dict) = join(["$k: `$v`" 
		for (k, v) in sort(dict, lt=natural)
	], ", ")
	
	locationnames = s["locationnames"]
	
	locationnames = join(["       - `$k`: $(locations(v))"
		for (k, v) in locationnames
	], "\n\n")

	actions = s["actions"]
	actions = sort(actions, lt=natural)
	actions = join(["      - $k: `$v`"
		for (k, v) in actions
	], "\n\n")

	s["type"] != "state->regressor" && @error("Strategy type not supported")
	s["version"] != 1.0 && @error("Strategy version not supported")
	
	Markdown.parse("""
	!!! info "Strategy { $statevars } -> { $pointvars }"

		`statevars`: $(statevars == "" ? "`none`" : statevars)
	
		`pointvars`: $(pointvars == "" ? "`none`" : pointvars)
	
		**Location names:**
	
	$(locationnames)

		**Actions**

	$actions
	""")
end

# ╔═╡ 1c8b2b93-8a23-4717-99a1-6d0cd8fa56b1
show_strategy_info(jsondict)

# ╔═╡ 259a0f84-a0d5-4e59-870f-2030c0b7a8e3
md"""
# Mechanics

Methods to read the policy file follows below
"""

# ╔═╡ d94c6338-fdab-4dce-a2c6-43ab4dc6a837
@enum CCAction backwards neutral forwards

# ╔═╡ 272cd4cb-9d0d-45fe-9b0d-e230eabc8512
begin 
	import Base.+
	
	a::Number + b::CCAction = a+Int(b)
	
	a::CCAction + b::Number = CCAction(Int(a) + b)
end

# ╔═╡ 06147f6a-807c-43e1-a128-a74775699b6f
struct CCMechanics
	t_act::Number # Period between actions
	distance_min::Number
	distance_max::Number
	v_ego_min::Number
	v_ego_max::Number
	v_front_min::Number
	v_front_max::Number
end

# ╔═╡ 64925534-ad26-42af-9656-e2731697d9c8
m = CCMechanics(1, 0, 200, -10, 20, -10, 20)

# ╔═╡ 47a5a6d8-f312-4b39-829a-942a70ebfbc0
function random_front_behaviour(mechanics::CCMechanics, point, random_variable)
    v_ego, v_front, distance = point
	if random_variable[1] < 1/3
		return backwards
	elseif random_variable[1] < 2/3
		return neutral
	else
		return forwards
	end
end

# ╔═╡ 6d51d6a3-04c5-4abb-9dc6-bb526e51d212
[random_front_behaviour(m, (4, 0, 201), rand(Uniform(0, 1))) for _ in 1:100] |> unique |> sort

# ╔═╡ 678bbf8a-ac82-453c-a02b-ff1a4ad5ab7b
function speed_limit(min, max, v, action::CCAction)
	if action == backwards && v <= min
		return neutral
	elseif action == forwards && v >= max
		return neutral
	else
		return action
	end
end

# ╔═╡ 9b77a783-8c05-491e-8c03-1493b795c0db
function apply_action(velocity, action::CCAction)
	if action == backwards
		return velocity - 2
	elseif action == neutral
		return velocity
	else
		return velocity + 2
	end
end

# ╔═╡ 5f115ebe-b9ce-4412-8e31-6d601e791c1f
begin
	function simulate_point(mechanics::CCMechanics, 
			point,
			action::CCAction)

		return simulate_point(mechanics, point, rand(Uniform(0, 1)), action)
	end
	
	function simulate_point(mechanics::CCMechanics, 
	        point, 
	        random_variable, 
	        action::CCAction)
	
	    v_ego, v_front, distance = point
	
	    old_vel = v_front - v_ego;
	
	    front_action = random_front_behaviour(mechanics, point, random_variable)

		front_action′ = speed_limit(mechanics.v_front_min, 
			mechanics.v_front_max, 
			v_front,
			front_action)
		
		v_front = apply_action(v_front, front_action′)
	
	    action′ = speed_limit(mechanics.v_ego_min, 
	        mechanics.v_ego_max, 
	        v_ego,
	        action)
	    
	    v_ego = apply_action(v_ego, action′)
	
	    new_vel = v_front - v_ego;
	
	    distance += (old_vel + new_vel)/2;
	    (v_ego, v_front, distance)
	end
end

# ╔═╡ bf7b4c9d-c4e9-459e-9bd9-7c08f92709cf
function simulate_sequence(mechanics::CCMechanics, duration, s0, policy::Function)
	s0 = Tuple(Float64(x) for x in s0)
    states, times, actions = [s0], [0.0], []
    s, t = s0, 0
    while times[end] <= duration - mechanics.t_act
        action = policy(s)
        s = simulate_point(mechanics, s, action)
		t += mechanics.t_act
        push!(states, s)
        push!(times, t)
        push!(actions, action)
    end
    (;states, times, actions)
end

# ╔═╡ b3e2a24a-fab6-414e-be8b-351a0e7d1b1c
md"""
## Methods to read the policy file
"""

# ╔═╡ 5204d97e-6e04-4525-818b-a7ed642aec0d
# Traverse the "simpletree" which makes a prediction on the continuous statevars for the regressor's action
function traverse_simpletree(regressor, statevars)
	# Base case
	if typeof(regressor) <: Number
		return regressor
	end

	# Recursion
	var_index = regressor["var"] + 1 # Julia indexes start at 1
	var = statevars[var_index]
	bound = regressor["bound"]
	if var >= bound
		traverse_simpletree(regressor["high"], statevars)
	else
		traverse_simpletree(regressor["low"], statevars)
	end
end

# ╔═╡ 7f840af3-bff8-4548-9d31-cf3c64fa9faf
function get_action(regressors, pointvars, statevars)
	pointvars_str = "($(join(pointvars, ",")))"
	regressor = regressors[pointvars_str]
	@assert regressor["minimize"] == 1
	@assert regressor["representation"] == "simpletree"
	regressor = regressor["regressor"]
	
	actions = [k for (k, _) in regressor]

	lowest_outcome = Inf
	cheapest_action = nothing
	for action in actions
		outcome = traverse_simpletree(regressor[action], statevars)
		if outcome < lowest_outcome
			lowest_outcome = outcome
			cheapest_action = action
		end
	end
	parse(Int, cheapest_action)
end

# ╔═╡ 1a27105e-58d5-4dc2-bb7e-f7392a39c900
begin
	function get_policy(file::AbstractString)
		jsondict = file |> read |> JSON.parse
		get_policy(jsondict)
	end
	
	function get_policy(jsondict::Dict{String, Any})
		regressors = jsondict["regressors"]
	
		policy = (statevars, pointvars) -> get_action(regressors, statevars, pointvars)
	end
end

# ╔═╡ 79fb04f7-2d45-454f-89c5-7312d4aeadde
begin
	policy′ = get_policy(jsondict)
	# This strategy has no statevars, so there is only State 1
	policy(s) = policy′(1, s) 
end

# ╔═╡ 29a9d1e2-b0d0-46f2-bbff-ba30f13d3ac0
md"""
### Testing the policy

Get policy from selected file, then apply it to a state.
"""

# ╔═╡ 47a9daed-792b-4b75-8208-3dcf46ede4c5
md"""
## Drawing the policy
Draw a 2D policy
"""

# ╔═╡ 9780bb84-d495-4124-98ca-1318689eec94
function middle(bounds::Bounds{T})::Vector{T} where T
	result = zeros(T, get_dim(bounds))
	for (i, (lower, upper)) in enumerate(zip(bounds.lower, bounds.upper))
		result[i] = lower + (upper - lower)/2
	end
	result
end

# ╔═╡ f969579d-e392-4dce-88ba-6a5da83b599f
GridShielding.draw(policy_2d::Function, bounds::Bounds, G; 
		colors=[:blue, :yellow], 
		color_labels=["action1", "action2"], 
		plotargs...
) = begin
	
	grid = Grid(G, bounds)
	for partition in grid
		bounds = Bounds(partition)
		x, y = middle(bounds)
		a = policy_2d(x, y)
		set_value!(partition, a)
	end
	if length(unique(grid.array)) > length(colors)
		@warn "Not enough colors provided to display all unique values"
	end
	GridShielding.draw(grid; colors, color_labels, plotargs...)
end

# ╔═╡ 8fcb8611-e58c-4830-81e1-9541ddeb2780
bounds = Bounds(Float64[0, -10], Float64[200, 20])

# ╔═╡ c2983ccd-9c9e-4bca-937a-32afd11c35c7
begin
	# Take note of the actions from the strategy description
	# 0 is NegativeAcc, 1 is PositiveAcc, and 2 is Neutral
	action_labels = ["backwards", "neutral", "forwards"]
	action_colors = [colorant"#9C59D1", colorant"#BD83EB", colorant"#ff74af"]
end

# ╔═╡ cd41d294-d1d6-42dd-8246-756c6c40f56c
@bind v_ego NumberField(-10:2:20)

# ╔═╡ 2fd70212-9b73-41a8-a7a6-0cfd02ba8d7e
@bind v_front NumberField(-10:2:20)

# ╔═╡ f8cf701b-61e0-4423-9b37-cd6a6c2dd5b9
@bind distance NumberField(0:1:200, default=50)

# ╔═╡ 596dfcee-99dc-44c6-affe-c5ddef76d90c
md"""
# Shielding the Policy
"""

# ╔═╡ 6df8443f-6aa5-44ce-a865-870a830b6737
begin
	action_color_dict=Dict(
		actions_to_int([]) => colorant"#2C2C2C",
		actions_to_int([backwards]) => colorant"#9C59D1", 
		actions_to_int([backwards neutral]) => colorant"#FCF434",
		actions_to_int([neutral]) => colorant"#BD83EB", 
		actions_to_int([neutral forwards]) => colorant"#D9D469", 
		actions_to_int([forwards]) => colorant"#ff74af", 
		actions_to_int([backwards, forwards]) => colorant"#57ff61",
		actions_to_int([backwards neutral forwards]) => colorant"#FFFFFF", 
	)
	
	shield_colors = [v for (k, v) in sort(action_color_dict)]
	shield_labels = [k for (k, v) in sort(action_color_dict)]
	shield_labels = [int_to_actions(CCAction, l) for l in shield_labels]
	shield_labels = [join(l, ", ") for l in shield_labels]
	shield_labels = ["{$l}" for l in shield_labels]
	(;shield_colors, shield_labels)
end

# ╔═╡ 0856b055-2c75-47d6-8bfb-db2d4a2cf885
# ╠═╡ disabled = true
#=╠═╡
let
	state = [v_ego, 0, 50]
	partition = box(shield, state)
	slice = Vector{Any}(partition.indices)
	slice[2] = Colon()
	slice[3] = Colon()
	draw(shield, slice, 
		colors=shield_colors, 
		color_labels=shield_labels,
		legend=:outerright,
		size=(800, 400))
end
  ╠═╡ =#

# ╔═╡ aee51ef5-e3d3-43e7-ba9a-0c68b0cff9f0
function strategy_action_to_CCAction(a)
	a == 0 ? backwards :
	a == 1 ? forwards :
	a == 2 ? neutral :
	error("Unexpected value for a: $a")
end

# ╔═╡ aa7545c2-c313-4b9f-aebe-5e68cbe2d1fc
# ╠═╡ disabled = true
#=╠═╡
# There is no good place to convert between UPPAAL's action IDs and the internal ones, so I do it here.
function policy_2d(x, y)
	action = policy((v_ego, y, x))
	action = strategy_action_to_CCAction(action)
	action = Int(action)
	return action
end
  ╠═╡ =#

# ╔═╡ e540ed8c-d752-4870-8487-2cd0ea0ea6ba
# ╠═╡ disabled = true
#=╠═╡
draw(policy_2d, bounds, [1, 0.5], 
	colors=action_colors, 
	color_labels=action_labels,
	xlabel="distance",
	ylabel="v_front")
  ╠═╡ =#

# ╔═╡ 9da72ccf-d7d9-44ff-9409-5ea5f3a33b34
function shielded_policy(s)
	action = strategy_action_to_CCAction(policy(s))
	if s ∉ shield
		return action
	end
	partition = box(shield, s)
	allowed = int_to_actions(CCAction, get_value(partition))
	@assert all(typeof(action) == typeof(a) for a in allowed)
	if action ∈ allowed
		return action
	elseif allowed == []
		return -1
	else
		return allowed[1]
	end
end

# ╔═╡ 9f3ad933-5cf0-4d7c-b09a-521480abe589
traces = [
	simulate_sequence(m, 120, [0, 0, 50], shielded_policy)
	for i in 1:50
]

# ╔═╡ 11453734-63ad-4377-ae15-78d85aa21bac
let
	f, b, n = [], [], []

	for trace in traces
		for (i, s) in enumerate(trace.states)
			i == 121 && continue
			v_ego′, v_front, distance = s
			v_ego′ != v_ego && continue
			a = trace.actions[i]
			if a == forwards
				push!(f, (distance, v_front))
			elseif a == backwards
				push!(b, (distance, v_front))
			elseif a == neutral
				push!(n, (distance, v_front))
			end
		end
	end
	
	plot(
		size=(700, 400),
		xlim=(shield.bounds.lower[3], shield.bounds.upper[3]),
		ylim=(shield.bounds.lower[2], shield.bounds.upper[2]),
		xlabel="distance",
		ylabel="v_front",
		legend=:outertop)
	#=
	draw(shielded_policy_2d, bounds, [1, 0.5], 
		colors=[colorant"#2C2C2C", action_colors...], 
		color_labels=["<unsafe>", action_labels...],
		legend=:outertop,
		size=(800, 500),
		ylabel="v_front",
		xlabel="distance",
		margin=3mm)
	=#
	
	length(b) > 0 && scatter!(unzip(b),
		markersize=3,
		label="backwards",
		markershape=:diamond,
		markerstrokewidth=3,
		markerstrokecolor=colors.ALIZARIN,
		markercolor=:white)
	
	length(n) > 0 && scatter!(unzip(n),
		markersize=3,
		label="neutral",
		markershape=:circle,
		markerstrokewidth=3,
		markerstrokecolor=colors.EMERALD,
		markercolor=:white)
	
	length(f) > 0 && scatter!(unzip(f),
		markersize=3,
		label="forwards",
		markershape=:utriangle,
		markerstrokewidth=3,
		markerstrokecolor=colors.WISTERIA,
		markercolor=:white,
	)
	
end

# ╔═╡ ddbd8bcc-a090-459c-a8ea-45847c32169b
let
	f, b, n = [], [], []

	for trace in traces
		for (i, s) in enumerate(trace.states)
			i == 121 && continue
			v_ego, v_front′, distance = s
			v_front′ != v_front && continue
			a = trace.actions[i]
			if a == forwards
				push!(f, (distance, v_ego))
			elseif a == backwards
				push!(b, (distance, v_ego))
			elseif a == neutral
				push!(n, (distance, v_ego))
			end
		end
	end
	
	plot(
		size=(700, 400),
		xlim=(shield.bounds.lower[3], shield.bounds.upper[3]),
		ylim=(shield.bounds.lower[2], shield.bounds.upper[2]),
		xlabel="distance",
		ylabel="v_ego",
		legend=:outertop)
	
	length(b) > 0 && scatter!(unzip(b),
		markersize=3,
		label="backwards",
		markershape=:diamond,
		markerstrokewidth=3,
		markerstrokecolor=colors.ALIZARIN,
		markercolor=:white)
	
	length(n) > 0 && scatter!(unzip(n),
		markersize=3,
		label="neutral",
		markershape=:circle,
		markerstrokewidth=3,
		markerstrokecolor=colors.EMERALD,
		markercolor=:white)
	
	length(f) > 0 && scatter!(unzip(f),
		markersize=3,
		label="forwards",
		markershape=:utriangle,
		markerstrokewidth=3,
		markerstrokecolor=colors.WISTERIA,
		markercolor=:white,
	)
	
end

# ╔═╡ 19db2642-fb75-4d9c-8c33-dfa75ca29b3a
let
	f, b, n = [], [], []

	for trace in traces
		for (i, s) in enumerate(trace.states)
			i == 121 && continue
			v_ego, v_front, distance′ = s
			distance′ != distance && continue
			a = trace.actions[i]
			if a == forwards
				push!(f, (v_front, v_ego))
			elseif a == backwards
				push!(b, (v_front, v_ego))
			elseif a == neutral
				push!(n, (v_front, v_ego))
			end
		end
	end
	
	plot(
		aspectratio=:equal,
		size=(700, 400),
		xlim=(shield.bounds.lower[1], shield.bounds.upper[1]),
		ylim=(shield.bounds.lower[2], shield.bounds.upper[2]),
		xlabel="v_front",
		ylabel="v_ego",
		legend=:outertop)
	
	length(b) > 0 && scatter!(unzip(b),
		markersize=3,
		label="backwards",
		markershape=:diamond,
		markerstrokewidth=3,
		markerstrokecolor=colors.ALIZARIN,
		markercolor=:white)
	
	length(n) > 0 && scatter!(unzip(n),
		markersize=3,
		label="neutral",
		markershape=:circle,
		markerstrokewidth=3,
		markerstrokecolor=colors.EMERALD,
		markercolor=:white)
	
	length(f) > 0 && scatter!(unzip(f),
		markersize=3,
		label="forwards",
		markershape=:utriangle,
		markerstrokewidth=3,
		markerstrokecolor=colors.WISTERIA,
		markercolor=:white,
	)
	plot!()
end

# ╔═╡ 262a613f-9e5e-4d3f-b31a-b26ebcf31680
shielded_policy([0, 0, 20])

# ╔═╡ 545132b9-ba7c-40dc-ae44-8551113c18dd
shielded_policy_2d(x, y) = Int(shielded_policy((v_ego, y, x)))

# ╔═╡ d689f140-a352-4a98-b489-48e81896f915
# ╠═╡ disabled = true
#=╠═╡
draw(shielded_policy_2d, bounds, [1, 0.5], 
	colors=[colorant"#2C2C2C", action_colors...], 
	color_labels=["<unsafe>", action_labels...],
	legend=:outerright,
	size=(800, 400),
	ylabel="v_front",
	xlabel="distance",
	margin=3mm)
  ╠═╡ =#

# ╔═╡ 21bde71c-da6d-4eb9-acfe-8f3ffb2398ad
md"""
# Animated Policy
"""

# ╔═╡ 58f0cfbd-54c5-41d6-8504-83beb01bc620
trace = simulate_sequence(m, 100, (0, 0, 20), shielded_policy)

# ╔═╡ 4cb2809b-e0e1-4f14-833c-0163f872c05b
car = """
  _____
__/ |_|_|  `
/_( )___( )_|
"""

# ╔═╡ 9cec2767-8b7a-4b58-be30-80d240b22067
function plot_cars(distance, time)
	car_width = 20
	p = distance + car_width

	plot(
		xlims=(-9, 200),
		ylims=(0, 2),
		yticks=[0],
		legend=:outertop,
		size=(600, 200),
		label="cars",
		xlabel="distance to front",
		margin=3mm)
	
	annotate!([(0, 1, car, 8)])
	annotate!([(p, 1, car, 8)])

	#scatter!([0], label="time: $time", alpha=0, marker=0)
end

# ╔═╡ b451a816-417b-490e-8e2c-08a2ef2592fb
tree = "γ"

# ╔═╡ 734d3f2b-1b60-4b27-8753-8b68eba5b8db
function plot_landscape(distance_covered)
	draw_limit = 200
	x = 2*draw_limit
	annotate!([((distance_covered + x*0.03)%x, 0.3, tree)])
	annotate!([((distance_covered + x*0.14)%x, 0.7, tree)])
	annotate!([((distance_covered + x*0.23)%x, 0.6, tree)])
	annotate!([((distance_covered + x*0.43)%x, 1.5, tree)])
	annotate!([((distance_covered + x*0.50)%x, 1.4, tree)])
	annotate!([((distance_covered + x*0.64)%x, 1.6, tree)])
	annotate!([((distance_covered + x*0.69)%x, 1.8, tree)])
	annotate!([((distance_covered + x*0.83)%x, 0.3, tree)])
end

# ╔═╡ 2f60f8c7-758d-4e29-8c6e-838dbde3696b
let
	plot_cars(5, 10)
	plot_landscape(0)
end

# ╔═╡ fc6281ab-aeba-48b5-a0b0-f6decc94b9e6
function draw_policy_with_state(policy, bounds, state, G)
	v_ego, v_front, distance = state
	policy_2d(x, y) = Int(policy((v_ego, y, x)))
	draw(policy_2d, bounds, G; 
		colors=[colorant"#2C2C2C", action_colors...], 
		color_labels=["<unsafe>", action_labels...],
		ylabel="v_front",
		xlabel="distance",
		legend=:outerright,
		margin=3mm)
	
	scatter!([distance], [v_front],
		marker=:x, 
		markersize=8,
		markerstrokewidth=6,
		markercolor=colors.SUNFLOWER,
		label="state")

	scatter!([], [], markeralpha=0, label="\nv_ego=$v_ego")
end

# ╔═╡ 9ff16d40-a249-4195-9bb8-2fa50955495e
let
	p1 = draw_policy_with_state(shielded_policy, bounds, [0, 30, 10], [1, 0.5])
	p2 = plot_cars(5, 10)
	plot_landscape(0)
	plot(p1, p2, layout=(2, 1), size=(800, 600))
end

# ╔═╡ 82c9e826-18d6-462f-9709-26bf76c75957
function animate_trace(trace)
	states, times = trace
	Δt = times[2] - times[1] # Assuming uniform timestep
	distance_covered = 0
	anim = @animate for ((v_ego, v_front, distance), time) in zip(states, times)
		plot_cars(distance, time)
		distance_covered += v_front*Δt
		plot_landscape(distance_covered)
	end
	# Add a delay before reset
	[frame(anim) for _ in 1:10]
	anim
end

# ╔═╡ d1635e23-29d3-4029-96d1-b7e4c1d0bd44
sum(s[3] for s in trace.states)

# ╔═╡ c77b8270-6680-41cc-81ee-5e087bfb9ecb
# Fuck it, this funciton doesn't generalize
function animate_trace_with_shielded_policy(trace)
	states, times = trace
	Δt = times[2] - times[1] # Assuming uniform timestep
	distance_covered = 0
	G = [1, 0.5]
	anim = @animate for ((v_ego, v_front, distance), time) in zip(states, times)
		p1 = draw_policy_with_state(shielded_policy, bounds, (v_ego, v_front, distance), G)
		p2 = plot_cars(distance, time)
		distance_covered += v_front*Δt
		plot_landscape(distance_covered)

		plot(p1, p2, layout=(2, 1), size=(800, 700))
	end
	# Add a delay before reset
	[frame(anim) for _ in 1:10]
	anim
end

# ╔═╡ d16f9007-153a-4dac-8ee0-223a7c6ce8e6
gif(animate_trace_with_shielded_policy(trace), fps=4, show_msg=false)

# ╔═╡ Cell order:
# ╠═bdb61d68-2ac9-11ed-1b20-9dc154fc45d0
# ╠═f543bf7e-737e-4e76-8a76-e11d54997c07
# ╟─57fa5a4e-2d90-436c-a1f1-36ffa6ad7b89
# ╟─8894e942-b6f6-4893-bfea-ebaa2f9c58f0
# ╟─c870988d-96aa-4114-9901-35472f341d16
# ╟─eeebe049-8b0b-4e3e-8cb2-4ee89e241273
# ╟─c426cf95-81ed-4c70-96a1-d46e05e29ddb
# ╠═f334b30a-7963-4314-8a26-4f8e0c493ce9
# ╠═9a3af469-7dc0-4d29-a375-bdc79415e950
# ╟─534968b3-b361-41e0-8e2a-c3ec9e73eef4
# ╟─1c8b2b93-8a23-4717-99a1-6d0cd8fa56b1
# ╟─259a0f84-a0d5-4e59-870f-2030c0b7a8e3
# ╠═d94c6338-fdab-4dce-a2c6-43ab4dc6a837
# ╠═272cd4cb-9d0d-45fe-9b0d-e230eabc8512
# ╠═06147f6a-807c-43e1-a128-a74775699b6f
# ╠═64925534-ad26-42af-9656-e2731697d9c8
# ╠═47a5a6d8-f312-4b39-829a-942a70ebfbc0
# ╠═6d51d6a3-04c5-4abb-9dc6-bb526e51d212
# ╠═678bbf8a-ac82-453c-a02b-ff1a4ad5ab7b
# ╠═9b77a783-8c05-491e-8c03-1493b795c0db
# ╠═5f115ebe-b9ce-4412-8e31-6d601e791c1f
# ╠═bf7b4c9d-c4e9-459e-9bd9-7c08f92709cf
# ╟─b3e2a24a-fab6-414e-be8b-351a0e7d1b1c
# ╠═1a27105e-58d5-4dc2-bb7e-f7392a39c900
# ╠═7f840af3-bff8-4548-9d31-cf3c64fa9faf
# ╠═5204d97e-6e04-4525-818b-a7ed642aec0d
# ╠═79fb04f7-2d45-454f-89c5-7312d4aeadde
# ╟─29a9d1e2-b0d0-46f2-bbff-ba30f13d3ac0
# ╟─47a9daed-792b-4b75-8208-3dcf46ede4c5
# ╟─9780bb84-d495-4124-98ca-1318689eec94
# ╠═f969579d-e392-4dce-88ba-6a5da83b599f
# ╠═aa7545c2-c313-4b9f-aebe-5e68cbe2d1fc
# ╠═8fcb8611-e58c-4830-81e1-9541ddeb2780
# ╠═c2983ccd-9c9e-4bca-937a-32afd11c35c7
# ╠═e540ed8c-d752-4870-8487-2cd0ea0ea6ba
# ╠═9f3ad933-5cf0-4d7c-b09a-521480abe589
# ╠═cd41d294-d1d6-42dd-8246-756c6c40f56c
# ╟─11453734-63ad-4377-ae15-78d85aa21bac
# ╠═2fd70212-9b73-41a8-a7a6-0cfd02ba8d7e
# ╟─ddbd8bcc-a090-459c-a8ea-45847c32169b
# ╠═f8cf701b-61e0-4423-9b37-cd6a6c2dd5b9
# ╟─19db2642-fb75-4d9c-8c33-dfa75ca29b3a
# ╟─596dfcee-99dc-44c6-affe-c5ddef76d90c
# ╠═0856b055-2c75-47d6-8bfb-db2d4a2cf885
# ╟─6df8443f-6aa5-44ce-a865-870a830b6737
# ╠═aee51ef5-e3d3-43e7-ba9a-0c68b0cff9f0
# ╠═9da72ccf-d7d9-44ff-9409-5ea5f3a33b34
# ╠═262a613f-9e5e-4d3f-b31a-b26ebcf31680
# ╠═545132b9-ba7c-40dc-ae44-8551113c18dd
# ╠═d689f140-a352-4a98-b489-48e81896f915
# ╟─21bde71c-da6d-4eb9-acfe-8f3ffb2398ad
# ╠═58f0cfbd-54c5-41d6-8504-83beb01bc620
# ╠═9cec2767-8b7a-4b58-be30-80d240b22067
# ╠═734d3f2b-1b60-4b27-8753-8b68eba5b8db
# ╟─4cb2809b-e0e1-4f14-833c-0163f872c05b
# ╠═b451a816-417b-490e-8e2c-08a2ef2592fb
# ╠═2f60f8c7-758d-4e29-8c6e-838dbde3696b
# ╠═fc6281ab-aeba-48b5-a0b0-f6decc94b9e6
# ╠═9ff16d40-a249-4195-9bb8-2fa50955495e
# ╠═82c9e826-18d6-462f-9709-26bf76c75957
# ╠═d1635e23-29d3-4029-96d1-b7e4c1d0bd44
# ╠═d16f9007-153a-4dac-8ee0-223a7c6ce8e6
# ╠═c77b8270-6680-41cc-81ee-5e087bfb9ecb
