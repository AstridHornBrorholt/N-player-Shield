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

# ╔═╡ c1bdc9f0-3d96-11ee-00af-b341a715281c
begin
	using Pkg
	Pkg.activate("..", io=devnull)
	using GridShielding
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

# ╔═╡ 1e159603-fc61-45f8-9595-f75e55318344
md"""
# Safety strategy for Cruise Control
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
@kwdef struct CCMechanics
	fleet_size::Int64 = 3 		# Fleet size = 1 random agent + N controlled agents
	t_act::Float64 = 1 			# Period between actions
	distance_min::Float64 = 0
	distance_max::Float64 = 50
	v_min::Float64 = -10
	v_max::Float64 = 20
end

# ╔═╡ 0fedc544-3a81-45b3-b8b0-94c86d291f1b
m = CCMechanics(fleet_size=3, distance_max=50)

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

# ╔═╡ c99e6ef7-3318-4148-9e52-b1116c6ad073
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
			ylabel="distance",
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

# ╔═╡ 09447a99-25b6-4c25-ad2a-a5127d1a3378
starting_point = [
	[0 for _ in 1:m.fleet_size]..., 
	[20 for _ in 1:m.fleet_size - 1]...
] |> Tuple

# ╔═╡ 95f84ae0-f42b-4691-8287-47a6a721190f
states, times = simulate_sequence(m, 100, starting_point, (_...) -> [rand([backwards neutral forwards]) for _ in 1:m.fleet_size - 1])


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

Code to generate the actual shield
"""

# ╔═╡ 2b4ab48b-7e4e-4846-93d7-362a955d54b0
md"""
## Action mapping

Okay so this one is a doozy. 

Recall that the `Grid` type encodes a set number of partitions each associated with an integer value. That integer represents a set of allowable actions.

Now. This set representation does not directly support vectors of actions. Only sets of actions which are (or can be converted to) integers can be encoded as integers.

This presents a challenge for joint actions, which are best represented as vectors.
So before the set of allowable joint actions can be encoded as an integer, each joint action has to be encoded as an integer also. 

This cannot be done with the same `action_to_int` function, because that encodes them as a set; not a vector. Instead, functions `joint_action_to_int` and it's inverse are defined.
"""

# ╔═╡ 172e3022-eb28-460f-8fca-ed297f0f3a73
permutations_with_replacement = Iterators.product([instances(CCAction) for _ in 1:m.fleet_size - 1]...) |> collect

# ╔═╡ 2bf28352-02c3-459d-80ca-12157887542f
# Number of different values the shield can have. 
# NB: Not the max value of the int because of sub-optimal encoding.
permutations_with_replacement |> powerset |> collect |> length

# ╔═╡ 7db236df-8918-4ad2-887e-a053327e2338
function joint_action_to_int(joint_action::Union{Tuple, Vector})::Int64
	bits = 2 # Number of bits used to represent each action
	l = length(joint_action)
	result::Int64 = 0
	for (i, a) in enumerate(joint_action)
		a = Int64(a)
		a > 2^bits && error("Action size too large. Edit this function.")
		result += a<<(bits*(i - 1))
	end
	result
end

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
const no_action = actions_to_int([])

# ╔═╡ 97d2cfda-ab59-42fb-9fe5-ad1d9c25f6e3
const any_action = actions_to_int([joint_action_to_int(a) 
	for a in permutations_with_replacement])

# ╔═╡ c2546161-03c9-47a4-ad77-9eb852aecd3d
# You can count to check that there are 3^(fleet_size - 1) ones in the bitstring
any_action |> bitify

# ╔═╡ e49c01cf-93da-4893-9fdb-4ccb69b80a0b
int_to_actions(Int64, typemax(Int64))

# ╔═╡ 9c8154f4-fc4d-49e9-bed0-257c5abce2c0
function int_to_joint_action(int::Int64, joint_action_length)::Vector{CCAction}
	bits = 2 # Number of bits used to represent each action
	result = CCAction[]
	for i in 1:joint_action_length
		shift = bits*(i - 1)
		action = (0b11<<shift & int)>>shift # trust me on this one.
		result ← action |> CCAction
	end
	result
end

# ╔═╡ 93b82d88-d967-4caa-a7a2-83a64d4833b3
int_to_joint_action(0, m.fleet_size - 1)

# ╔═╡ f00d17b3-12ef-4248-ae19-ae8b952c51e1
md"""
## Simulation function

The function for taking a single step needs to be wrapped up, so that it only takes the arguments `point`, `action` and `random_outcomes`.
"""

# ╔═╡ 583ca101-265a-4a68-a4c3-36dd544d6180
function clamp_point(m::CCMechanics, p::A)::A where A
	# Idk if clamping velocity would do anything. Shouldn't.
	#for i in 1:m.fleet_size
	#	p[i] = clamp(p[i], m.v_min, m.v_max)
	#end
	
	for i in m.fleet_size + 1:m.fleet_size + m.fleet_size - 1
		p[i] = clamp(p[i], m.distance_min, m.distance_max)
	end
	p
end

# ╔═╡ d42f6a70-d65f-4e68-8481-d51a3c1ab8fb
begin
	function simulation_function(p, a::Int64, r, m=m)
		a′ = int_to_joint_action(a, m.fleet_size - 1)
		p′ = simulate_point(m, p, r, a′)
		# Clamp the states so that overshooting max distance isn't a winning strategy
		return clamp_point(m, p′)
	end

	function simulation_function(p, a::T, r) where T<:Union{Tuple, AbstractArray}
		simulation_function(p, joint_action_to_int(a), r)
	end
end

# ╔═╡ b3a94518-6966-48e9-a2e0-59e9d0e8c310
clamp_point(m, [-100 for _ in 1:m.fleet_size + m.fleet_size - 1])

# ╔═╡ 32d19beb-b4cb-4767-a094-22d7952d9be8
md"""
## Safety Property
The cars should not crash, so the distance between cars should always be greater than zero.
"""

# ╔═╡ 07645bb8-9f8d-4b0e-90ec-34466a966786
begin
	function is_safe(point, m=m)::Bool
		[m.distance_max > point[i]::Float64 > m.distance_min
			for i in m.fleet_size + 1:m.fleet_size + m.fleet_size - 1
		] |> all
	end
	
	function is_safe(bounds::Bounds{Float64}, m=m)::Bool
			is_safe([bounds.lower[i] 
				for i in 1:m.fleet_size + m.fleet_size - 1]) &&

			# Bounds are inclusive in the lower bound and strict in the upper bound.
			is_safe([prevfloat(bounds.upper[i]) 
				for i in 1:m.fleet_size + m.fleet_size - 1])
	end
end

# ╔═╡ 11fc2ce9-bb18-407f-90fc-4c60c8a65e7e
is_safe(Bounds(Float64[0, 0, 0, 49, 49], Float64[2, 2, 2, 50, 50]))

# ╔═╡ 1813649d-05f8-4d81-88b3-7313e5f16f89
is_safe(Bounds(Float64[0, 0, 0, 50, 50], Float64[2, 2, 2, 51, 51]))

# ╔═╡ 43e1f427-aa70-4210-afbf-9d142c52b0bc
m

# ╔═╡ 28237ef9-6a65-407f-8a1c-0dc49cb8a1d7
Bounds(Float64[2, 2, -2, 0, 50], Float64[4, 4, 0, 1, 51]) |> is_safe

# ╔═╡ 270796fb-2c5b-4fb1-b27c-58d354c87e36
md"""
## Grid
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
function get_grid_bounds(m::CCMechanics)::Bounds
	Bounds(
		vcat(
			[m.v_min for _ in 1:m.fleet_size], 	# Velocity lower bounds
			[m.distance_min for _ in 1:m.fleet_size - 1] # Distance lower bounds
		),
		vcat(
			[m.v_max + 2 for _ in 1:m.fleet_size],
			[m.distance_max + 1 for _ in 1:m.fleet_size - 1]
			# ...and corresponding upper bounds.
			# +1 and +2 to make sure inside bounds
		)
	)
end

# ╔═╡ 194b8f6d-c02f-44be-9635-95f0f5bdb9bc
grid_bounds = get_grid_bounds(m)

# ╔═╡ 6a9e0327-fd4a-4357-a30f-fe05ff487736
granularity = get_granularity(m)

# ╔═╡ 9fb7bb68-c1d7-481b-b3ba-201e4d9bc43c
function safety_init(x::Bounds)::Int32
	is_safe(x) ? any_action : no_action
end

# ╔═╡ 82cb8845-5eb9-4dac-bab2-47a5e9761bee
begin
	grid = Grid(granularity, grid_bounds, data_type=Int32)
	initialize!(grid, safety_init)
end

# ╔═╡ 06e52243-b8a9-4335-8452-3fb7d6d153a8
is_safe(box(grid, [0 for _ in 1:m.fleet_size + m.fleet_size - 1]) |> Bounds)

# ╔═╡ 240eda51-2e54-4529-bfef-35e29747af57
grid.array |> unique

# ╔═╡ 034626dc-dc37-462e-818a-a0fe06a50979
function countunique(array::T) where T<:AbstractArray{S} where S
	result = Dict{S, Int}(u => 0 for u in unique(array))
	for s in array
		result[s] += 1
	end
	result
end

# ╔═╡ 9288cc4f-f773-4ba1-a7bd-90d5c421db39
grid.array |> countunique

# ╔═╡ b3e8b012-57c0-48f1-86a8-cd06b8971d46
md"""
## Simulation Model

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

# ╔═╡ 20b37794-47de-46cb-b158-1dd7d0f42962
SupportingPoints(model.samples_per_random_axis, model.randomness_space) |> collect

# ╔═╡ e2ec2596-8a0c-4d82-8b9a-d39838858898
[random_front_behaviour(m, p) 
	for p in SupportingPoints(model.samples_per_random_axis, model.randomness_space)]

# ╔═╡ 4b651d7e-7e05-4cdf-a5d7-734653183e96
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ da8a843d-b5c7-4155-b90c-3df160996c13
md"""
## Time to make the shield!
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
	joint_actions = [joint_action_to_int(ja) for ja in joint_actions]
	vec(joint_actions)
end

# ╔═╡ dfc8cb50-b08f-4006-8e6f-de058ee0bf98
if make_shield_button > 0
	reachability_function_precomputed = 
		get_transitions(reachability_function, joint_action_space, grid)
end;

# ╔═╡ 8600bae3-6f6a-4ca0-8b6d-5e4857c12985
length(grid)

# ╔═╡ afceb89c-26ed-4d7f-b542-8031cc11deba
@bind imported_shield_fp FilePicker()

# ╔═╡ 8d6cd687-0964-4060-a6b2-4947d595d576
imported_shield = if isnothing(imported_shield_fp)
	nothing
else
	imported_shield_fp["data"] |> IOBuffer |> robust_grid_deserialization
end

# ╔═╡ 0f5ee444-afe5-4314-ab8e-a7dfff02964d
begin
	shield, max_steps_reached = grid, false

	if !isnothing(imported_shield)
		shield = imported_shield
	elseif true
		## here is the computation ##
		shield, max_steps_reached = make_shield(
			reachability_function_precomputed, 
			joint_action_space,
			grid; 
			max_steps
		)
		
	end

	shield
end

# ╔═╡ 85e07e50-a0fc-42bb-813c-8d0ab6af2b4c
if max_steps_reached
	Markdown.parse("""
	!!! warning "Max steps reached"
		The method reached a maximum iteration steps of $max_steps before a fixed point was reached. The strategy is only safe for a finite horizon of $max_steps steps.""")
end

# ╔═╡ bc55b7aa-a2b0-4307-9130-42d6327c34bf
gradient = let
	numbers = shield.array |> unique |> sort
	highest = max(numbers...)
	color_list = [colors[1 + i%length(colors)] for (i, v) in enumerate(numbers)]
	color_list[1] = colorant"#000000"
	cgrad(color_list, length(color_list), categorical=true)
end

# ╔═╡ f22987f2-acf7-4a48-b296-f20f81881a49
@bind show_point CheckBox(default=false)

# ╔═╡ 99aabe32-7c65-4a9d-9397-ba2db2ca5cab
# Joint action
@bind action PlutoUI.combine() do e
	selectors = [e(Select(instances(CCAction) |> collect))
		for i in 1:m.fleet_size - 1]
	md"""
	
	`action = ` $(selectors)
	
	` ` 
	"""
end

# ╔═╡ 84dfb0c5-2287-4f54-9abe-6c29b76f3c39
joint_action_to_int(action)

# ╔═╡ 342d3d02-4d1e-47f9-97fd-0d273a016ccd
let
	result = joint_action_to_int(action)
	(result, result |> bitify, action)
end

# ╔═╡ d6d9202e-247a-4ba8-8b4e-100841be3a8d
int_to_joint_action(joint_action_to_int(action), m.fleet_size - 1)

# ╔═╡ e0e29a56-56db-406b-acb5-3ea1adef7b00
action |> collect

# ╔═╡ 13021bce-c0e7-4e71-951d-e4124a952481
let 
	# Converting to int and back again. 
	# It's a two-step process now.
	a1 = action |> collect
	a2 = [neutral for i in 1:m.fleet_size - 1]
	a3 = [backwards for i in 1:m.fleet_size - 1]
	@show a1′ = joint_action_to_int(a1)
	@show a2′ = joint_action_to_int(a2)
	@show a3′ = joint_action_to_int(a3)

	@show joint_actions = [a1′, a2′, a3′] |> unique
	@show encoded = actions_to_int(joint_actions)
	@show encoded |> bitify

	@show decoded = int_to_actions(Int64, encoded)
	decoded′ = [int_to_joint_action(d, length(action)) for d in decoded]
	@show [[string(dd) for dd in d] for d in decoded′]
	@show a1 ∈ decoded′ 
	@show a2 ∈ decoded′
	@show a3 ∈ decoded′
	decoded′
end

# ╔═╡ 84236123-88d6-4f15-af8e-8b5cc4632606
@bind point′ PlutoUI.combine() do e
	
	velocities = [e(NumberField(m.v_min:2:m.v_max, default=0))
			for _ in 1:m.fleet_size]
	
	distances = [e(NumberField(m.distance_min:m.distance_max, default=40))
			for _ in 1:m.fleet_size - 1]

	md"""
	`point′ = ` $(velocities)
	$(distances)
	"""
end

# ╔═╡ 5646da93-955b-4b8d-aa2b-2bc05a00075f
point = collect(point′)

# ╔═╡ 9efcf9d2-424e-4595-8e16-311eddbc6846
get_fleet_size(point)

# ╔═╡ a20365bd-b5ab-4b98-a5c8-1a892a763275
get_velocities(point)

# ╔═╡ 81c72668-c674-425e-9634-5e7dc6596159
get_distances(point)

# ╔═╡ 911407b6-daa3-44a3-ba2f-bbd96fbb2710
simulate_point(m, point, [0.34], action)

# ╔═╡ 5ac6e0b7-369d-414f-8968-8c3d6cf36e5a
clamp_point(m, point)

# ╔═╡ ef90454b-6226-4277-8ae3-7be0ba88a8f8
simulation_function(point, joint_action_to_int(action), [1])

# ╔═╡ 0e0b517b-5088-4b7f-96f6-1c069360e17d
typeof(point)

# ╔═╡ 05c9631f-6cd3-4017-b2bb-99a3a99a044e
is_safe(point)

# ╔═╡ b7d66268-8a40-499d-aaca-d6e59f0ee14f
partition = box(shield, point)

# ╔═╡ d37045cf-f139-470d-be3f-ed8544e9fcaa
bounds = Bounds(partition)

# ╔═╡ c9d3f5df-4707-4875-beed-f7ebbc8596fb
is_safe(bounds)

# ╔═╡ 1c8ff33b-41c0-485f-9092-2b552cdb39d5
safety_init(bounds)

# ╔═╡ c403ff95-26db-4d72-87a2-a00d4ea3a77e
SupportingPoints(model.samples_per_axis, box(grid, point)) |> collect

# ╔═╡ 7a26f7f8-043a-4d0a-aeff-b46194c313ca
reachability_function(box(grid, point), action)

# ╔═╡ 219d83e3-0604-45d2-8db3-ee5938e8276b
slice = vcat(
	[:],
	[box(grid, point).indices[i + 1] 
		for i in 1:m.fleet_size - 1], 
	[:],
	[box(grid, point).indices[i + 1] 
		for i in m.fleet_size + 1:m.fleet_size + 1 + m.fleet_size - 3], 
)

# ╔═╡ ae07716b-d018-4d5e-84ae-de8fdf615094
encoded_actions = shield.array |> unique |> sort

# ╔═╡ 5b2a89d2-54a4-4335-8831-9a449af57399
findfirst((==(17)), encoded_actions)

# ╔═╡ 99e4dde5-4239-45d9-82b1-b21eda494b3d
# I can't get it to properly draw the actual shield, seeing as there is such 
#a big numberical difference between some of the actions.
# I can't get the heatmap to draw the value 0 as black, but 1 as non-black 
#when the maximum value is > 1000
shield_to_draw = let
	result = Grid(shield.granularity, shield.bounds, data_type=Int64)
	for partition in result
		value = get_value(GridShielding.Partition(shield, partition.indices))
		new_value = findfirst((==(value)), encoded_actions)
		set_value!(partition, new_value)
	end
	result
end

# ╔═╡ 28f000ec-9538-4c9c-afbc-ece4af32d3af
let
	draw(shield_to_draw, slice;
		colors=gradient,
		clims=(0, length(encoded_actions)),
		size=(800,400),
		legend=nothing,
		colorbar_ticks=nothing,
		colorbar=nothing)
	
	if show_point
		draw_barbaric_transition!(model, partition, joint_action_to_int(action), slice)
	end
	plot!(xlabel="v_front",
			ylabel="distance",
			size=(600, 400))
end

# ╔═╡ 12ac5894-d531-4d89-b066-38648174a6a3
[int_to_joint_action(a, m.fleet_size - 1) for a in int_to_actions(Int64, get_value(partition))]

# ╔═╡ dd5faeb3-42f2-43ca-ace4-493e578bca77
Bounds(partition)

# ╔═╡ c9904b3d-061c-47ec-8ed7-2655f08f6883
unique(possible_outcomes(model, box(shield, point), action))

# ╔═╡ e4397487-050e-4531-b356-cd855136bd56
[get_value(box(shield, p))
	for p in possible_outcomes(model, box(shield, point), action)]

# ╔═╡ 7930c464-6404-4855-ab73-0ab7ce5a24dd
shield.array |> unique |> sort

# ╔═╡ 2c030279-eedd-45cc-92e0-1570e3ba74c2
[model.simulation_function(point, action, r) 
	for r in 0:0.1:1] |> unique

# ╔═╡ b4e94daf-4ca4-4460-8868-d58ef706a1ef
get_value(partition)

# ╔═╡ 107b960f-1a75-41f9-9cb9-195877ad6184
shielded_random = s -> begin
	if s ∈ shield
		partition = box(shield, s)
		
		allowed = [int_to_joint_action(a, m.fleet_size - 1) 
				for a in int_to_actions(Int64, get_value(partition))]
		
		if allowed == []
			return rand(permutations_with_replacement)
		end
		return rand(allowed)
	else
		return rand(permutations_with_replacement)
	end
end

# ╔═╡ 0382588a-ac96-4528-9fee-67ab93d4a1f8
if true || !isnothing(imported_shield) let
	animation = @animate for i in 1:10
		
		trace = simulate_sequence(m, 120, starting_point, shielded_random)
	
		plot_sequence(trace..., title="Shielded Trace", legend=:topleft)
	end
	gif(animation, fps=1, show_msg=false)
end end

# ╔═╡ 614c630a-f0e5-44a3-bdce-ee28b7a3e220
shielded_random(point)

# ╔═╡ fe395e1f-96a8-4cc7-b11e-0fb902934e05
trace = simulate_sequence(m, 120, starting_point, shielded_random)

# ╔═╡ 33c7afd2-ce38-4158-afbd-7aae25cc0f8c
@bind i NumberField(1:length(trace.states))

# ╔═╡ 6d736288-c2a1-4307-9022-4c5e093e9438
trace.states[i]

# ╔═╡ f4cc7c54-b0d7-41f3-bd13-1c5a3a9c0836
let point = trace.states[i]
	
	slice = vcat(
		[:],
		[box(grid, point).indices[i + 1] 
			for i in 1:m.fleet_size - 1], 
		[:],
		[box(grid, point).indices[i + 1] 
			for i in m.fleet_size + 1:m.fleet_size + 1 + m.fleet_size - 3], 
	)
	
	draw(shield_to_draw, slice;
		colors=gradient,
		clims=(0, length(encoded_actions)),
		size=(800,400),
		legend=nothing,
		colorbar_ticks=nothing,
		colorbar=nothing)

	scatter!([point[1]], [point[4]])
	plot!(xlabel="v_front",
			ylabel="distance",
			size=(600, 400))
end

# ╔═╡ be63e7be-5647-4d22-b08c-0b9f1228d352
allowed = [int_to_joint_action(a, m.fleet_size - 1) 
			for a in int_to_actions(Int64, get_value(box(shield, trace.states[i])))]

# ╔═╡ b62e8995-0ce7-4685-845a-17e60e80be99
md"""
## Exporting the shield

The UI is a bit clunky but Firefox gets stressed if I try to use the `DownloadButton`s
"""

# ╔═╡ 8899dd63-121c-4207-a7cf-47424bc18a22
@bind save_destination TextField(80, default=homedir()*"/Results/N-player CC/$(m.fleet_size)-car.shield")

# ╔═╡ 8766f219-5703-4528-867f-17fac21ec2a5
save_destination, shield; @bind save_button CounterButton("save")

# ╔═╡ 298dadf8-41a4-443d-90c9-9dba1a87145c
if save_button > 0
	open(save_destination, "w") do file
		robust_grid_serialization(file, shield)
	end
	"saved."
end

# ╔═╡ 8ff68715-2eed-4f1d-a7f5-38122faa5046
@bind save_so_destination TextField(80, default="./$(m.fleet_size)-car.so")

# ╔═╡ a8109fd4-163c-4b47-b462-46c80beb9a4c
save_destination, shield; @bind save_so_button CounterButton("save shared object")

# ╔═╡ 2bf0b403-6bf6-4705-b39d-c3575f1c3003
working_dir = mktempdir()

# ╔═╡ 1d60c357-4df6-4521-b41a-8d0fd64fdb94
if save_so_button > 0
	if isfile(save_so_destination)
		rm(save_so_destination)
	end
	const libshield = get_libshield(shield; working_dir, destination=save_so_destination)
	"saved shared object."
end

# ╔═╡ 608470cc-8f28-46f8-b214-6262519966f1
md"""
## Ad-hoc testing of the so-shield
"""

# ╔═╡ 4aa00eef-9baf-4d67-8178-b18549f4f8b9
md"""
### get c value
"""

# ╔═╡ 1b976488-e975-4642-9556-47769b450e22
c_get_value(v0, v1, v2, d0, d1) = @ccall libshield.get_value(v0::Cdouble, v1::Cdouble, v2::Cdouble, d0::Cdouble, d1::Cdouble)::Clong

# ╔═╡ 760e4a42-ad92-4fed-8aa3-8f302c23f8ea
let
	velocity = [9.999999999999453,12.0,7.999999999999453]
	distance = [30.98999999999947,32.01999999999947]
	
		expected = get_value(box(shield, velocity..., distance...))
		actual = c_get_value(velocity..., distance...)
	(;expected, actual)
end

# ╔═╡ 4c1b079a-cf80-42a9-a5e2-ed417863826a
[int_to_joint_action(a, m.fleet_size - 1) for a in int_to_actions(Int64, get_value(box(shield, point)))]

# ╔═╡ 8d99b2c5-47c4-42e6-ad44-6173a6253931
let
	expected = get_value(box(shield, point...))
	actual = c_get_value(point...)
	(;expected, actual)
end

# ╔═╡ 0cad7028-15db-417c-ba66-6ceb88402d0d
let
	discrepancies = []
	for i in 1:100
		velocity = rand(Uniform(m.v_min, m.v_max), 3)
		distance = rand(Uniform(m.distance_min, m.distance_max), 2)
		
		expected = get_value(box(shield, velocity..., distance...))
		actual = c_get_value(velocity..., distance...)

		if expected != actual
			push!(discrepancies, (;expected, actual, s=(velocity..., distance...)))
		end
	end
	discrepancies
end

# ╔═╡ 31853eab-4002-43c9-b1d6-754069cc4880
md"""
### boxing
"""

# ╔═╡ efcbf61f-9375-41f0-8e7c-f389a306842c
c_box(v, dim) = @ccall libshield.box(v::Cdouble, dim::Cint)::Cint

# ╔═╡ bf6fa0ea-c723-4fd0-b916-2d8711b7775c
c_box_full(p) = [c_box(x, i - 1) for (i, x) in enumerate(p)]

# ╔═╡ 41ccb2d4-317c-421d-8162-d4a4c4f779b7
[(x, i - 1) for (i, x) in enumerate(point)]

# ╔═╡ 17e226f6-1647-400b-9173-ca26e1f064db
@bind v NumberField(-100:100)

# ╔═╡ 1045ef3c-f141-4d77-b35a-567e9c93d489
c_box(v, 4)

# ╔═╡ cd4c41bd-7cfa-462d-b32d-c4d703a4b2c6
# Mind that C indexing is off by one
(c_box_full(point) .+ 1), box(grid, point).indices

# ╔═╡ 31e799f6-759c-4371-8cee-4fd38ccf0cfa
let
	discrepancies = []
	for i in 1:100
		velocity = rand(Uniform(m.v_min, m.v_max), 3)
		distance = rand(Uniform(m.distance_min, m.distance_max), 2)
		
		expected = box(grid, point).indices
		actual = (c_box_full(point) .+ 1)

		if expected != actual
			push!(discrepancies, (;expected, actual, s=(velocity..., distance...)))
		end
	end
	discrepancies
end

# ╔═╡ Cell order:
# ╟─1e159603-fc61-45f8-9595-f75e55318344
# ╠═c1bdc9f0-3d96-11ee-00af-b341a715281c
# ╠═6a33c245-d3ba-42ff-bac1-174e7082dd92
# ╠═59eac6a7-c4c3-4579-bc23-42549f95ae83
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
# ╠═d5a28ba8-70fe-4fb2-a9b6-a151ec52fd8b
# ╟─95f84ae0-f42b-4691-8287-47a6a721190f
# ╟─c99e6ef7-3318-4148-9e52-b1116c6ad073
# ╠═911407b6-daa3-44a3-ba2f-bbd96fbb2710
# ╟─5db3cdc1-c8ec-4053-a058-b1ed03d2b95e
# ╠═09447a99-25b6-4c25-ad2a-a5127d1a3378
# ╠═2565d5b7-2fa5-46d6-a445-6a89b773d595
# ╠═fe5ecd5a-cda8-4c97-856f-a36401dbaadf
# ╟─308cc16b-1c00-4689-9187-45abf1967ca4
# ╟─20fd3eb5-3bc1-4862-9aa0-d7a01f977fe3
# ╟─4c0f483c-147a-4325-b907-16d914e9205e
# ╟─2b4ab48b-7e4e-4846-93d7-362a955d54b0
# ╠═172e3022-eb28-460f-8fca-ed297f0f3a73
# ╠═2bf28352-02c3-459d-80ca-12157887542f
# ╠═7db236df-8918-4ad2-887e-a053327e2338
# ╠═84dfb0c5-2287-4f54-9abe-6c29b76f3c39
# ╠═342d3d02-4d1e-47f9-97fd-0d273a016ccd
# ╟─9da71f71-fc87-49c4-86b0-9dff82298465
# ╠═2bc74997-0d20-4edf-8eb2-5d2603a7a377
# ╠═8f1897ff-b9de-4a55-9f39-830dae4287eb
# ╠═7c436a91-c2a2-49d1-94c9-828b53b7a901
# ╠═97d2cfda-ab59-42fb-9fe5-ad1d9c25f6e3
# ╠═c2546161-03c9-47a4-ad77-9eb852aecd3d
# ╠═e49c01cf-93da-4893-9fdb-4ccb69b80a0b
# ╠═9c8154f4-fc4d-49e9-bed0-257c5abce2c0
# ╠═93b82d88-d967-4caa-a7a2-83a64d4833b3
# ╠═d6d9202e-247a-4ba8-8b4e-100841be3a8d
# ╠═e0e29a56-56db-406b-acb5-3ea1adef7b00
# ╠═13021bce-c0e7-4e71-951d-e4124a952481
# ╟─f00d17b3-12ef-4248-ae19-ae8b952c51e1
# ╠═d42f6a70-d65f-4e68-8481-d51a3c1ab8fb
# ╠═583ca101-265a-4a68-a4c3-36dd544d6180
# ╠═b3a94518-6966-48e9-a2e0-59e9d0e8c310
# ╠═5ac6e0b7-369d-414f-8968-8c3d6cf36e5a
# ╠═ef90454b-6226-4277-8ae3-7be0ba88a8f8
# ╟─32d19beb-b4cb-4767-a094-22d7952d9be8
# ╠═07645bb8-9f8d-4b0e-90ec-34466a966786
# ╠═0e0b517b-5088-4b7f-96f6-1c069360e17d
# ╠═05c9631f-6cd3-4017-b2bb-99a3a99a044e
# ╠═06e52243-b8a9-4335-8452-3fb7d6d153a8
# ╠═11fc2ce9-bb18-407f-90fc-4c60c8a65e7e
# ╠═1813649d-05f8-4d81-88b3-7313e5f16f89
# ╠═43e1f427-aa70-4210-afbf-9d142c52b0bc
# ╠═28237ef9-6a65-407f-8a1c-0dc49cb8a1d7
# ╠═c9d3f5df-4707-4875-beed-f7ebbc8596fb
# ╟─270796fb-2c5b-4fb1-b27c-58d354c87e36
# ╠═df6eac60-61ed-47b3-a002-a7c4a4399f05
# ╠═bf5414c8-6141-43fd-826b-088858ac86d4
# ╠═194b8f6d-c02f-44be-9635-95f0f5bdb9bc
# ╠═6a9e0327-fd4a-4357-a30f-fe05ff487736
# ╠═9fb7bb68-c1d7-481b-b3ba-201e4d9bc43c
# ╠═1c8ff33b-41c0-485f-9092-2b552cdb39d5
# ╠═82cb8845-5eb9-4dac-bab2-47a5e9761bee
# ╠═d37045cf-f139-470d-be3f-ed8544e9fcaa
# ╠═b7d66268-8a40-499d-aaca-d6e59f0ee14f
# ╠═240eda51-2e54-4529-bfef-35e29747af57
# ╟─034626dc-dc37-462e-818a-a0fe06a50979
# ╠═9288cc4f-f773-4ba1-a7bd-90d5c421db39
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
# ╠═1f9b85b7-43f8-4cf6-90b1-581694f4a8f2
# ╟─1995a818-3309-458a-b753-0636bc680c27
# ╠═6f39548f-7fb0-46ae-8673-5eea5c34ad3b
# ╠═dfc8cb50-b08f-4006-8e6f-de058ee0bf98
# ╠═8600bae3-6f6a-4ca0-8b6d-5e4857c12985
# ╠═afceb89c-26ed-4d7f-b542-8031cc11deba
# ╠═8d6cd687-0964-4060-a6b2-4947d595d576
# ╠═0f5ee444-afe5-4314-ab8e-a7dfff02964d
# ╟─85e07e50-a0fc-42bb-813c-8d0ab6af2b4c
# ╠═bc55b7aa-a2b0-4307-9130-42d6327c34bf
# ╠═219d83e3-0604-45d2-8db3-ee5938e8276b
# ╠═f22987f2-acf7-4a48-b296-f20f81881a49
# ╟─99aabe32-7c65-4a9d-9397-ba2db2ca5cab
# ╠═84236123-88d6-4f15-af8e-8b5cc4632606
# ╠═5646da93-955b-4b8d-aa2b-2bc05a00075f
# ╠═ae07716b-d018-4d5e-84ae-de8fdf615094
# ╠═5b2a89d2-54a4-4335-8831-9a449af57399
# ╠═99e4dde5-4239-45d9-82b1-b21eda494b3d
# ╠═28f000ec-9538-4c9c-afbc-ece4af32d3af
# ╠═12ac5894-d531-4d89-b066-38648174a6a3
# ╠═dd5faeb3-42f2-43ca-ace4-493e578bca77
# ╠═c9904b3d-061c-47ec-8ed7-2655f08f6883
# ╠═e4397487-050e-4531-b356-cd855136bd56
# ╠═7930c464-6404-4855-ab73-0ab7ce5a24dd
# ╠═2c030279-eedd-45cc-92e0-1570e3ba74c2
# ╠═b4e94daf-4ca4-4460-8868-d58ef706a1ef
# ╠═107b960f-1a75-41f9-9cb9-195877ad6184
# ╠═0382588a-ac96-4528-9fee-67ab93d4a1f8
# ╠═614c630a-f0e5-44a3-bdce-ee28b7a3e220
# ╠═fe395e1f-96a8-4cc7-b11e-0fb902934e05
# ╠═33c7afd2-ce38-4158-afbd-7aae25cc0f8c
# ╠═6d736288-c2a1-4307-9022-4c5e093e9438
# ╠═f4cc7c54-b0d7-41f3-bd13-1c5a3a9c0836
# ╠═be63e7be-5647-4d22-b08c-0b9f1228d352
# ╟─b62e8995-0ce7-4685-845a-17e60e80be99
# ╠═8899dd63-121c-4207-a7cf-47424bc18a22
# ╠═8766f219-5703-4528-867f-17fac21ec2a5
# ╠═298dadf8-41a4-443d-90c9-9dba1a87145c
# ╠═8ff68715-2eed-4f1d-a7f5-38122faa5046
# ╠═a8109fd4-163c-4b47-b462-46c80beb9a4c
# ╠═2bf0b403-6bf6-4705-b39d-c3575f1c3003
# ╠═1d60c357-4df6-4521-b41a-8d0fd64fdb94
# ╟─608470cc-8f28-46f8-b214-6262519966f1
# ╟─4aa00eef-9baf-4d67-8178-b18549f4f8b9
# ╠═1b976488-e975-4642-9556-47769b450e22
# ╠═760e4a42-ad92-4fed-8aa3-8f302c23f8ea
# ╠═4c1b079a-cf80-42a9-a5e2-ed417863826a
# ╠═8d99b2c5-47c4-42e6-ad44-6173a6253931
# ╠═0cad7028-15db-417c-ba66-6ceb88402d0d
# ╟─31853eab-4002-43c9-b1d6-754069cc4880
# ╠═efcbf61f-9375-41f0-8e7c-f389a306842c
# ╠═bf6fa0ea-c723-4fd0-b916-2d8711b7775c
# ╠═41ccb2d4-317c-421d-8162-d4a4c4f779b7
# ╠═1045ef3c-f141-4d77-b35a-567e9c93d489
# ╠═17e226f6-1647-400b-9173-ca26e1f064db
# ╠═cd4c41bd-7cfa-462d-b32d-c4d703a4b2c6
# ╠═31e799f6-759c-4371-8cee-4fd38ccf0cfa
