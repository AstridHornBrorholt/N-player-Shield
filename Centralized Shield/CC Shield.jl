### A Pluto.jl notebook ###
# v0.19.27

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
	include("../FlatUI Colors.jl")
end

# ╔═╡ d2204fe6-a71e-4131-a568-349572ce28d4
begin
	Pkg.develop("GridShielding")
	@revise using GridShielding
end

# ╔═╡ 1e159603-fc61-45f8-9595-f75e55318344
md"""
# Safety strategy for Cruise Control
"""

# ╔═╡ 3a57c06f-0adb-4f92-9f64-f22edbefcadf
TableOfContents()

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
@kwdef struct CCMechanics
	fleet_size::Int64 = 3 		# Fleet size = 1 random agent + N controlled agents
	t_act::Float64 = 1 			# Period between actions
	distance_min::Float64 = 0
	distance_max::Float64 = 50
	v_min::Float64 = -10
	v_max::Float64 = 20
end

# ╔═╡ 0fedc544-3a81-45b3-b8b0-94c86d291f1b
m = CCMechanics(fleet_size=2)

# ╔═╡ fef4c875-cab9-4300-ae02-ea0773363eb0
md"""
### Fleet Size

The **`fleet_size`** is the total number of cars, including the front car, which is not controlled.

This means that there are **`fleet_size`** different velocity values, and **`fleet_size - 1`** distances to keep track of. 

Furthermore, the joint action of the agents has size **`fleet_size - 1`**.

If there are $n$=**`fleet_size`** cars, the state vector is $[v_1, v_2, \dots v_n, d_1, d_2, \dots d_{n - 1}]^T$

Where $v_i$ is the velocity of car $i$. Car $1$ is the first car in the fleet. And $d_i$ is the distance from car $i$ to car $i + 1$.

For the joint action, $[a_1, a_2, \dots a_{n-1}]^T$, the action $a_i$ applies to the car which has velocity $v_{i+1}$ because the first car isn't controlled.

Mind that arrays in Julia start at 1 while they start at 0 in UPPAAL.
"""

# ╔═╡ 84236123-88d6-4f15-af8e-8b5cc4632606
@bind point PlutoUI.combine() do e
	
	velocities = [e(NumberField(m.v_min:2:m.v_max, default=0))
			for _ in 1:m.fleet_size]
	
	distances = [e(NumberField(m.distance_min:m.distance_max, default=40))
			for _ in 1:m.fleet_size - 1]

	md"""
	`point = ` $(velocities)
	$(distances)
	"""
end

# ╔═╡ 3ba9e8c6-8188-4b09-9ae5-8ec73a655b14
get_fleet_size(point) = Int64((length(point) + 1) / 2)

# ╔═╡ 9efcf9d2-424e-4595-8e16-311eddbc6846
get_fleet_size(point)

# ╔═╡ 05ecffb2-c407-4dbb-ad90-4164b107d977
function get_velocities(point)
	fleet_size = get_fleet_size(point)
	point[1:fleet_size]
end

# ╔═╡ a20365bd-b5ab-4b98-a5c8-1a892a763275
get_velocities(point)

# ╔═╡ 653ea516-ea8f-429e-8c6b-ec5d852a09a7
function get_distances(point)
	fleet_size = get_fleet_size(point)
	point[fleet_size + 1:fleet_size + 1 + fleet_size - 2]
end

# ╔═╡ 81c72668-c674-425e-9634-5e7dc6596159
get_distances(point)

# ╔═╡ e7db569d-345e-46fb-9a46-61fb2c9d5b47
md"""
### Simulation Function
"""

# ╔═╡ f8a8834e-b8fe-4dc8-8528-4b72148fda6f
function random_front_behaviour(mechanics::CCMechanics, random_variable)
	if random_variable[1] < 1/3
		return backwards
	elseif random_variable[1] < 2/3
		return neutral
	else
		return forwards
	end
end

# ╔═╡ 1431a6cc-1a91-4357-b624-8ed77311a426
function apply_action(m, velocity, action::CCAction)
	if action == backwards
		velocity = velocity - 2
	elseif action == neutral
		velocity = velocity
	else
		velocity = velocity + 2
	end
	return clamp(velocity, m.v_min, m.v_max)
end

# ╔═╡ d5a28ba8-70fe-4fb2-a9b6-a151ec52fd8b
begin
	function simulate_point(mechanics::CCMechanics, 
			point,
			actions::Union{Tuple, Vector{CCAction}})

		return simulate_point(mechanics, point, rand(Uniform(0, 1)), actions)
	end
	
	function simulate_point(mechanics::CCMechanics, 
	        point, 
	        random_variable, 
	        actions::Union{Tuple, Vector{CCAction}})

		if length(actions) != mechanics.fleet_size - 1
			error("Unexpected number of actions: $(length(actions)) expected: $(mechanics.fleet_size - 1)")
		end
		if length(point) != mechanics.fleet_size*2 - 1
			error("Unexpected number of point variables: $(length(point)) expected: $(mechanics.fleet_size*2 - 1)")
		end
		
	    velocities = point[1:mechanics.fleet_size]
		distances = point[mechanics.fleet_size + 1:end]
	
	    velocity_differences = [a - b 
				for (a, b) in zip(velocities, velocities[2:end])]
	
		velocities′ = velocities |> collect
	    front_action = random_front_behaviour(mechanics, random_variable)

		velocities′[1] = apply_action(mechanics, velocities[1], front_action)

		for (i, action) in enumerate(actions)
	    	velocities′[i + 1] = apply_action(mechanics, velocities[i + 1], action)
		end
	
	
	    velocity_differences′ = [a - b 
				for (a, b) in zip(velocities′, velocities′[2:end])]
	
	    # ((old_velcity_difference + new_velcity_difference)/2)*t_act
		distances′ = [d + ((velocity_differences[i] + velocity_differences′[i])/2)*
					mechanics.t_act
				for (i, d) in enumerate(distances)]

		point′ = Float64[velocities′..., distances′...]
	    point′
	end
end

# ╔═╡ 62e0bad2-9a11-473a-a36f-5ab977df2c44
function simulate_sequence(mechanics::CCMechanics,
	duration,
	starting_point::Union{Tuple, Vector{Float64}},
	policy::Function)
	
    states, times = [starting_point |> collect], [0.0]
    point, t = starting_point, 0
    while times[end] <= duration - mechanics.t_act
        action = policy(point)
        point = simulate_point(mechanics, point, action)
		t += mechanics.t_act
        push!(states, point)
        push!(times, t)
    end
    (;states, times)
end

# ╔═╡ 5db3cdc1-c8ec-4053-a058-b1ed03d2b95e
function plot_sequence(points, times; m=m, plotargs...)
	N = m.fleet_size - 1
	layout = (N, 1)
	linewidth = 4

	plots = []

	for n in 1:N
		distances = [point[n + m.fleet_size] for point in points]
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
	plot(plots...; layout, size=(600, 200*(m.fleet_size - 1)))
end

# ╔═╡ 97c9c178-fdc6-429c-b600-6ad940a1a714
states, times = simulate_sequence(m, 100, point, (_...) -> [rand([backwards neutral forwards]) for _ in 1:m.fleet_size - 1])

# ╔═╡ 34410f0b-2858-46cf-85bf-f1bc4c809cfe
plot_sequence(states, times)

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
		xlims=(-9, max(209, positions[end] + 09)),
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

# ╔═╡ a3875aad-0ac1-4502-82bc-f3b0cd90597e
gif(animate_cars(states), show_msg=:false, fps=10)

# ╔═╡ 4c0f483c-147a-4325-b907-16d914e9205e
md"""
## Shielding

Code to generate the actual shield
"""

# ╔═╡ 2b4ab48b-7e4e-4846-93d7-362a955d54b0
md"""
### Action mapping
"""

# ╔═╡ f1e598c8-90af-43c7-a230-98ba9c745189
permutations_with_replacement = Iterators.product([instances(CCAction) for _ in 1:m.fleet_size - 1]...) |> collect

# ╔═╡ 7db236df-8918-4ad2-887e-a053327e2338
function joint_action_to_int(joint_action::Union{Tuple, Vector})
	l = length(joint_action)
	result::Int64 = 0
	for (i, a) in enumerate(joint_action)
		result += Int64(a)<<(2*(i - 1))
	end
	result
end

# ╔═╡ 2bc74997-0d20-4edf-8eb2-5d2603a7a377
instances(CCAction)

# ╔═╡ 8f1897ff-b9de-4a55-9f39-830dae4287eb
bitify(x::Int64) = string(x, base=2, pad=64)

# ╔═╡ 44ed87e8-3dd3-4b02-b1c1-45e547797dc4
[actions_to_int(p) # |> bitify
	for p in combinations(instances(CCAction))] |> sort

# ╔═╡ 7c436a91-c2a2-49d1-94c9-828b53b7a901
no_action = actions_to_int([])

# ╔═╡ 97d2cfda-ab59-42fb-9fe5-ad1d9c25f6e3
any_action = TODO: Any aciton

# ╔═╡ c2546161-03c9-47a4-ad77-9eb852aecd3d


# ╔═╡ e49c01cf-93da-4893-9fdb-4ccb69b80a0b
int_to_actions(Int64, typemax(Int64))

# ╔═╡ 9c8154f4-fc4d-49e9-bed0-257c5abce2c0
function int_to_joint_action(int::Int64, joint_action_length)
	result = CCAction[]
	for i in 1:joint_action_length
		shift = 2*(i - 1)
		action = (0b11<<shift & int)>>shift
		action = action |> CCAction
		result ← action
	end
	result
end

# ╔═╡ f00d17b3-12ef-4248-ae19-ae8b952c51e1
md"""
### Simulation function

The function for taking a single step needs to be wrapped up, so that it only takes the arguments `point`, `action` and `random_outcomes`.
"""

# ╔═╡ 583ca101-265a-4a68-a4c3-36dd544d6180
function clamp_point(m::CCMechanics, p)
	# Idk if clamping velocity would do anything. Shouldn't.
	#for i in 1:m.fleet_size
	#	p[i] = clamp(p[i], m.v_min, m.v_max)
	#end

	for i in m.fleet_size + 1:m.fleet_size - 1
		p[i] = clamp(p[i], m.distance_min, m.distance_max)
	end
	p
end

# ╔═╡ d42f6a70-d65f-4e68-8481-d51a3c1ab8fb
function simulation_function(p, a, r)
	a′ = int_to_joint_action(a, m.fleet_size - 1)
	p′ = simulate_point(m, p, r, a′)
	# Clamp the states so that overshooting max distance isn't a winning strategy
	return clamp_point(m, p′)
end

# ╔═╡ 99aabe32-7c65-4a9d-9397-ba2db2ca5cab
# Joint action
@bind action PlutoUI.combine() do e
	selectors = [e(Select(instances(CCAction) |> collect))
		for i in 1:m.fleet_size - 1]
	md"""
	`action = ` $(selectors)
	"""
end

# ╔═╡ 911407b6-daa3-44a3-ba2f-bbd96fbb2710
simulate_point(m, point, [0.34], action)

# ╔═╡ 342d3d02-4d1e-47f9-97fd-0d273a016ccd
let
	result = joint_action_to_int(action)
	(result, result |> bitify, action)
end

# ╔═╡ d6d9202e-247a-4ba8-8b4e-100841be3a8d
int_to_joint_action(joint_action_to_int(action), m.fleet_size - 1)

# ╔═╡ 13021bce-c0e7-4e71-951d-e4124a952481
let 
	a1 = action |> collect
	a2 = [neutral for i in 1:m.fleet_size - 1]
	a3 = [backwards for i in 1:m.fleet_size - 1]
	@show a1′ = joint_action_to_int(a1)
	@show a2′ = joint_action_to_int(a2)
	@show a3′ = joint_action_to_int(a3)

	@show joint_actions = [a1′, a2′, a3′]
	@show encoded = actions_to_int(joint_actions)
	@show encoded |> bitify

	@show decoded = int_to_actions(Int64, encoded)
	decoded′ = [int_to_joint_action(d, length(action)) for d in decoded]
	@show a1 ∈ decoded′ && a2 ∈ decoded′ && a3 ∈ decoded′
	decoded′
end

# ╔═╡ ef90454b-6226-4277-8ae3-7be0ba88a8f8
simulation_function(point, joint_action_to_int(action), [1])

# ╔═╡ 32d19beb-b4cb-4767-a094-22d7952d9be8
md"""
### Safety Property
The cars should not crash, so the distance between cars should always be greater than zero.
"""

# ╔═╡ 07645bb8-9f8d-4b0e-90ec-34466a966786
begin
	is_safe(point) = [m.distance_max > point[i] > m.distance_min
		for i in m.fleet_size + 1:m.fleet_size - 1
	] |> all
	
	is_safe(bounds::Bounds) = 
			is_safe((nothing, nothing, bounds.lower[3])) &&
			is_safe((nothing, nothing, bounds.upper[3]))
end

# ╔═╡ 270796fb-2c5b-4fb1-b27c-58d354c87e36
md"""
### Grid
The grid is defined by the upper and lower bounds on the state space, and some `granularity` which determines the size of the partitions.

As it turns out, the CC problem is fully discrete as long as the time step is an integer. So the granularity is given as constant.
"""

# ╔═╡ df6eac60-61ed-47b3-a002-a7c4a4399f05
function get_granularity(m::CCMechanics)
	@assert m.t_act%1 == 0 "Not implemented: Non-integer timestep."
	
	vcat(
		[2 for _ in 1:m.fleet_size], 	# Velocity granularities
		[1 for _ in 1:m.fleet_size - 1] # Distance granularities
	)
end

# ╔═╡ bf5414c8-6141-43fd-826b-088858ac86d4
function get_grid_bounds(m::CCMechanics)
	Bounds(
		vcat(
			[m.v_min for _ in 1:m.fleet_size], 	# Velocity lower bounds
			[m.distance_min for _ in 1:m.fleet_size - 1] # Distance lower bounds
		),
		vcat(
			[m.v_max for _ in 1:m.fleet_size],
			[m.distance_max for _ in 1:m.fleet_size - 1]
		)
	)
end

# ╔═╡ 194b8f6d-c02f-44be-9635-95f0f5bdb9bc
grid_bounds = get_grid_bounds(m)

# ╔═╡ 6a9e0327-fd4a-4357-a30f-fe05ff487736
granularity = get_granularity(m)

# ╔═╡ 82cb8845-5eb9-4dac-bab2-47a5e9761bee
begin

	grid = Grid(granularity, grid_bounds)

	initialize!(grid, x -> is_safe(x) ? any_action : no_action)

	grid
end

# ╔═╡ b3e8b012-57c0-48f1-86a8-cd06b8971d46
md"""
### Simulation Model

All of this is wrapped up in the following model `struct` just to make the call signatures shorter. 

`spa_v_ego =` $(@bind spa_v_ego NumberField(1:10, default=1))

`spa_v_front =` $(@bind spa_v_front NumberField(1:10, default=1))

`spa_distance =` $(@bind spa_distance NumberField(1:10, default=3))

`samples_per_random_axis =` $(@bind samples_per_random_axis NumberField(1:10, default=3))
"""

# ╔═╡ 52cee5fe-75ac-42bc-b422-8235108e9d8d
samples_per_axis = Tuple(1 for _ in 1:m.fleet_size + m.fleet_size - 1)

# ╔═╡ b4a84cfd-13a3-4c00-81e2-b28d288b23d2
md"""
Randomness space: The random behaviour of the front car is based on a number between 0 and 1, which is interpreted in different ways depending on the state. (Wheter it is inside sensor range or not.)
"""

# ╔═╡ c4cbe6e7-3497-4b84-b66a-947fa85b0ee2
randomness_space = Bounds((0,), (1,))

# ╔═╡ bc6d7025-7567-4a7d-b3d3-70161f65c3f4
model = SimulationModel(simulation_function, randomness_space, samples_per_axis, samples_per_random_axis)

# ╔═╡ c403ff95-26db-4d72-87a2-a00d4ea3a77e
SupportingPoints(model.samples_per_axis, box(grid, point)) |> collect

# ╔═╡ 20b37794-47de-46cb-b158-1dd7d0f42962
SupportingPoints(model.samples_per_random_axis, model.randomness_space) |> collect

# ╔═╡ e2ec2596-8a0c-4d82-8b9a-d39838858898
[random_front_behaviour(m, p) 
	for p in SupportingPoints(model.samples_per_random_axis, model.randomness_space)]

# ╔═╡ 4b651d7e-7e05-4cdf-a5d7-734653183e96
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ da8a843d-b5c7-4155-b90c-3df160996c13
md"""
### Time to make the shield!
"""

# ╔═╡ 1f9b85b7-43f8-4cf6-90b1-581694f4a8f2
begin
	grid, m, model # reactivity
	@bind make_shield_button CounterButton("Do it.")
end

# ╔═╡ 1995a818-3309-458a-b753-0636bc680c27
md"""
Try starting at 1 and then stepping through the iterations.

`max_steps=` $(@bind max_steps NumberField(1:1000, default=1000))
"""

# ╔═╡ 6f39548f-7fb0-46ae-8673-5eea5c34ad3b
joint_action_space = let
	actions = instances(CCAction)
	actions = [Int(a) for a in actions]
	joint_actions = Iterators.product([actions for _ in 1:m.fleet_size - 1]...)
	[joint_action_to_int(ja) for ja in joint_actions]
end

# ╔═╡ dfc8cb50-b08f-4006-8e6f-de058ee0bf98
if make_shield_button > 0
	reachability_function_precomputed = 
		get_transitions(reachability_function, joint_action_space, grid)
end;

# ╔═╡ 0f5ee444-afe5-4314-ab8e-a7dfff02964d
begin
	shield, max_steps_reached = grid, false
	
	if make_shield_button > 0

		# here is the computation
		shield, max_steps_reached = 
			make_shield(reachability_function_precomputed, joint_action_space, grid; max_steps)
		
	end
end

# ╔═╡ 85e07e50-a0fc-42bb-813c-8d0ab6af2b4c
if max_steps_reached
	Markdown.parse("""
	!!! warning "Max steps reached"
		The method reached a maximum iteration steps of $max_steps before a fixed point was reached. The strategy is only safe for a finite horizon of $max_steps steps.""")
end

# ╔═╡ b7d66268-8a40-499d-aaca-d6e59f0ee14f
partition = box(shield, point)

# ╔═╡ 0018900a-03ed-437f-a4ce-b1e967269ac3
get_value(partition)

# ╔═╡ 5b3b198d-f0df-4991-8eb7-f208418b0be0
possible_outcomes(model, partition, joint_action_to_int(action))

# ╔═╡ fe377de1-a9e0-4abd-8da1-54133d87be18
int_to_joint_action(7, 1)

# ╔═╡ 05305c4a-a1e6-40b4-bb94-e15e77929ef3
begin
	function draw′(grid)
		draw′(grid, point)
	end
	function draw′(grid, point)
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
		slice = vcat(
			[box(grid, point).indices[i] 
				for i in 1:m.fleet_size - 1], 
			[:],
			[box(grid, point).indices[i] 
				for i in m.fleet_size + 1:m.fleet_size + 1 + m.fleet_size - 3], 
			[:]
		)
		colors = [v for (k, v) in sort(action_color_dict)]
		labels = [k for (k, v) in sort(action_color_dict)]
		labels = [int_to_actions(CCAction, l) for l in labels]
		labels = [join(l, ", ") for l in labels]
		labels = ["{$l}" for l in labels]
		draw(grid, slice, 
			colors=colors, 
			color_labels=labels,
			xlabel="v_front",
			ylabel="distance",
			legend=:outerright,
			clims=(no_action, any_action),
			size=(800,400))
	end
end

# ╔═╡ 28f000ec-9538-4c9c-afbc-ece4af32d3af
let
	slice = vcat(
		[box(grid, point).indices[i] 
			for i in 1:m.fleet_size - 1], 
		[:],
		[box(grid, point).indices[i] 
			for i in m.fleet_size + 1:m.fleet_size + 1 + m.fleet_size - 3], 
		[:]
	)
	draw′(shield)
	draw_barbaric_transition!(model, partition, joint_action_to_int(action), slice)
end

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
if make_shield_button > 0 let
	animation = @animate for i in 1:10
		
		trace = simulate_sequence(m, 120, (0, 0, 50), shielded_random)
	
		plot_sequence(trace..., title="Shielded Trace", legend=:topleft)
	end
	gif(animation, fps=1, show_msg=false)
end end

# ╔═╡ 298dadf8-41a4-443d-90c9-9dba1a87145c
let
	buf = IOBuffer()
	str = get_c_library_header(shield, "CC samples_per_axis=$samples_per_axis, granularity=$granularity")
	print(buf, str)
	DownloadButton(take!(buf), "shield_dump.c")
end

# ╔═╡ Cell order:
# ╟─1e159603-fc61-45f8-9595-f75e55318344
# ╠═c1bdc9f0-3d96-11ee-00af-b341a715281c
# ╠═d2204fe6-a71e-4131-a568-349572ce28d4
# ╠═3a57c06f-0adb-4f92-9f64-f22edbefcadf
# ╠═77d2442c-8081-4cc0-90f5-65684b51b801
# ╟─dc3c1888-5846-498a-ad37-92c6d5493c1b
# ╟─5f3af2ba-af4e-4591-bc56-dbebfcb06de5
# ╠═f7233b81-e182-4b23-aa31-409ee53daf77
# ╠═7dd403fc-878d-45d3-9976-655f10dfd8bc
# ╠═0fedc544-3a81-45b3-b8b0-94c86d291f1b
# ╟─fef4c875-cab9-4300-ae02-ea0773363eb0
# ╟─84236123-88d6-4f15-af8e-8b5cc4632606
# ╠═3ba9e8c6-8188-4b09-9ae5-8ec73a655b14
# ╠═9efcf9d2-424e-4595-8e16-311eddbc6846
# ╠═05ecffb2-c407-4dbb-ad90-4164b107d977
# ╠═a20365bd-b5ab-4b98-a5c8-1a892a763275
# ╠═653ea516-ea8f-429e-8c6b-ec5d852a09a7
# ╠═81c72668-c674-425e-9634-5e7dc6596159
# ╟─e7db569d-345e-46fb-9a46-61fb2c9d5b47
# ╠═f8a8834e-b8fe-4dc8-8528-4b72148fda6f
# ╠═1431a6cc-1a91-4357-b624-8ed77311a426
# ╠═d5a28ba8-70fe-4fb2-a9b6-a151ec52fd8b
# ╠═911407b6-daa3-44a3-ba2f-bbd96fbb2710
# ╠═62e0bad2-9a11-473a-a36f-5ab977df2c44
# ╟─5db3cdc1-c8ec-4053-a058-b1ed03d2b95e
# ╠═97c9c178-fdc6-429c-b600-6ad940a1a714
# ╠═34410f0b-2858-46cf-85bf-f1bc4c809cfe
# ╠═a3875aad-0ac1-4502-82bc-f3b0cd90597e
# ╟─fe5ecd5a-cda8-4c97-856f-a36401dbaadf
# ╟─308cc16b-1c00-4689-9187-45abf1967ca4
# ╟─20fd3eb5-3bc1-4862-9aa0-d7a01f977fe3
# ╟─4c0f483c-147a-4325-b907-16d914e9205e
# ╟─2b4ab48b-7e4e-4846-93d7-362a955d54b0
# ╠═f1e598c8-90af-43c7-a230-98ba9c745189
# ╠═7db236df-8918-4ad2-887e-a053327e2338
# ╠═342d3d02-4d1e-47f9-97fd-0d273a016ccd
# ╠═2bc74997-0d20-4edf-8eb2-5d2603a7a377
# ╠═8f1897ff-b9de-4a55-9f39-830dae4287eb
# ╠═44ed87e8-3dd3-4b02-b1c1-45e547797dc4
# ╠═7c436a91-c2a2-49d1-94c9-828b53b7a901
# ╠═97d2cfda-ab59-42fb-9fe5-ad1d9c25f6e3
# ╠═c2546161-03c9-47a4-ad77-9eb852aecd3d
# ╠═e49c01cf-93da-4893-9fdb-4ccb69b80a0b
# ╠═9c8154f4-fc4d-49e9-bed0-257c5abce2c0
# ╠═d6d9202e-247a-4ba8-8b4e-100841be3a8d
# ╠═13021bce-c0e7-4e71-951d-e4124a952481
# ╟─f00d17b3-12ef-4248-ae19-ae8b952c51e1
# ╠═d42f6a70-d65f-4e68-8481-d51a3c1ab8fb
# ╠═583ca101-265a-4a68-a4c3-36dd544d6180
# ╠═99aabe32-7c65-4a9d-9397-ba2db2ca5cab
# ╠═ef90454b-6226-4277-8ae3-7be0ba88a8f8
# ╟─32d19beb-b4cb-4767-a094-22d7952d9be8
# ╠═07645bb8-9f8d-4b0e-90ec-34466a966786
# ╟─270796fb-2c5b-4fb1-b27c-58d354c87e36
# ╠═df6eac60-61ed-47b3-a002-a7c4a4399f05
# ╠═bf5414c8-6141-43fd-826b-088858ac86d4
# ╠═194b8f6d-c02f-44be-9635-95f0f5bdb9bc
# ╠═6a9e0327-fd4a-4357-a30f-fe05ff487736
# ╠═82cb8845-5eb9-4dac-bab2-47a5e9761bee
# ╟─b3e8b012-57c0-48f1-86a8-cd06b8971d46
# ╠═52cee5fe-75ac-42bc-b422-8235108e9d8d
# ╟─b4a84cfd-13a3-4c00-81e2-b28d288b23d2
# ╟─c4cbe6e7-3497-4b84-b66a-947fa85b0ee2
# ╠═bc6d7025-7567-4a7d-b3d3-70161f65c3f4
# ╠═c403ff95-26db-4d72-87a2-a00d4ea3a77e
# ╠═20b37794-47de-46cb-b158-1dd7d0f42962
# ╠═e2ec2596-8a0c-4d82-8b9a-d39838858898
# ╠═4b651d7e-7e05-4cdf-a5d7-734653183e96
# ╟─da8a843d-b5c7-4155-b90c-3df160996c13
# ╟─1f9b85b7-43f8-4cf6-90b1-581694f4a8f2
# ╟─1995a818-3309-458a-b753-0636bc680c27
# ╠═6f39548f-7fb0-46ae-8673-5eea5c34ad3b
# ╠═dfc8cb50-b08f-4006-8e6f-de058ee0bf98
# ╠═0f5ee444-afe5-4314-ab8e-a7dfff02964d
# ╟─85e07e50-a0fc-42bb-813c-8d0ab6af2b4c
# ╠═b7d66268-8a40-499d-aaca-d6e59f0ee14f
# ╠═0018900a-03ed-437f-a4ce-b1e967269ac3
# ╠═5b3b198d-f0df-4991-8eb7-f208418b0be0
# ╠═fe377de1-a9e0-4abd-8da1-54133d87be18
# ╠═05305c4a-a1e6-40b4-bb94-e15e77929ef3
# ╠═28f000ec-9538-4c9c-afbc-ece4af32d3af
# ╟─0382588a-ac96-4528-9fee-67ab93d4a1f8
# ╠═107b960f-1a75-41f9-9cb9-195877ad6184
# ╠═298dadf8-41a4-443d-90c9-9dba1a87145c
