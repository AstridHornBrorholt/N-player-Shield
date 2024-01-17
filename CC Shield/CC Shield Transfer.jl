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
	using PlutoUI
	using PlutoLinks
	using StatsBase
	using Unzip
	using Distributions
	using Combinatorics
	using Measures
end

# ╔═╡ d2204fe6-a71e-4131-a568-349572ce28d4
begin
	Pkg.develop("GridShielding")
	@revise using GridShielding
end

# ╔═╡ 1e159603-fc61-45f8-9595-f75e55318344
md"""
# Default Mechanics the Shield was Created With

So the idea is to take a shield generated for one set of mechanics, and shield a different system with it, by way of a projection of the state space. Or something; I am not so much words today.

First there is this whole preamble which is just copy-paste d from an earlier motebook better explained there
"""

# ╔═╡ 3a57c06f-0adb-4f92-9f64-f22edbefcadf
TableOfContents()

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
	v_ego_min::Number
	v_ego_max::Number
	v_front_min::Number
	v_front_max::Number
end

# ╔═╡ 0fedc544-3a81-45b3-b8b0-94c86d291f1b
# Default Mechanics
m = CCMechanics(1, 0, 200, -10, 20, -10, 20)

# ╔═╡ 6134ef59-6377-466b-952d-bee90e421b80
s0 = (0, 0, 50)

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
function speed_limit(min, max, v, action::CCAction)
	if action == backwards && v <= min
		return neutral
	elseif action == forwards && v >= max
		return neutral
	else
		return action
	end
end

# ╔═╡ 1431a6cc-1a91-4357-b624-8ed77311a426
function apply_action(velocity, action::CCAction, acceleration=2)
	if action == backwards
		return velocity - acceleration
	elseif action == neutral
		return velocity
	else
		return velocity + acceleration
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

# ╔═╡ c3558255-b235-4638-96a5-b40501b14b73
md"""
### Simulation Model

Simulation model for default mechanics. Used for reachability approximation.

`spa_v_ego =` $(@bind spa_v_ego NumberField(1:10, default=1))

`spa_v_front =` $(@bind spa_v_front NumberField(1:10, default=1))

`spa_distance =` $(@bind spa_distance NumberField(1:10, default=3))

`samples_per_random_axis =` $(@bind samples_per_random_axis NumberField(1:10, default=3))
"""

# ╔═╡ 06cb86de-b11b-421e-85ef-7002ecff1cf5
samples_per_axis = (spa_v_ego, spa_v_front, spa_distance)

# ╔═╡ de31fa0c-acc3-42c4-bac2-e9c2ef4065f6
md"""
Randomness space: The random behaviour of the front car is based on a number between 0 and 1, which is interpreted in different ways depending on the state. (Wheter it is inside sensor range or not.)
"""

# ╔═╡ f25d9d2d-baae-422a-a56f-9a7491198f00
randomness_space = Bounds((0,), (1,))

# ╔═╡ 25e8dc25-5570-4b39-b353-2df981cc8c9a
model = SimulationModel(simulation_function, randomness_space, samples_per_axis, samples_per_random_axis)

# ╔═╡ bd4395db-3c26-4235-9a42-fa6a7eca7041
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ da8a843d-b5c7-4155-b90c-3df160996c13
md"""
## Import a shield
"""

# ╔═╡ af869f6a-d132-4c75-b0b4-440f76352c70
@bind imported_shield_fp FilePicker()

# ╔═╡ 75dbc088-74a1-4a7a-ae59-f2163b99b6f1
shield = if isnothing(imported_shield_fp)
	nothing
else
	imported_shield_fp["data"] |> IOBuffer |> robust_grid_deserialization
end

# ╔═╡ ea83ab65-934a-4734-b562-f9f5223fb34f
granularity = shield.granularity

# ╔═╡ 2418bf90-b0ec-4cb9-b3fd-bf2b91d2ff33
md"""
### Inspect imported shield
"""

# ╔═╡ 99aabe32-7c65-4a9d-9397-ba2db2ca5cab
@bind action Select([backwards, neutral, forwards])

# ╔═╡ 1537138d-1e9a-4c2e-a1ce-0e3b696d5c8d
md"""

`v_ego =` $(@bind v_ego NumberField(m.v_ego_min:2:m.v_ego_max))

`v_front =` $(@bind v_front NumberField(m.v_front_min:1:m.v_front_max))

`distance =` $(@bind distance NumberField(m.distance_min:granularity[3]:m.distance_max + 1))
"""

# ╔═╡ 05305c4a-a1e6-40b4-bb94-e15e77929ef3
begin
	function draw′(grid)
		draw′(grid, v_ego, v_front, distance)
	end
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

# ╔═╡ e400c9d4-4132-431c-aa99-b551b09fbccd
SupportingPoints(model.samples_per_axis, box(shield, v_ego, v_front, distance)) |> collect

# ╔═╡ b7d66268-8a40-499d-aaca-d6e59f0ee14f
partition = box(shield, v_ego, v_front, distance)

# ╔═╡ 0018900a-03ed-437f-a4ce-b1e967269ac3
get_value(partition)

# ╔═╡ 5b3b198d-f0df-4991-8eb7-f208418b0be0
possible_outcomes(model, partition, action)

# ╔═╡ fa369c7d-ba1b-4aa0-bd83-2e2d4b8486f4
@bind show_point CheckBox(default=true)

# ╔═╡ 28f000ec-9538-4c9c-afbc-ece4af32d3af
let
	draw′(shield)
	plot!(margin=3mm)
	slice = [box(shield, v_ego, v_front, distance).indices[1], :, :]
	if show_point
		draw_barbaric_transition!(model, partition, action, slice)
	else
		plot!()
	end
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
let
	animation = @animate for i in 1:10
		
		trace = simulate_sequence(m, 120, s0, shielded_random)
	
		plot_sequence(trace..., title="Shielded Trace", legend=:topleft)
	end
	gif(animation, fps=1, show_msg=false)
end

# ╔═╡ c971bbe4-bc6b-49dd-940d-3277017e99bc
function evaluate(m::CCMechanics, policy; episode_length=120, traces=1000, is_safe=is_safe)
	example_of_unsafe_trace = nothing
	safety_violations = 0
	for i in 1:traces
		trace = simulate_sequence(m, episode_length, s0, policy)
		sequence, times = trace
		if any(!is_safe(s) for s in sequence)
			example_of_unsafe_trace = trace
			safety_violations += 1
		end
	end
	return (;traces, safety_violations, example_of_unsafe_trace)
end

# ╔═╡ 93741008-85f5-479c-908e-27a3716ef25f
traces, safety_violations, example_of_unsafe_trace = evaluate(m, shielded_random)

# ╔═╡ db29fb3a-0e95-44f6-b324-5238ac02427c
if !isnothing(example_of_unsafe_trace)
	plot_sequence(example_of_unsafe_trace..., title="Example of Unsafe Trace", legend=:topleft)
end

# ╔═╡ b4eea529-3c88-4e9d-b1b1-99fe2f9c4f94
if safety_violations > 0 let
	first_unsafe = nothing
	states, times = example_of_unsafe_trace
	for (i, s) in enumerate(states)
		if !is_safe(s)
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
			
				$(states[first_unsafe])
			
			The state before that: 
			
				$(states[first_unsafe - 1])
		""")
	end
end end

# ╔═╡ fb88f6f9-cfba-4ccd-ba56-9e84a56ce63c
md"""
# Modifiying the mechanics

The new mechanics are like this
"""

# ╔═╡ 3af3824c-c032-46b6-b6ae-db9f01691183
m′ = CCMechanics(1, 0, 200, 0, 30, 0, 30)

# ╔═╡ 2b1c93bc-d6f1-4591-8fde-c32a78138325
s0

# ╔═╡ 38d987a3-eeb8-45fc-a86f-53e5337663c2
# Projection of the state space
function π(s)
	v_ego, v_front, distance = s
	return (v_ego - 10, v_front - 10, distance)
end

# ╔═╡ 9d64b733-6a09-4997-b363-04281f52fb26
shielded_random′ = s -> shielded_random(π(s))

# ╔═╡ 38e1e427-6b1f-402c-93d5-8847e2563c32
md"""
## Applying the projection or something
"""

# ╔═╡ aea60129-59db-4597-9bb5-715b83560dd0
# No safety violations here :-)
traces′, safety_violations′, example_of_unsafe_trace′ = 
	evaluate(m′, shielded_random′, is_safe=s -> is_safe(s, m=m′))

# ╔═╡ ddd02244-044f-480c-833a-bd895f0adb79
# Notice how shielding m′ with the shield directly leads to safety violations.
evaluate(m′, shielded_random)

# ╔═╡ 0dd174f4-ca16-4ad3-90e7-783da9f59366
if !isnothing(example_of_unsafe_trace′)
	plot_sequence(example_of_unsafe_trace′..., title="Example of Unsafe Trace", legend=:topleft, is_safe=s -> is_safe(s, m=m′))
end

# ╔═╡ 5aaa1518-652c-4980-9899-0d7ae60008ea
if safety_violations′ > 0 let
	first_unsafe = nothing
	states, times = example_of_unsafe_trace′
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
			
				$(states[first_unsafe])
			
			The state before that: 
			
				$(states[first_unsafe - 1])
		""")
	end
end end

# ╔═╡ Cell order:
# ╟─1e159603-fc61-45f8-9595-f75e55318344
# ╠═c1bdc9f0-3d96-11ee-00af-b341a715281c
# ╠═d2204fe6-a71e-4131-a568-349572ce28d4
# ╠═3a57c06f-0adb-4f92-9f64-f22edbefcadf
# ╟─5f3af2ba-af4e-4591-bc56-dbebfcb06de5
# ╠═f7233b81-e182-4b23-aa31-409ee53daf77
# ╠═7ba18477-7d3a-4004-b422-46e7c850fc23
# ╠═7dd403fc-878d-45d3-9976-655f10dfd8bc
# ╠═0fedc544-3a81-45b3-b8b0-94c86d291f1b
# ╠═6134ef59-6377-466b-952d-bee90e421b80
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
# ╠═25e8dc25-5570-4b39-b353-2df981cc8c9a
# ╠═e400c9d4-4132-431c-aa99-b551b09fbccd
# ╠═bd4395db-3c26-4235-9a42-fa6a7eca7041
# ╟─da8a843d-b5c7-4155-b90c-3df160996c13
# ╠═af869f6a-d132-4c75-b0b4-440f76352c70
# ╠═75dbc088-74a1-4a7a-ae59-f2163b99b6f1
# ╠═ea83ab65-934a-4734-b562-f9f5223fb34f
# ╟─2418bf90-b0ec-4cb9-b3fd-bf2b91d2ff33
# ╠═99aabe32-7c65-4a9d-9397-ba2db2ca5cab
# ╠═b7d66268-8a40-499d-aaca-d6e59f0ee14f
# ╠═0018900a-03ed-437f-a4ce-b1e967269ac3
# ╠═5b3b198d-f0df-4991-8eb7-f208418b0be0
# ╟─1537138d-1e9a-4c2e-a1ce-0e3b696d5c8d
# ╠═fa369c7d-ba1b-4aa0-bd83-2e2d4b8486f4
# ╟─28f000ec-9538-4c9c-afbc-ece4af32d3af
# ╟─0382588a-ac96-4528-9fee-67ab93d4a1f8
# ╠═107b960f-1a75-41f9-9cb9-195877ad6184
# ╠═c971bbe4-bc6b-49dd-940d-3277017e99bc
# ╠═93741008-85f5-479c-908e-27a3716ef25f
# ╟─db29fb3a-0e95-44f6-b324-5238ac02427c
# ╟─b4eea529-3c88-4e9d-b1b1-99fe2f9c4f94
# ╟─fb88f6f9-cfba-4ccd-ba56-9e84a56ce63c
# ╠═3af3824c-c032-46b6-b6ae-db9f01691183
# ╠═2b1c93bc-d6f1-4591-8fde-c32a78138325
# ╠═38d987a3-eeb8-45fc-a86f-53e5337663c2
# ╠═9d64b733-6a09-4997-b363-04281f52fb26
# ╟─38e1e427-6b1f-402c-93d5-8847e2563c32
# ╠═aea60129-59db-4597-9bb5-715b83560dd0
# ╠═ddd02244-044f-480c-833a-bd895f0adb79
# ╠═0dd174f4-ca16-4ad3-90e7-783da9f59366
# ╟─5aaa1518-652c-4980-9899-0d7ae60008ea
