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

# ╔═╡ c1bdc9f0-3d96-11ee-00af-b341a715281c
begin
	using Pkg
	Pkg.activate("..")
	using Plots
	import Gaston
	using PlutoUI
	using PlutoLinks
	using StatsBase
	using Unzip
	using Distributions
	using Combinatorics
	using Serialization
	include("../FlatUI Colors.jl")
end

# ╔═╡ d2204fe6-a71e-4131-a568-349572ce28d4
begin
	Pkg.develop("GridShielding")
	@revise using GridShielding # Be careful with @revise and long computations.
	#using GridShielding
end

# ╔═╡ 1e159603-fc61-45f8-9595-f75e55318344
md"""
# Analyze Safety Violation

Analysis of safety violations that (at some point did) occur when the shield is applied to different cc-mechanics using a projection $\pi$. 

This is Frankenstein'd from like 3 different notebooks so good luck.
"""

# ╔═╡ f29d0dc0-f557-4522-82c3-7daa42d416e1
md"""
# Preamble

This is the stuff that was copy-pasted as mentioned above.
"""

# ╔═╡ 6a33c245-d3ba-42ff-bac1-174e7082dd92
TableOfContents()

# ╔═╡ 59eac6a7-c4c3-4579-bc23-42549f95ae83
⨝ = joinpath

# ╔═╡ 77d2442c-8081-4cc0-90f5-65684b51b801
← = push!

# ╔═╡ dc3c1888-5846-498a-ad37-92c6d5493c1b
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

# ╔═╡ 5f3af2ba-af4e-4591-bc56-dbebfcb06de5
md"""
## Mechanics

The mechanics which describe the cruise control system
"""

# ╔═╡ f7233b81-e182-4b23-aa31-409ee53daf77
@enum CCAction backwards neutral forwards

# ╔═╡ 7dd403fc-878d-45d3-9976-655f10dfd8bc
struct CCMechanics
	t_act::Number # Period between actions
	distance_min::Number
	distance_max::Number
	acceleration::Number
	v_ego_min::Number
	v_ego_max::Number
	v_front_min::Number
	v_front_max::Number
end

# ╔═╡ 0fedc544-3a81-45b3-b8b0-94c86d291f1b
# Default Mechanics
m = CCMechanics(1, 0, 200, 2, -10, 20, -10, 20)

# ╔═╡ fef4c875-cab9-4300-ae02-ea0773363eb0
md"""
The **`fleet_size`** is the total number of cars, including the front car, which is not controlled.

This means that there are **`fleet_size`** different velocity values, and **`fleet_size - 1`** distances to keep track of. 

If there are $n$=**`fleet_size`** cars, the state vector is $[v_1, v_2, \dots v_n, d_1, d_2, \dots d_{n - 1}]^T$

Where $v_i$ is the velocity of car $i$. Car $1$ is the first car in the fleet. And $d_i$ is the distance from car $i$ to car $i + 1$.

Mind that arrays in Julia start at 1 while they start at 0 in UPPAAL.
"""

# ╔═╡ 3ba9e8c6-8188-4b09-9ae5-8ec73a655b14
get_fleet_size(point) = Int64((length(point) + 1) / 2)

# ╔═╡ 05ecffb2-c407-4dbb-ad90-4164b107d977
function get_velocities(point)
	fleet_size = get_fleet_size(point)
	point[1:fleet_size]
end

# ╔═╡ 653ea516-ea8f-429e-8c6b-ec5d852a09a7
function get_distances(point)
	fleet_size = get_fleet_size(point)
	point[fleet_size + 1:fleet_size + 1 + fleet_size - 2]
end

# ╔═╡ f8a8834e-b8fe-4dc8-8528-4b72148fda6f
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

# ╔═╡ 1431a6cc-1a91-4357-b624-8ed77311a426
function apply_action(mechanics::CCMechanics, velocity, action::CCAction)
	if action == backwards
		return velocity - mechanics.acceleration*mechanics.t_act
	elseif action == neutral
		return velocity
	else
		return velocity + mechanics.acceleration*mechanics.t_act
	end
end

# ╔═╡ e4627d05-2f02-4bdd-b4ac-2c697f5c3628
function speed_limit(mechanics::CCMechanics, agent, v, action::CCAction)
	if agent == :ego
		min, max = mechanics.v_ego_min, mechanics.v_ego_max
	elseif agent == :front
		min, max = mechanics.v_front_min, mechanics.v_front_max
	else
		error("Argument `agent` must be :ego or :front but was $agent")
	end
	acceleration = mechanics.acceleration*mechanics.t_act
	if action == backwards && v - acceleration < min
		return neutral
	elseif action == forwards && v + acceleration > max
		return neutral
	else
		return action
	end
end

# ╔═╡ d5a28ba8-70fe-4fb2-a9b6-a151ec52fd8b
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

		front_action′ = speed_limit(mechanics, :front, v_front, front_action)
		
		v_front = apply_action(mechanics, v_front, front_action′)
	
	    action′ = speed_limit(mechanics, :ego, v_ego, action)
	    
	    v_ego = apply_action(mechanics, v_ego, action′)
	
	    new_vel = v_front - v_ego;
	
	    distance += mechanics.t_act*((old_vel + new_vel)/2);
	    (v_ego, v_front, distance)
	end
end

# ╔═╡ c99e6ef7-3318-4148-9e52-b1116c6ad073
function simulate_sequence(mechanics::CCMechanics, duration, s0, policy::Function)
	s0 = Tuple(Float64(x) for x in s0)
    states, times = [s0], [0.0]
    s, t = s0, 0
    while times[end] <= duration - mechanics.t_act
        action = policy(s)
        s = simulate_point(mechanics, s, action)
		t += mechanics.t_act
        push!(states, s)
        push!(times, t)
    end
    (;states, times)
end

# ╔═╡ 95f84ae0-f42b-4691-8287-47a6a721190f
states, times = simulate_sequence(m, 100, (0, 0, 20), (_...) -> rand([backwards neutral forwards]))


# ╔═╡ 911407b6-daa3-44a3-ba2f-bbd96fbb2710
#=╠═╡
simulate_point(m, point, [0.34], action)
  ╠═╡ =#

# ╔═╡ 2565d5b7-2fa5-46d6-a445-6a89b773d595
# This cell fails the first time you run it for some reason. Dontworryaboutit.
#gif(animate_cars(states), show_msg=:false, fps=10)

# ╔═╡ fe5ecd5a-cda8-4c97-856f-a36401dbaadf
function plot_cars(states, time::Int64)
	distances = []
	for i in 1:m.fleet_size - 1
		distances ← [s[m.fleet_size + i] for s in states]
	end
	distances = [ d[time + 1] for d in distances]
	positions = [ sum(distances[1:i]) for (i, _) in enumerate(distances)]

	# front
	plot(
		xlims=(-9, max(50, positions[end] + 09)),
		ylims=(0, 2),
		#xflip=true,
		yticks=[0],
		legend=:outertop,
		size=(600, 200),
		label="cars",
		xlabel="distance to front")
	annotate!([(0, 1, "🚙", 10)])
	annotate!([(p, 1, "🚗", 10) for p in positions])

	scatter!([0], label="time: $(time)", alpha=0, marker=0)
end

# ╔═╡ 308cc16b-1c00-4689-9187-45abf1967ca4
function plot_landscape(distance_covered)
	annotate!([(distance_covered%418, 0.3, "🌻")])
	annotate!([((distance_covered + 60)%418, 0.7, "🌳")])
	annotate!([((distance_covered + 100)%418, 0.6, "🌳")])
	annotate!([((distance_covered + 180)%418, 1.5, "🌲")])
	annotate!([((distance_covered + 210)%418, 1.4, "🌳")])
	annotate!([((distance_covered + 270)%418, 1.6, "🌳")])
	annotate!([((distance_covered + 290)%418, 1.8, "⛺")])
	annotate!([((distance_covered + 350)%418, 0.3, "🌳")])
end

# ╔═╡ 20fd3eb5-3bc1-4862-9aa0-d7a01f977fe3
function animate_cars(states) # TODO: Use time to support non-1 delta time
	gaston() # Gaston backend supports emoji
	t_max = length(states) - 1
	distance_covered = 0
	velocities = [s[1] for s in states] # Velocity for front car
	anim = @animate for t in 1:t_max
		plot_cars(states, t)
		distance_covered += velocities[t + 1] # I don't remember why it was + 1
		plot_landscape(distance_covered)
	end
	# Add a delay before reset
	[frame(anim) for _ in 1:10]
	gr()
	anim
end

# ╔═╡ 4c0f483c-147a-4325-b907-16d914e9205e
md"""
## Shielding

Code to interpret the shield, and stuff I just thoughtlessly copied over.
"""

# ╔═╡ 9da71f71-fc87-49c4-86b0-9dff82298465
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

# ╔═╡ 2bc74997-0d20-4edf-8eb2-5d2603a7a377
instances(CCAction)

# ╔═╡ 8f1897ff-b9de-4a55-9f39-830dae4287eb
bitify(x::Int64) = string(x, base=2, pad=64)

# ╔═╡ 7c436a91-c2a2-49d1-94c9-828b53b7a901
no_action = actions_to_int([])

# ╔═╡ bf592609-b0d9-4be6-9af3-6de419dbf6ba
any_action = actions_to_int(instances(CCAction))

# ╔═╡ ef90454b-6226-4277-8ae3-7be0ba88a8f8
#=╠═╡
simulation_function(point, action, [1])
  ╠═╡ =#

# ╔═╡ 034626dc-dc37-462e-818a-a0fe06a50979
function countunique(array::T) where T<:AbstractArray{S} where S
	result = Dict{S, Int}(u => 0 for u in unique(array))
	for s in array
		result[s] += 1
	end
	result
end

# ╔═╡ b3e8b012-57c0-48f1-86a8-cd06b8971d46
md"""

`samples_per_axis′ =` $(@bind samples_per_axis′ NumberField(1:10, default=1))

`samples_per_random_axis =` $(@bind samples_per_random_axis NumberField(1:10, default=3))
"""

# ╔═╡ 52cee5fe-75ac-42bc-b422-8235108e9d8d
samples_per_axis = (1, 1, 1)

# ╔═╡ b4a84cfd-13a3-4c00-81e2-b28d288b23d2
md"""
Randomness space: The random behaviour of the front car is based on a number between 0 and 1, which is interpreted in different ways depending on the state. (Wheter it is inside sensor range or not.)
"""

# ╔═╡ c4cbe6e7-3497-4b84-b66a-947fa85b0ee2
randomness_space = Bounds((0,), (1,))

# ╔═╡ da8a843d-b5c7-4155-b90c-3df160996c13
md"""
## Showing the Imported Shield
"""

# ╔═╡ 465a1c6a-52f2-4ab9-b950-caaae1c8d3fd
@bind shieldpath TextField(80, 
	default = pwd() ⨝ "../CC Shield/Cruise Control.shield")

# ╔═╡ 8d6cd687-0964-4060-a6b2-4947d595d576
shield = robust_grid_deserialization(shieldpath)

# ╔═╡ 05305c4a-a1e6-40b4-bb94-e15e77929ef3
begin
	function draw′(grid, slice)
		draw(grid, slice, 
			colors=cgrad(:glasbey_category10_n256),
			clims=(no_action, any_action),
			size=(800,400),
			legend=nothing,
			colorbar=:right)
	end
end

# ╔═╡ 83d417f9-b257-4abd-907a-2449c083748c
fleet_size = 2

# ╔═╡ 5db3cdc1-c8ec-4053-a058-b1ed03d2b95e
function plot_sequence(points, times; m=m, plotargs...)
	N = fleet_size - 1
	layout = (N, 1)
	linewidth = 4

	plots = []

	for n in 1:N
		distances = [point[n + fleet_size] for point in points]
		p1 = plot(times, distances; 
			label="distance $n",
			ylabel="v",
			xlabel="t", 
			linewidth=linewidth,
			linecolor=colors.ALIZARIN,
			plotargs...)

		# mark safety violations
		unsafe_ts, unsafe_ds = [], []
		for (t, d) in zip(times, distances)
			if !(m.distance_min <= d < m.distance_max)
				push!(unsafe_ts, t)
				push!(unsafe_ds, d)
			end
		end
		if length(unsafe_ts) > 0
			scatter!(unsafe_ts, unsafe_ds, 
				label="safety violation",
				marker=:utriangle,
				markercolor=colors.ALIZARIN,
				markerstrokecolor=:white,
				ms=4)
		end

		plots ← p1
	end
	plot(plots...; layout, size=(600, 200*(fleet_size - 1)))
end

# ╔═╡ 09447a99-25b6-4c25-ad2a-a5127d1a3378
starting_point = [
	[0 for _ in 1:fleet_size]..., 
	[20 for _ in 1:fleet_size - 1]...
] |> Tuple

# ╔═╡ 84a75f54-16af-4430-8e1c-5301ddbbe0a3
starting_point

# ╔═╡ 172e3022-eb28-460f-8fca-ed297f0f3a73
permutations_with_replacement = Iterators.product([instances(CCAction) for _ in 1:fleet_size - 1]...) |> collect

# ╔═╡ 2bf28352-02c3-459d-80ca-12157887542f
# Number of different values the shield can have. 
# NB: Not the max value of the int because of sub-optimal encoding.
permutations_with_replacement |> powerset |> collect |> length

# ╔═╡ 583ca101-265a-4a68-a4c3-36dd544d6180
function clamp_point(m::CCMechanics, p)
	# Idk if clamping velocity would do anything. Shouldn't.
	#for i in 1:fleet_size
	#	p[i] = clamp(p[i], m.v_min, m.v_max)
	#end
	p = collect(p)
	for i in fleet_size + 1:fleet_size + fleet_size - 1
		p[i] = clamp(p[i], m.distance_min, m.distance_max)
	end
	Tuple(p)
end

# ╔═╡ d42f6a70-d65f-4e68-8481-d51a3c1ab8fb
function simulation_function(p, a::CCAction, r)
	p′ = simulate_point(m, p, r, a)
	# Clamp the states so that overshooting max distance isn't a winning strategy
	return clamp_point(m, p′)
end

# ╔═╡ bc6d7025-7567-4a7d-b3d3-70161f65c3f4
model = SimulationModel(simulation_function, randomness_space, samples_per_axis, samples_per_random_axis)

# ╔═╡ 20b37794-47de-46cb-b158-1dd7d0f42962
SupportingPoints(model.samples_per_random_axis, model.randomness_space) |> collect

# ╔═╡ 4b651d7e-7e05-4cdf-a5d7-734653183e96
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ b3a94518-6966-48e9-a2e0-59e9d0e8c310
clamp_point(m, [-100 for _ in 1:fleet_size + fleet_size - 1])

# ╔═╡ 07645bb8-9f8d-4b0e-90ec-34466a966786
begin
	function is_safe(point, m=m) 
		[m.distance_max >= point[i] > m.distance_min
			for i in fleet_size + 1:fleet_size + fleet_size - 1
		] |> all
	end
	
	function is_safe(bounds::Bounds, m=m)
			is_safe([bounds.lower[i] 
				for i in 1:fleet_size + fleet_size - 1], m) &&

			# Bounds are inclusive in the lower bound and strict in the upper bound.
			is_safe([prevfloat(bounds.upper[i]) 
				for i in 1:fleet_size + fleet_size - 1], m)
	end
end

# ╔═╡ 54abc354-9c80-4bf8-8167-f8b7a3ceec21
is_safe(Bounds(box(shield, 20, 20, 49)))

# ╔═╡ 84236123-88d6-4f15-af8e-8b5cc4632606
@bind point PlutoUI.combine() do e
	
	velocities = [e(NumberField(m.v_ego_min:2:m.v_ego_max, default=0))
			for _ in 1:fleet_size]
	
	distances = [e(NumberField(m.distance_min:m.distance_max, default=40))
			for _ in 1:fleet_size - 1]

	md"""
	`point = ` $(velocities)
	$(distances)
	"""
end

# ╔═╡ 9efcf9d2-424e-4595-8e16-311eddbc6846
get_fleet_size(point)

# ╔═╡ a20365bd-b5ab-4b98-a5c8-1a892a763275
get_velocities(point)

# ╔═╡ 81c72668-c674-425e-9634-5e7dc6596159
get_distances(point)

# ╔═╡ 05c9631f-6cd3-4017-b2bb-99a3a99a044e
is_safe(point)

# ╔═╡ c403ff95-26db-4d72-87a2-a00d4ea3a77e
SupportingPoints(model.samples_per_axis, box(shield, point)) |> collect

# ╔═╡ e2ec2596-8a0c-4d82-8b9a-d39838858898
[random_front_behaviour(m, point, p)
	for p in SupportingPoints(model.samples_per_random_axis, model.randomness_space)]

# ╔═╡ b7d66268-8a40-499d-aaca-d6e59f0ee14f
partition = box(shield, point)

# ╔═╡ c9d3f5df-4707-4875-beed-f7ebbc8596fb
Bounds(partition) |> is_safe

# ╔═╡ 6f8a09ac-bfa4-4ecc-ba85-5340d2ae5976
slice = let
	indices = box(shield, point).indices
	slice = [indices[1], Colon(), Colon()]
end

# ╔═╡ 6e56a1ce-42f2-466d-b2d4-686252c324dd
let
	draw′(shield, slice)
	plot!(xlabel="velocity 1",
			ylabel="distance 0",)
end

# ╔═╡ f57469d0-1b4d-4ff9-ac46-ebec7f17e92c
partition′ = box(shield, [round(v) for v in point])

# ╔═╡ 2f906afa-a599-4c4b-9c7d-b30125a1fa76
Bounds(partition)

# ╔═╡ 8196a05e-b52c-4df4-b56c-09d9a590ba75
Bounds(partition′)

# ╔═╡ b4e94daf-4ca4-4460-8868-d58ef706a1ef
get_value(partition)

# ╔═╡ dd5faeb3-42f2-43ca-ace4-493e578bca77
Bounds(partition)

# ╔═╡ 107b960f-1a75-41f9-9cb9-195877ad6184
shielded_random = s -> begin
	if s ∈ shield
		partition = box(shield, s)
		
		allowed = int_to_actions(CCAction, get_value(partition))
		
		if allowed == []
			return rand(instances(CCAction))
		end
		return rand(allowed)
	else
		return rand(instances(CCAction))
	end
end

# ╔═╡ 0382588a-ac96-4528-9fee-67ab93d4a1f8
let
	animation = @animate for i in 1:10
		
		trace = simulate_sequence(m, 120, starting_point, shielded_random)
	
		plot_sequence(trace..., title="Shielded Trace", legend=:topleft)
	end
	gif(animation, fps=1, show_msg=false)
end

# ╔═╡ 614c630a-f0e5-44a3-bdce-ee28b7a3e220
shielded_random(point)

# ╔═╡ 784a58a0-66d8-41a3-a07e-52c29083db55
md"""
# Mainmatter

Time for UPPAAL
"""

# ╔═╡ 2da31069-e4ee-4342-82e4-e914a8f01ca7
md"""
## Executing Query
"""

# ╔═╡ dc8aba2c-4909-4417-a421-b036e5956a13
working_dir = mktempdir(prefix="jl_asv_")

# ╔═╡ 8fa0e536-a470-4f26-b93a-3878155ae20c
@bind model_file TextField(80, pwd() ⨝ "Random Fleet.xml")

# ╔═╡ a3e84ad1-feed-4a84-b520-c01e81af5898
if !isfile(model_file)
	md"!!! warning \"Not found\""
else
	md"Model file found 👍"
end

# ╔═╡ c72ba902-caec-42cb-bbaa-cedc6a9305c3
# Replace single line break with space, 
# and multiple line breaks with single line break.
function my_parse(str::AbstractString)
	result = ""
	for line in split(str, "\n")
		if occursin(r"^\s*$", line)
			result *= "\n"
		else
			result *= replace(line, r"^\s*" => " ")
		end
	end
	result
end

# ╔═╡ 6defb489-3a76-4902-b19b-95ff4f4db58f
raw_query =
	"""
	Pr[<=10;1000](<> exists (i : int[0, fleetSize - 1]) 
		(velocity[i] < minVelocity || velocity[i] > maxVelocity)
	)
	
	simulate[<=100;1000] {
		velocity[0], velocity[1],
		distance[0],
		acceleration[0], acceleration[1]
	}
	"""

# ╔═╡ 96d6df0c-4ebf-4df2-b375-94ba0288e7c3
simulation_query = my_parse(raw_query)

# ╔═╡ 1bad5366-e677-410e-a246-323520d1c47c
simulation_query |> multiline

# ╔═╡ 37521cac-c2c8-49fa-924c-bed66fa7a640
begin
	query_file = working_dir ⨝ "query.q"
	write(query_file, simulation_query)
	query_file |> read |> String
end

# ╔═╡ eb6dbf15-cfa3-46c9-b27e-78f2d0ff421f
if isfile(query_file) && isfile(model_file)
	output = Cmd([
		"verifyta",
		"-s",
		#"--truncation-time-error", "0.01",  # Get less "lag" or "skips"
		#"--truncation-error", "0.01", 		# Get less "lag" or "skips"
		model_file,
		query_file
	]) |> read |> String
end

# ╔═╡ 6c814120-8147-41fb-8d09-15d1ada9d796
output[1:min(length(output), 5000)] |> multiline

# ╔═╡ 13982ef7-9b60-44f4-a622-dde716b13d5a
md"""
## Reading Resulting Traces
"""

# ╔═╡ 0913ea9c-8c98-47bc-985b-89780c83b2cd
function parse_pair(str)
	left = match(r"\(([-0-9e.]+),", str)[1]
	left = parse(Float64, left)
	right = match(r",([-0-9e.]+)\)", str)[1]
	right = parse(Float64, right)
	(left, right)
end

# ╔═╡ 47d9eeaa-cd33-4174-9808-4b44a50461d8
parse_pair("(0.002,50.102)")

# ╔═╡ ef68fd08-65f4-436d-8b02-f6db9c957a48
function parse_trace(str)
	[parse_pair(s) for s in split(str, " ") if s != ""]
end

# ╔═╡ cb1ce596-69a5-491f-abae-c15a4a094753
parse_trace(" (0,50) (0.02,50.0006) (0.04,50.002) (0.06,50.00419999999999)")

# ╔═╡ 5ec9aa5a-a020-4049-9067-a5d7f195a36d
keyword = "velocity"

# ╔═╡ 83faaf3f-e158-4370-ab16-cba20323ef54
re_trace = Regex("$keyword\\[(?<index>\\d+)\\]:\\n(?<traces>\\[(?<traceid>\\d+)\\]: (?<values>.*)\\n)+", "m")

# ╔═╡ 07bb0511-732f-43c1-9204-2c53c9755f87
function get_raw_traces(output::String, keyword::String)
	result = Dict()
	re_traces = Regex("$keyword\\[(?<index>\\d+)\\]:\\n(?<traces>\\[(?<traceid>\\d+)\\]:(?<values>.*)\\n)+", "m")

	re_trace = Regex("\\[(?<traceid>\\d+)\\]: (?<values>.*)\\n")
	
	for outer_match in eachmatch(re_traces, output)
		index = parse(Int64, outer_match[:index])
		result[index] = Dict()
		for inner_match in eachmatch(re_trace, outer_match.match)
			traceid = parse(Int64, inner_match[:traceid])
			values = parse_trace(inner_match[:values])
			result[index][traceid] = values
		end
	end
	result
end

# ╔═╡ 8f07c2f7-f4d7-47a7-b549-2855098280cf
raw_distances = get_raw_traces(output, "distance");

# ╔═╡ 288accb9-2169-4d95-8310-a7a347a7b2e3
raw_velocities = get_raw_traces(output, "velocity");

# ╔═╡ 55395309-1def-40ff-817b-da7ede116509
function value_at_time(trace::T, time::S) where T <: AbstractVector{Tuple{Float64, Float64}} where S <: Number
	
	time_before, value_before = last([(t, v) 
		for (t, v) in trace if t <= time])

	time_after, value_after = first([(t, v) 
		for (t, v) in trace if t >= time])

	Δt = time_after - time_before
	if Δt == 0 # Happens if there is an exact match
		return value_after
	end
	fraction = (time - time_before)/Δt
	return value_before + fraction*(value_after - value_before)
end

# ╔═╡ 393c9598-a937-479b-9c31-bd2efc1c41e5
function at_regular_intervals(trace::T, interval::S)::Vector{Float64} where T <: AbstractVector{Tuple{Float64, Float64}} where S <: Number

	t_max = trace[end][1]
	return [ value_at_time(trace, i) for i in 0:interval:prevfloat(t_max) ]
end

# ╔═╡ 5e3c4d41-bfa8-49fb-9f73-e3682a663498
at_regular_intervals(raw_distances[0][0], 1.0)

# ╔═╡ d3981f15-e866-408b-81aa-c9dda32d373e
get_raw_traces(output, "distance")

# ╔═╡ f02b52a3-fd1e-4b1f-8bb9-eb2cd27c070d
# Returns list of lists of state-tuples.
# Accelerations are appended to the state, to know which joint action is taken.
function get_traces(raw_trace)
	result = []
	raw_velocities = get_raw_traces(raw_trace, "velocity")
	raw_distances = get_raw_traces(raw_trace, "distance")
	raw_accelerations = get_raw_traces(raw_trace, "acceleration")

	# raw_velocities is a 0-indexed [velocity1, velocity2, velocity3]
	# where velocityN is a 0-indexed [trace1, trace2 ...]
	
	# raw_velocities[0] chosen arbitrarily. Should all be the same number of traces.
	for (trace_id, _) in raw_velocities[0] 
		push!(result, zip(
			at_regular_intervals(raw_velocities[0][trace_id], m.t_act),
			at_regular_intervals(raw_velocities[1][trace_id], m.t_act),
			at_regular_intervals(raw_distances[0][trace_id], m.t_act),
			at_regular_intervals(raw_accelerations[0][trace_id], m.t_act),
			at_regular_intervals(raw_accelerations[1][trace_id], m.t_act)
		) |> collect)
	end
	result
end

# ╔═╡ a6f3bdcc-610c-4737-9c58-cc1df09ae188
traces = get_traces(output);

# ╔═╡ c1eb1500-623c-4dca-a91f-f9df87b095ee
traces[1]

# ╔═╡ ba696386-71e0-49df-8002-328daf95206c
begin
	# Indices into states for the 3-car trace
	velocity0 = 1
	velocity1 = 2
	distance0 = 3
	acceleration0 = 4
	acceleration1 = 5
end;

# ╔═╡ 28fa2a5e-8063-412a-84b5-89cbe92d0616
let
	i = 1
	plot([s[distance0] for s in traces[i]],
		linewidth=2,
		label="trace $i",
		xlabel="time",
		ylabel="distance 0")

	hline!([m.distance_min, m.distance_max], label=nothing, color=:black)
end

# ╔═╡ 05b427ac-dfc6-48b0-8e85-cfde6536f011
md"""
## Unsafe traces
"""

# ╔═╡ dcb170ec-dc54-4d46-a3e2-61de5cee26ac
let
	function invalid_velocity(s, m=m)
		if any(v < m.v_ego_min || v > m.v_ego_max for v in s[1:3])
			return true
		end
		return false
	end
	invalid_velocities = []
	for (id, trace) in enumerate(traces)
		if any(invalid_velocity(s, m) for s in trace)
			push!(invalid_velocities, id)
			continue
		end
	end
	(;invalid_velocities)
end

# ╔═╡ b8b00534-6f03-4d96-bc6e-51f611908236
# Return indices of unsafe traces. 
function get_unsafe_trace_ids(traces)
	result = []
	for (id, trace) in enumerate(traces)
		
		if any(!is_safe(s) for s in trace)
			
			push!(result, id)
		end
	end
	return result
end

# ╔═╡ 8ce4e365-877e-49f3-8adc-4b1e25e6ccf7
unsafe_trace_ids = get_unsafe_trace_ids(traces)

# ╔═╡ c0ebc0f4-5b5c-40a9-b5e6-5eb4192ceb0c
if length(unsafe_trace_ids) > 0
md"""
!!! info "Unsafe traces found."
"""
else
md"""
!!! success "All traces were safe"
"""
end

# ╔═╡ f77ce670-2f18-473c-9fb4-da1c5ef9517c
let
	hline([m.distance_min, m.distance_max], label=nothing, color=:black)
	for i in unsafe_trace_ids[1:min(length(unsafe_trace_ids), 28)]
		plot!([s[distance0] for s in traces[i]],
			legend=:outerright,
			linewidth=2,
			label="trace $i",
			xlabel="time",
			ylabel="distance 0")
	end
	plot!()
end

# ╔═╡ fdfb6924-2981-481a-af7d-95a23b81428b
md"""
**Select trace to inspect**

`trace_id =` $(@bind trace_id Select(unsafe_trace_ids))
"""

# ╔═╡ aaba0fba-5bc2-4ec6-a369-398f83aaf557
md"""
**Zoom in:**

xmin $(@bind xmin NumberField(0:100))

xmax $(@bind xmax NumberField(0:100, default=100))

---

ymin $(@bind ymin NumberField(-20:100))

ymax $(@bind ymax NumberField(-20:100, default=100))
"""

# ╔═╡ 99aabe32-7c65-4a9d-9397-ba2db2ca5cab
@bind action (Select(instances(CCAction) |> collect))

# ╔═╡ 7a26f7f8-043a-4d0a-aeff-b46194c313ca
reachability_function(box(shield, point), action)

# ╔═╡ 2c030279-eedd-45cc-92e0-1570e3ba74c2
model.simulation_function(point, action, [0.5])

# ╔═╡ e4397487-050e-4531-b356-cd855136bd56
[get_value(box(shield, p))
	for p in possible_outcomes(model, box(shield, point), action)]

# ╔═╡ c9904b3d-061c-47ec-8ed7-2655f08f6883
[p for p in possible_outcomes(model, box(shield, point), action)]

# ╔═╡ dbf47fae-b242-47ef-b15a-668410499d2c
md"""
**Point in time for detailed view**

`time =` $(@bind time NumberField(1:101))
"""

# ╔═╡ e8f115b2-0f11-4d2d-b816-94ef345ee33e
value_at_time(raw_distances[0][0], time)

# ╔═╡ 74eba11e-23c4-49e1-9139-8cbfe5984a2b
let
	hline([m.distance_min, m.distance_max], label=nothing, color=:black)
	plot!(
		xlim=(xmin, xmax),
		ylim=(ymin, ymax),
		title="trace $trace_id",
		xlabel="time",
		ylabel="distance")
	
	plot!([s[distance0] for s in traces[trace_id]],
		linewidth=2,
		label="distance 0",)

	scatter!([time], [traces[trace_id][time][distance0]],
		marker=:circle,
		markerstrokewidth=0,
		markercolor=:black,
		label="at time $time")
end

# ╔═╡ 78308964-0faa-4b13-bd54-e6d0368541d2
# Variable "point" already used further up to inspect the shield
s = traces[trace_id][time]

# ╔═╡ 95735d07-5c59-4254-a581-d6171f5362c7
s′ = traces[trace_id][time + 1]

# ╔═╡ 87b9bcc9-c91e-4d60-a90b-03d8915d8a9b
s[velocity0]

# ╔═╡ 71488b0b-6caf-4f07-b657-72c2776e8040
is_safe(s, m)

# ╔═╡ bc669799-3d13-4962-b790-b0ee48074036
begin
	function prettyprint(bounds::Bounds)
		"($(bounds.lower), $(bounds.upper))"
	end
	function prettyprint(bounds::Vector{Bounds{T}}, delimiter=", ") where T
		join([prettyprint(b) for b in bounds], delimiter)
	end
end

# ╔═╡ b02a89e3-6c28-48be-a5c1-44a6af2bdc72
allowed = let
	µ = box(shield, round.(s))
	allowed_middle = int_to_actions(CCAction, get_value(µ))
end

# ╔═╡ 33b9bebe-9100-4509-b797-e7ad168ba9e9
function acceleration_to_action(acceleration::Number, m=m)
	acceleration == m.acceleration ? forwards :
	acceleration == 0 ? neutral :
	acceleration == -m.acceleration ? backwards :
	error("unexpected value for acceleration: $acceleration")
end

# ╔═╡ 98236fa0-bb63-423e-b7cb-6bff0b6d121b
trace_action = acceleration_to_action(s′[acceleration1])

# ╔═╡ 549a6a06-7209-4e03-825b-c0512d5def37
let 
	if trace_action ∉ allowed
		header = "!!! danger \"Shield ignored!\""
	else
		header = "!!! success \"Safe action taken\""
	end

	Markdown.parse(header*"""

		Allowed: `[$(join([string(a) for a in allowed], ", "))]`

		Taken: `$(trace_action)`
	""")
end

# ╔═╡ c5fcf631-5896-470e-8641-e52e917f9c91
reachable = let
	µ = box(shield, round.(s))
	#µ′ = box(shield, middle_state(center(s′)))
	reachable_ix = reachability_function(µ, trace_action)
	
	[(GridShielding.Partition(shield, i)) for i in reachable_ix]
end

# ╔═╡ 4ea987bf-2447-4719-99a9-352d37f554bb
discrepancy = !any([round.(s′) ∈ Bounds(r) for r in reachable])

# ╔═╡ a9fc2526-a740-4f9c-b337-a70cfa59d738
let
	if discrepancy
		header = """!!! danger "Discrepancy" """
		
	else
		header = """!!! success "UPPAAL model in agreement with reachability function." """
	end
	
	Markdown.parse(header * """

		Action: `$trace_action`
		
		State: `$s`
	
		Subsequent state: `$s′` 
	
		Predicted squares:
		
		    $(prettyprint([Bounds(square) for square in reachable], "\n        "))
	""")
	
end

# ╔═╡ Cell order:
# ╟─1e159603-fc61-45f8-9595-f75e55318344
# ╟─f29d0dc0-f557-4522-82c3-7daa42d416e1
# ╠═c1bdc9f0-3d96-11ee-00af-b341a715281c
# ╠═6a33c245-d3ba-42ff-bac1-174e7082dd92
# ╠═59eac6a7-c4c3-4579-bc23-42549f95ae83
# ╠═d2204fe6-a71e-4131-a568-349572ce28d4
# ╠═77d2442c-8081-4cc0-90f5-65684b51b801
# ╟─dc3c1888-5846-498a-ad37-92c6d5493c1b
# ╟─5f3af2ba-af4e-4591-bc56-dbebfcb06de5
# ╠═f7233b81-e182-4b23-aa31-409ee53daf77
# ╠═7dd403fc-878d-45d3-9976-655f10dfd8bc
# ╠═0fedc544-3a81-45b3-b8b0-94c86d291f1b
# ╟─fef4c875-cab9-4300-ae02-ea0773363eb0
# ╠═3ba9e8c6-8188-4b09-9ae5-8ec73a655b14
# ╠═9efcf9d2-424e-4595-8e16-311eddbc6846
# ╠═05ecffb2-c407-4dbb-ad90-4164b107d977
# ╠═a20365bd-b5ab-4b98-a5c8-1a892a763275
# ╠═653ea516-ea8f-429e-8c6b-ec5d852a09a7
# ╠═81c72668-c674-425e-9634-5e7dc6596159
# ╠═f8a8834e-b8fe-4dc8-8528-4b72148fda6f
# ╠═1431a6cc-1a91-4357-b624-8ed77311a426
# ╠═e4627d05-2f02-4bdd-b4ac-2c697f5c3628
# ╠═d5a28ba8-70fe-4fb2-a9b6-a151ec52fd8b
# ╠═c99e6ef7-3318-4148-9e52-b1116c6ad073
# ╠═95f84ae0-f42b-4691-8287-47a6a721190f
# ╠═84a75f54-16af-4430-8e1c-5301ddbbe0a3
# ╠═911407b6-daa3-44a3-ba2f-bbd96fbb2710
# ╠═5db3cdc1-c8ec-4053-a058-b1ed03d2b95e
# ╠═09447a99-25b6-4c25-ad2a-a5127d1a3378
# ╠═2565d5b7-2fa5-46d6-a445-6a89b773d595
# ╠═fe5ecd5a-cda8-4c97-856f-a36401dbaadf
# ╟─308cc16b-1c00-4689-9187-45abf1967ca4
# ╟─20fd3eb5-3bc1-4862-9aa0-d7a01f977fe3
# ╟─4c0f483c-147a-4325-b907-16d914e9205e
# ╠═172e3022-eb28-460f-8fca-ed297f0f3a73
# ╠═2bf28352-02c3-459d-80ca-12157887542f
# ╟─9da71f71-fc87-49c4-86b0-9dff82298465
# ╠═2bc74997-0d20-4edf-8eb2-5d2603a7a377
# ╠═8f1897ff-b9de-4a55-9f39-830dae4287eb
# ╠═7c436a91-c2a2-49d1-94c9-828b53b7a901
# ╠═bf592609-b0d9-4be6-9af3-6de419dbf6ba
# ╠═d42f6a70-d65f-4e68-8481-d51a3c1ab8fb
# ╠═583ca101-265a-4a68-a4c3-36dd544d6180
# ╠═b3a94518-6966-48e9-a2e0-59e9d0e8c310
# ╠═ef90454b-6226-4277-8ae3-7be0ba88a8f8
# ╠═07645bb8-9f8d-4b0e-90ec-34466a966786
# ╠═05c9631f-6cd3-4017-b2bb-99a3a99a044e
# ╠═54abc354-9c80-4bf8-8167-f8b7a3ceec21
# ╠═c9d3f5df-4707-4875-beed-f7ebbc8596fb
# ╟─034626dc-dc37-462e-818a-a0fe06a50979
# ╟─b3e8b012-57c0-48f1-86a8-cd06b8971d46
# ╠═52cee5fe-75ac-42bc-b422-8235108e9d8d
# ╟─b4a84cfd-13a3-4c00-81e2-b28d288b23d2
# ╟─c4cbe6e7-3497-4b84-b66a-947fa85b0ee2
# ╠═bc6d7025-7567-4a7d-b3d3-70161f65c3f4
# ╠═c403ff95-26db-4d72-87a2-a00d4ea3a77e
# ╠═20b37794-47de-46cb-b158-1dd7d0f42962
# ╠═e2ec2596-8a0c-4d82-8b9a-d39838858898
# ╠═4b651d7e-7e05-4cdf-a5d7-734653183e96
# ╠═7a26f7f8-043a-4d0a-aeff-b46194c313ca
# ╟─da8a843d-b5c7-4155-b90c-3df160996c13
# ╠═465a1c6a-52f2-4ab9-b950-caaae1c8d3fd
# ╠═8d6cd687-0964-4060-a6b2-4947d595d576
# ╠═05305c4a-a1e6-40b4-bb94-e15e77929ef3
# ╠═84236123-88d6-4f15-af8e-8b5cc4632606
# ╠═b7d66268-8a40-499d-aaca-d6e59f0ee14f
# ╠═83d417f9-b257-4abd-907a-2449c083748c
# ╠═6e56a1ce-42f2-466d-b2d4-686252c324dd
# ╠═6f8a09ac-bfa4-4ecc-ba85-5340d2ae5976
# ╠═f57469d0-1b4d-4ff9-ac46-ebec7f17e92c
# ╠═2f906afa-a599-4c4b-9c7d-b30125a1fa76
# ╠═8196a05e-b52c-4df4-b56c-09d9a590ba75
# ╠═b4e94daf-4ca4-4460-8868-d58ef706a1ef
# ╠═dd5faeb3-42f2-43ca-ace4-493e578bca77
# ╠═2c030279-eedd-45cc-92e0-1570e3ba74c2
# ╠═e4397487-050e-4531-b356-cd855136bd56
# ╠═c9904b3d-061c-47ec-8ed7-2655f08f6883
# ╟─0382588a-ac96-4528-9fee-67ab93d4a1f8
# ╠═107b960f-1a75-41f9-9cb9-195877ad6184
# ╠═614c630a-f0e5-44a3-bdce-ee28b7a3e220
# ╟─784a58a0-66d8-41a3-a07e-52c29083db55
# ╟─2da31069-e4ee-4342-82e4-e914a8f01ca7
# ╠═dc8aba2c-4909-4417-a421-b036e5956a13
# ╠═8fa0e536-a470-4f26-b93a-3878155ae20c
# ╟─a3e84ad1-feed-4a84-b520-c01e81af5898
# ╟─c72ba902-caec-42cb-bbaa-cedc6a9305c3
# ╠═6defb489-3a76-4902-b19b-95ff4f4db58f
# ╠═96d6df0c-4ebf-4df2-b375-94ba0288e7c3
# ╠═1bad5366-e677-410e-a246-323520d1c47c
# ╠═37521cac-c2c8-49fa-924c-bed66fa7a640
# ╠═eb6dbf15-cfa3-46c9-b27e-78f2d0ff421f
# ╠═6c814120-8147-41fb-8d09-15d1ada9d796
# ╟─c0ebc0f4-5b5c-40a9-b5e6-5eb4192ceb0c
# ╟─13982ef7-9b60-44f4-a622-dde716b13d5a
# ╟─0913ea9c-8c98-47bc-985b-89780c83b2cd
# ╠═47d9eeaa-cd33-4174-9808-4b44a50461d8
# ╠═ef68fd08-65f4-436d-8b02-f6db9c957a48
# ╠═cb1ce596-69a5-491f-abae-c15a4a094753
# ╠═5ec9aa5a-a020-4049-9067-a5d7f195a36d
# ╠═83faaf3f-e158-4370-ab16-cba20323ef54
# ╟─07bb0511-732f-43c1-9204-2c53c9755f87
# ╠═8f07c2f7-f4d7-47a7-b549-2855098280cf
# ╠═288accb9-2169-4d95-8310-a7a347a7b2e3
# ╟─55395309-1def-40ff-817b-da7ede116509
# ╠═e8f115b2-0f11-4d2d-b816-94ef345ee33e
# ╟─393c9598-a937-479b-9c31-bd2efc1c41e5
# ╠═5e3c4d41-bfa8-49fb-9f73-e3682a663498
# ╠═d3981f15-e866-408b-81aa-c9dda32d373e
# ╠═f02b52a3-fd1e-4b1f-8bb9-eb2cd27c070d
# ╠═a6f3bdcc-610c-4737-9c58-cc1df09ae188
# ╠═c1eb1500-623c-4dca-a91f-f9df87b095ee
# ╠═ba696386-71e0-49df-8002-328daf95206c
# ╟─28fa2a5e-8063-412a-84b5-89cbe92d0616
# ╟─05b427ac-dfc6-48b0-8e85-cfde6536f011
# ╠═dcb170ec-dc54-4d46-a3e2-61de5cee26ac
# ╠═b8b00534-6f03-4d96-bc6e-51f611908236
# ╠═8ce4e365-877e-49f3-8adc-4b1e25e6ccf7
# ╟─f77ce670-2f18-473c-9fb4-da1c5ef9517c
# ╟─fdfb6924-2981-481a-af7d-95a23b81428b
# ╟─aaba0fba-5bc2-4ec6-a369-398f83aaf557
# ╠═99aabe32-7c65-4a9d-9397-ba2db2ca5cab
# ╟─dbf47fae-b242-47ef-b15a-668410499d2c
# ╠═74eba11e-23c4-49e1-9139-8cbfe5984a2b
# ╠═78308964-0faa-4b13-bd54-e6d0368541d2
# ╠═95735d07-5c59-4254-a581-d6171f5362c7
# ╠═87b9bcc9-c91e-4d60-a90b-03d8915d8a9b
# ╠═71488b0b-6caf-4f07-b657-72c2776e8040
# ╠═4ea987bf-2447-4719-99a9-352d37f554bb
# ╟─bc669799-3d13-4962-b790-b0ee48074036
# ╟─a9fc2526-a740-4f9c-b337-a70cfa59d738
# ╟─549a6a06-7209-4e03-825b-c0512d5def37
# ╠═b02a89e3-6c28-48be-a5c1-44a6af2bdc72
# ╠═33b9bebe-9100-4509-b797-e7ad168ba9e9
# ╠═98236fa0-bb63-423e-b7cb-6bff0b6d121b
# ╠═c5fcf631-5896-470e-8641-e52e917f9c91
