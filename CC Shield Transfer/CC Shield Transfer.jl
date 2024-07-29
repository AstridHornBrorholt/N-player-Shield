### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ c1bdc9f0-3d96-11ee-00af-b341a715281c
begin
	using Pkg
	Pkg.activate("..", io=devnull)
	using GridShielding
	using Plots
	using PlutoLinks
	using StatsBase
	using Unzip
	using Distributions
	using Combinatorics
	using Measures
end

# ╔═╡ 57fe6e2d-92d0-4891-a1fa-a9fb0b29f81d
# ╠═╡ skip_as_script = true
#=╠═╡
begin 
	using PlutoUI
	TableOfContents()
end
  ╠═╡ =#

# ╔═╡ da8a843d-b5c7-4155-b90c-3df160996c13
md"""
# Import a shield
"""

# ╔═╡ af869f6a-d132-4c75-b0b4-440f76352c70
# ╠═╡ skip_as_script = true
#=╠═╡
@bind imported_shield_fp FilePicker()
  ╠═╡ =#

# ╔═╡ 75dbc088-74a1-4a7a-ae59-f2163b99b6f1
#=╠═╡
shield = if isnothing(imported_shield_fp)
	nothing
else
	imported_shield_fp["data"] |> IOBuffer |> robust_grid_deserialization
end
  ╠═╡ =#

# ╔═╡ ea83ab65-934a-4734-b562-f9f5223fb34f
#=╠═╡
granularity = shield.granularity
  ╠═╡ =#

# ╔═╡ 1e159603-fc61-45f8-9595-f75e55318344
md"""
# Default Mechanics the Shield was Created With

So the idea is to take a shield generated for one set of mechanics, and shield a different system with it, by way of a projection of the state space. Or something; I am not so much words today.

First there is this whole preamble which is just copy-paste d from an earlier motebook better explained there
"""

# ╔═╡ 5f3af2ba-af4e-4591-bc56-dbebfcb06de5
md"""
## Mechanics

This is all just copy-pasta
"""

# ╔═╡ f7233b81-e182-4b23-aa31-409ee53daf77
@enum CCAction backwards neutral forwards

# ╔═╡ 7ba18477-7d3a-4004-b422-46e7c850fc23
begin 
	import Base.+
	
	a::Number + b::CCAction = a+Int(b)
	
	a::CCAction + b::Number = CCAction(Int(a) + b)
end

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

# ╔═╡ 0fba5442-bba5-4a82-9821-77068368227e
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

# ╔═╡ 62e0bad2-9a11-473a-a36f-5ab977df2c44
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

# ╔═╡ 4c0f483c-147a-4325-b907-16d914e9205e
md"""
## Shielding

Same with this. Copy-pasted from CC Shield.jl
"""

# ╔═╡ 7c436a91-c2a2-49d1-94c9-828b53b7a901
no_action, any_action = actions_to_int([]), actions_to_int(instances(CCAction))

# ╔═╡ 9fb76adf-fdbd-46df-8ae9-073cacf0fb58
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

# ╔═╡ 07645bb8-9f8d-4b0e-90ec-34466a966786
begin
	is_safe(point; m=m) = m.distance_max > point[3] > m.distance_min
	
	is_safe(bounds::Bounds; m=m) = 
			is_safe((nothing, nothing, bounds.lower[3]); m) &&
			is_safe((nothing, nothing, bounds.upper[3]); m)
end

# ╔═╡ 5db3cdc1-c8ec-4053-a058-b1ed03d2b95e
function plot_sequence(states, times; dim=1, m=m, is_safe=is_safe, plotargs...)
	unzipped = unzip(states)
	layout = (2, 1)
	linewidth = 4
	
	p1 = plot(times, unzipped[1]; 
		label="v_ego",
		ylabel="v",
		xlabel="t", 
		linewidth=linewidth,
		linecolor=:green,
		plotargs...)
	
	plot!(times, unzipped[2];
		linewidth=linewidth,
		linecolor=:blue,
		label="v_front")

	p2 = plot(times, unzipped[3]; 
		xlabel="t",
		ylabel="d",
		label="distance",
		linewidth=linewidth,
		linecolor=:red,
		plotargs...)

	# mark safety violations
	unsafe_ts, unsafe_ds = [], []
	for (t, d) in zip(times, unzipped[3])
		if !(is_safe((0, 0, d)))
			push!(unsafe_ts, t)
			push!(unsafe_ds, d)
		end
	end
	if length(unsafe_ts) > 0
		scatter!(unsafe_ts, unsafe_ds, label="safety violation", marker=:ltriangle, ms=10)
	end
	
	plot(p1, p2, layout=layout, size=(800, 400))
end

# ╔═╡ 05305c4a-a1e6-40b4-bb94-e15e77929ef3
begin
	function draw′(grid, v_ego, v_front, distance)
		slice = [box(grid, v_ego, v_front, distance).indices[1], :, :]
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

# ╔═╡ c3558255-b235-4638-96a5-b40501b14b73
#=╠═╡
md"""
### Simulation Model

Simulation model for default mechanics. Used for reachability approximation.

`spa_v_ego =` $(@bind spa_v_ego NumberField(1:10, default=1))

`spa_v_front =` $(@bind spa_v_front NumberField(1:10, default=1))

`spa_distance =` $(@bind spa_distance NumberField(1:10, default=3))

`samples_per_random_axis =` $(@bind samples_per_random_axis NumberField(1:10, default=3))
"""
  ╠═╡ =#

# ╔═╡ 06cb86de-b11b-421e-85ef-7002ecff1cf5
#=╠═╡
samples_per_axis = (spa_v_ego, spa_v_front, spa_distance)
  ╠═╡ =#

# ╔═╡ de31fa0c-acc3-42c4-bac2-e9c2ef4065f6
md"""
Randomness space: The random behaviour of the front car is based on a number between 0 and 1, which is interpreted in different ways depending on the state. (Wheter it is inside sensor range or not.)
"""

# ╔═╡ f25d9d2d-baae-422a-a56f-9a7491198f00
randomness_space = Bounds((0,), (1,))

# ╔═╡ a96b2790-b7ee-4ac0-8ea3-19094eeb962b
simulation_function(p, a, r) = begin
	v_ego, v_front, distance = simulate_point(m, p, r, a)
	(   clamp(v_ego, m.v_ego_min, m.v_ego_max),
		clamp(v_front, m.v_front_min, m.v_front_max),
		clamp(distance, m.distance_min, m.distance_max))
end

# ╔═╡ 25e8dc25-5570-4b39-b353-2df981cc8c9a
#=╠═╡
model = SimulationModel(simulation_function, randomness_space, samples_per_axis, samples_per_random_axis)
  ╠═╡ =#

# ╔═╡ bd4395db-3c26-4235-9a42-fa6a7eca7041
#=╠═╡
reachability_function = get_barbaric_reachability_function(model)
  ╠═╡ =#

# ╔═╡ 2418bf90-b0ec-4cb9-b3fd-bf2b91d2ff33
md"""
### Inspect imported shield
"""

# ╔═╡ 107b960f-1a75-41f9-9cb9-195877ad6184
#=╠═╡
shielded_random = s -> begin
	s = Tuple(round(x) for x in s)
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
  ╠═╡ =#

# ╔═╡ fb88f6f9-cfba-4ccd-ba56-9e84a56ce63c
md"""
# Modifiying the mechanics

Okok so this might look a bit strange. I will admit a degree of trial and error has been employed here.

But what I found was, that you cannot just change the mechanics to just about anything, if you want the shield to still be applicable. 

The velocity can have 15 values: From -10 to 20 in increments of 2. If the acceleration (i.e. the increment) is changed, the min and max velocities have to be changed in a proportional manner so that there are still 15 possible velocities. 
"""

# ╔═╡ 0518e3ff-8c3f-49b4-92ba-871b22c7adc7
collect(m.v_ego_min:m.acceleration:m.v_ego_max)

# ╔═╡ 6ed54088-757e-4906-ab95-769563050ef9
md"""
Same has to hold true for distance. There are a lot more increments there, but the same principle applies. If the acceleration is shifted, the distance has to be shifted in a similar manner for the safety strategy to apply.

And then it doesn't matter if the distance is between 0 and 200, or if it's between 20 and 220. It is relative anyway. The same goes for velocity.

And lastly, something similar happens with the time-step. If the time-step is halved, in essence this is the same as halving the acceleration and velocity or something.
"""

# ╔═╡ 9dc03739-4704-4710-b6f5-7fab0e33a6f2
m

# ╔═╡ de7136f9-32ed-4042-b649-1bdfb9624685
begin
	t_act_multiplier = 0.8
	acceleration_multiplier = 0.5
	distance_add = 25
	velocity_add = 10
end

# ╔═╡ 3af3824c-c032-46b6-b6ae-db9f01691183
m′ =  CCMechanics(m.t_act*t_act_multiplier,
			(m.distance_min + distance_add)*t_act_multiplier*acceleration_multiplier,
			(m.distance_max + distance_add)*t_act_multiplier*acceleration_multiplier,
			m.acceleration*acceleration_multiplier,
			(m.v_ego_min + velocity_add)*t_act_multiplier*acceleration_multiplier,
			(m.v_ego_max + velocity_add)*t_act_multiplier*acceleration_multiplier,
			(m.v_front_min + velocity_add)*t_act_multiplier*acceleration_multiplier,
			(m.v_front_max + velocity_add)*t_act_multiplier*acceleration_multiplier)

# ╔═╡ b96b370d-adef-485d-9efd-2d15148be70d
fieldnames(typeof(m))

# ╔═╡ 18b71e15-9485-4019-9c4b-b400b7e823d6
getfield(m, :t_act)

# ╔═╡ 877bcf32-eed1-42ef-80b5-87c13cbf6ea3
Markdown.parse("""
	// Copy this into the UPPAAL model

	// $(join(["$f=$(getfield(m′, f))" for f in fieldnames(typeof(m′))],
		", "))
	const double t_act_multiplier = $t_act_multiplier;
	const double acceleration_multiplier = $acceleration_multiplier;
	const double distance_add = $distance_add;
	const double velocity_add = $velocity_add;
""")

# ╔═╡ 4c6fac5d-86b9-47d0-a654-77e3adc679f4
@assert length(m.v_ego_min:m.acceleration*m.t_act:m.v_ego_max) ==
	length(m′.v_ego_min:m′.acceleration*m′.t_act:m′.v_ego_max)

# ╔═╡ a9b3ccc3-58f6-4b65-9923-b4c213df6752
@assert length(m.distance_min:m.acceleration*m.t_act/2:m.distance_max) ==
	length(m′.distance_min:m′.acceleration*m′.t_act/2:m′.distance_max)

# ╔═╡ fb24a4e7-7754-4a35-bbfe-99dcf59ba50b
s0 = (0, 0, 10)

# ╔═╡ 0382588a-ac96-4528-9fee-67ab93d4a1f8
#=╠═╡
let
	animation = @animate for i in 1:10
		
		trace = simulate_sequence(m, 120, s0, shielded_random)
	
		plot_sequence(trace..., title="Shielded Trace", legend=:topleft)
	end
	gif(animation, fps=1, show_msg=false)
end
  ╠═╡ =#

# ╔═╡ baa9e7b6-9e93-4fe2-bf53-4c37803f3820
#=╠═╡
simulate_sequence(m, 120, s0, shielded_random)
  ╠═╡ =#

# ╔═╡ c971bbe4-bc6b-49dd-940d-3277017e99bc
function evaluate(m::CCMechanics, policy; 
		episode_length=120, 
		traces=1000, 
		is_safe=is_safe,
		s0=s0)
	
	example_of_unsafe_trace = nothing
	trace = nothing
	safety_violations = 0
	for i in 1:traces
		trace = simulate_sequence(m, episode_length, s0, policy)
		sequence, times = trace
		if any(!is_safe(s) for s in sequence)
			example_of_unsafe_trace = trace
			safety_violations += 1
		end
	end
	example_trace = something(example_of_unsafe_trace, trace)
	return (;traces, safety_violations, example_trace)
end

# ╔═╡ 93741008-85f5-479c-908e-27a3716ef25f
#=╠═╡
traces, safety_violations, example_trace = evaluate(m, shielded_random)
  ╠═╡ =#

# ╔═╡ db29fb3a-0e95-44f6-b324-5238ac02427c
#=╠═╡
plot_sequence(example_trace..., title="Example Trace", legend=:topleft)
  ╠═╡ =#

# ╔═╡ b4eea529-3c88-4e9d-b1b1-99fe2f9c4f94
#=╠═╡
let
	if safety_violations > 0 
		first_unsafe = nothing
		states, times = example_trace
		for (i, s) in enumerate(states)
			if !is_safe(s, m=m)
				first_unsafe = i
				break
			end
		end
	
		if first_unsafe == 1
			Markdown.parse("""
			!!! danger "Initial state unsafe"
				Initial state: $(states[first_unsafe])
			""")
		else
			Markdown.parse("""
			!!! danger "Unsafe trace found"
				Shielded random agent was found to be unsafe.
		
				Out of $traces traces, $safety_violations were found to be unsafe.
		
				First unsafe sate reached: 
				
					$(states[first_unsafe]) at index $first_unsafe, time  $(times[first_unsafe])
				
				The state before that: 
				
					$(states[first_unsafe - 1])
			""")
		end
	else
		Markdown.parse("""
		!!! success "✅ All traces safe"
			$safety_violations out of the $traces traces were unsafe.
		""")
	end
end
  ╠═╡ =#

# ╔═╡ 6134ef59-6377-466b-952d-bee90e421b80
# s0′ = π(s0)
s0′ = (0, 0, m′.distance_min + 5*m′.t_act*m′.acceleration)

# ╔═╡ 38d987a3-eeb8-45fc-a86f-53e5337663c2
begin
	# Projection of the state space of the modified mechanics
	# to that of the original mechanics
	function π(s)
		v_ego, v_front, distance = s
		return (v_ego/t_act_multiplier/acceleration_multiplier - velocity_add,
				v_front/t_act_multiplier/acceleration_multiplier - velocity_add,
				distance/t_act_multiplier/acceleration_multiplier - distance_add)
	end

	# Inverse of the projection
	function π⁻¹(s)
		v_ego, v_front, distance = s
		return ((v_ego + velocity_add)*t_act_multiplier*acceleration_multiplier,
				(v_front + velocity_add)*t_act_multiplier*acceleration_multiplier,
				(distance + distance_add)*t_act_multiplier*acceleration_multiplier)
	end

	let s = (-10, 10, 10)
		@assert all(s .≈ π⁻¹(π(s))) "$s ≈ $(π⁻¹(π(s)))"
	end
end

# ╔═╡ 7854e7a3-0749-45b9-85b9-ab43bcca10d1
π⁻¹((m.v_ego_min, m.v_front_min, m.distance_min))

# ╔═╡ 223fc1d3-6b1c-4807-bc74-7bf4a63ed859
π((m′.v_ego_max, m′.v_front_max, m′.distance_max))

# ╔═╡ 765a72ed-79af-4745-a26b-e2ff85992913
π((10, 10, 10))

# ╔═╡ 9d64b733-6a09-4997-b363-04281f52fb26
#=╠═╡
shielded_random′ = s -> shielded_random(π(s))
  ╠═╡ =#

# ╔═╡ aea60129-59db-4597-9bb5-715b83560dd0
#=╠═╡
# Should be safety violations here :-)
traces′, safety_violations′, example_trace′ = 
	evaluate(m′, shielded_random′, is_safe=s -> is_safe(s, m=m′), s0=s0′)
  ╠═╡ =#

# ╔═╡ 71155dd3-0abc-4119-9e31-885663a32cec
#=╠═╡
[π(s) for s in example_trace′.states]
  ╠═╡ =#

# ╔═╡ ddd02244-044f-480c-833a-bd895f0adb79
#=╠═╡
# But this should be unsafe.
# Because shielding m′ with the original shield leads to safety violations.
evaluate(m′, shielded_random)
  ╠═╡ =#

# ╔═╡ ed2811a6-c557-4f08-855c-59425a0d5c72
#=╠═╡
max([x[1] for x in example_trace′.states]...)
  ╠═╡ =#

# ╔═╡ 0dd174f4-ca16-4ad3-90e7-783da9f59366
#=╠═╡
plot_sequence(example_trace′..., title="Example Trace", legend=:topleft, is_safe=s -> is_safe(s, m=m′))
  ╠═╡ =#

# ╔═╡ 5aaa1518-652c-4980-9899-0d7ae60008ea
#=╠═╡
let
	if safety_violations′ > 0 
		first_unsafe = nothing
		states, times = example_trace′
		for (i, s) in enumerate(states)
			if !is_safe(s, m=m′)
				first_unsafe = i
				break
			end
		end
	
		if first_unsafe == 1
			Markdown.parse("""
			!!! danger "Initial state unsafe"
				Initial state: $(states[first_unsafe])
			""")
		else
			Markdown.parse("""
			!!! danger "Unsafe trace found"
				Shielded random agent was found to be unsafe.
		
				Out of $traces′ traces, $safety_violations′ were found to be unsafe.
		
				First unsafe sate reached: 
				
					$(states[first_unsafe]) at index $first_unsafe, time  $(times[first_unsafe])
				
				The state before that: 
				
					$(states[first_unsafe - 1])
			""")
		end
	else
		Markdown.parse("""
		!!! success "✅ All traces safe"
			$safety_violations′ out of the $traces′ traces were unsafe.
		""")
	end
end
  ╠═╡ =#

# ╔═╡ 82c1573c-1b09-4f22-b125-4a0d3b7c9b13
π((-4.0, -5.0, 9.75))

# ╔═╡ f1347d14-e9c8-469e-bc93-7d10724bb49b
#=╠═╡
@bind trace_index NumberField(1:length(example_trace′.states))
  ╠═╡ =#

# ╔═╡ 1537138d-1e9a-4c2e-a1ce-0e3b696d5c8d
#=╠═╡
md"""

`v_ego =` $(@bind v_ego NumberField(m.v_ego_min:2:m.v_ego_max))

`v_front =` $(@bind v_front NumberField(m.v_front_min:2:m.v_front_max))

`distance =` $(@bind distance NumberField(m.distance_min:1:m.distance_max + 1))
"""
  ╠═╡ =#

# ╔═╡ e400c9d4-4132-431c-aa99-b551b09fbccd
#=╠═╡
SupportingPoints(model.samples_per_axis, box(shield, v_ego, v_front, distance)) |> collect
  ╠═╡ =#

# ╔═╡ b7d66268-8a40-499d-aaca-d6e59f0ee14f
#=╠═╡
partition = box(shield, v_ego, v_front, distance)
  ╠═╡ =#

# ╔═╡ 0018900a-03ed-437f-a4ce-b1e967269ac3
#=╠═╡
get_value(partition)
  ╠═╡ =#

# ╔═╡ 99aabe32-7c65-4a9d-9397-ba2db2ca5cab
#=╠═╡
@bind action Select([backwards, neutral, forwards])
  ╠═╡ =#

# ╔═╡ 5b3b198d-f0df-4991-8eb7-f208418b0be0
#=╠═╡
possible_outcomes(model, partition, action)
  ╠═╡ =#

# ╔═╡ fa369c7d-ba1b-4aa0-bd83-2e2d4b8486f4
#=╠═╡
@bind show_point CheckBox(default=true)
  ╠═╡ =#

# ╔═╡ ac4c993e-0f18-4829-8dd1-450b79c399b8
#=╠═╡
s_t = example_trace′.states[trace_index]
  ╠═╡ =#

# ╔═╡ 628d471f-ccd7-464d-a7b1-7174712d6b86
#=╠═╡
[simulate_point(m′, s_t, r, a) 
	for a in instances(CCAction)
	for r in 0:0.5:1]
  ╠═╡ =#

# ╔═╡ c5de5e40-571d-4385-86ac-3f30f9aa6566
#=╠═╡
example_trace′.times[trace_index]
  ╠═╡ =#

# ╔═╡ 28f000ec-9538-4c9c-afbc-ece4af32d3af
#=╠═╡
	let
	partition = box(shield, π(s_t))
	slice = [partition.indices[1], :, :]
	draw′(shield, π(s_t)...)
	plot!(margin=3mm)
	
	if show_point
		draw_barbaric_transition!(model, partition, action, slice)
	else
		plot!()
	end
end
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═c1bdc9f0-3d96-11ee-00af-b341a715281c
# ╠═57fe6e2d-92d0-4891-a1fa-a9fb0b29f81d
# ╟─da8a843d-b5c7-4155-b90c-3df160996c13
# ╠═af869f6a-d132-4c75-b0b4-440f76352c70
# ╠═75dbc088-74a1-4a7a-ae59-f2163b99b6f1
# ╠═ea83ab65-934a-4734-b562-f9f5223fb34f
# ╟─1e159603-fc61-45f8-9595-f75e55318344
# ╟─5f3af2ba-af4e-4591-bc56-dbebfcb06de5
# ╠═f7233b81-e182-4b23-aa31-409ee53daf77
# ╠═7ba18477-7d3a-4004-b422-46e7c850fc23
# ╠═7dd403fc-878d-45d3-9976-655f10dfd8bc
# ╠═0fedc544-3a81-45b3-b8b0-94c86d291f1b
# ╠═f8a8834e-b8fe-4dc8-8528-4b72148fda6f
# ╠═0fba5442-bba5-4a82-9821-77068368227e
# ╠═1431a6cc-1a91-4357-b624-8ed77311a426
# ╠═d5a28ba8-70fe-4fb2-a9b6-a151ec52fd8b
# ╠═62e0bad2-9a11-473a-a36f-5ab977df2c44
# ╟─5db3cdc1-c8ec-4053-a058-b1ed03d2b95e
# ╟─4c0f483c-147a-4325-b907-16d914e9205e
# ╠═7c436a91-c2a2-49d1-94c9-828b53b7a901
# ╟─9fb76adf-fdbd-46df-8ae9-073cacf0fb58
# ╠═07645bb8-9f8d-4b0e-90ec-34466a966786
# ╠═05305c4a-a1e6-40b4-bb94-e15e77929ef3
# ╟─c3558255-b235-4638-96a5-b40501b14b73
# ╠═06cb86de-b11b-421e-85ef-7002ecff1cf5
# ╟─de31fa0c-acc3-42c4-bac2-e9c2ef4065f6
# ╠═f25d9d2d-baae-422a-a56f-9a7491198f00
# ╠═a96b2790-b7ee-4ac0-8ea3-19094eeb962b
# ╠═25e8dc25-5570-4b39-b353-2df981cc8c9a
# ╠═e400c9d4-4132-431c-aa99-b551b09fbccd
# ╠═bd4395db-3c26-4235-9a42-fa6a7eca7041
# ╟─2418bf90-b0ec-4cb9-b3fd-bf2b91d2ff33
# ╠═b7d66268-8a40-499d-aaca-d6e59f0ee14f
# ╠═0018900a-03ed-437f-a4ce-b1e967269ac3
# ╠═5b3b198d-f0df-4991-8eb7-f208418b0be0
# ╟─0382588a-ac96-4528-9fee-67ab93d4a1f8
# ╠═baa9e7b6-9e93-4fe2-bf53-4c37803f3820
# ╠═107b960f-1a75-41f9-9cb9-195877ad6184
# ╠═c971bbe4-bc6b-49dd-940d-3277017e99bc
# ╠═93741008-85f5-479c-908e-27a3716ef25f
# ╠═db29fb3a-0e95-44f6-b324-5238ac02427c
# ╟─b4eea529-3c88-4e9d-b1b1-99fe2f9c4f94
# ╟─fb88f6f9-cfba-4ccd-ba56-9e84a56ce63c
# ╠═0518e3ff-8c3f-49b4-92ba-871b22c7adc7
# ╟─6ed54088-757e-4906-ab95-769563050ef9
# ╠═9dc03739-4704-4710-b6f5-7fab0e33a6f2
# ╠═3af3824c-c032-46b6-b6ae-db9f01691183
# ╠═de7136f9-32ed-4042-b649-1bdfb9624685
# ╠═b96b370d-adef-485d-9efd-2d15148be70d
# ╠═18b71e15-9485-4019-9c4b-b400b7e823d6
# ╠═877bcf32-eed1-42ef-80b5-87c13cbf6ea3
# ╠═4c6fac5d-86b9-47d0-a654-77e3adc679f4
# ╠═a9b3ccc3-58f6-4b65-9923-b4c213df6752
# ╠═fb24a4e7-7754-4a35-bbfe-99dcf59ba50b
# ╠═6134ef59-6377-466b-952d-bee90e421b80
# ╠═38d987a3-eeb8-45fc-a86f-53e5337663c2
# ╠═7854e7a3-0749-45b9-85b9-ab43bcca10d1
# ╠═223fc1d3-6b1c-4807-bc74-7bf4a63ed859
# ╠═765a72ed-79af-4745-a26b-e2ff85992913
# ╠═9d64b733-6a09-4997-b363-04281f52fb26
# ╠═aea60129-59db-4597-9bb5-715b83560dd0
# ╠═71155dd3-0abc-4119-9e31-885663a32cec
# ╠═ddd02244-044f-480c-833a-bd895f0adb79
# ╠═ed2811a6-c557-4f08-855c-59425a0d5c72
# ╠═0dd174f4-ca16-4ad3-90e7-783da9f59366
# ╟─5aaa1518-652c-4980-9899-0d7ae60008ea
# ╠═82c1573c-1b09-4f22-b125-4a0d3b7c9b13
# ╠═f1347d14-e9c8-469e-bc93-7d10724bb49b
# ╟─1537138d-1e9a-4c2e-a1ce-0e3b696d5c8d
# ╠═99aabe32-7c65-4a9d-9397-ba2db2ca5cab
# ╠═628d471f-ccd7-464d-a7b1-7174712d6b86
# ╠═fa369c7d-ba1b-4aa0-bd83-2e2d4b8486f4
# ╠═ac4c993e-0f18-4829-8dd1-450b79c399b8
# ╠═c5de5e40-571d-4385-86ac-3f30f9aa6566
# ╠═28f000ec-9538-4c9c-afbc-ece4af32d3af
