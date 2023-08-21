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
	Pkg.activate(".")
	using Plots
	using PlutoUI
	using GridShielding
	using StatsBase
	using Unzip
	using Distributions
	using Combinatorics
end

# ╔═╡ 21b97e3c-e969-49ed-a4ab-3231893e96f9
Pkg.add("Combinatorics")

# ╔═╡ 1e159603-fc61-45f8-9595-f75e55318344
md"""
# Safety strategy for Cruise Control
"""

# ╔═╡ 3a57c06f-0adb-4f92-9f64-f22edbefcadf
TableOfContents()

# ╔═╡ 5f3af2ba-af4e-4591-bc56-dbebfcb06de5
md"""
## Mechanics

The mechanics which describe the cruise control system
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
	ego_sensor_range::Number # front is invisible after this
	v_ego_min::Number
	v_ego_max::Number
	v_front_min::Number
	v_front_max::Number
end

# ╔═╡ 0fedc544-3a81-45b3-b8b0-94c86d291f1b
m = CCMechanics(1, 200, 0, 20, 2, 18)

# ╔═╡ f8a8834e-b8fe-4dc8-8528-4b72148fda6f
function random_front_behaviour(mechanics::CCMechanics, point, random_variable)
    v_ego, v_front, distance = point
    # Check if inside sensor range.
    if distance <= mechanics.ego_sensor_range
        if random_variable[1] < 1/3
			return backwards
		elseif random_variable[1] < 2/3
			return neutral
		else
			return forwards
		end
    else
        if random_variable[1] < 0.5 && v_ego > mechanics.v_front_min
			lower = m.v_front_min - 1
			upper = v_ego - 1

			# I know.
			return round(lower + (upper - lower)*((random_variable[1])*2))
        else
            # Stays outside range
            return mechanics.v_front_max 
        end
    end
end

# ╔═╡ f30f1c2f-14a9-4f47-8abe-7d6a73017e3e
[random_front_behaviour(m, (4, 0, 201), rand(Uniform(0, 1))) for _ in 1:100] |> unique |> sort

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
function apply_action(velocity, action::CCAction)
	if action == backwards
		return velocity - 2
	elseif action == neutral
		return velocity
	else
		return velocity + 2
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
	    
	    # Update v_front. 
	    # Front behaviour varies depending on whether it is inside sensor range.
	    if distance <= mechanics.ego_sensor_range
	
	        front_action′ = speed_limit(mechanics.v_front_min, 
	            mechanics.v_front_max, 
	            v_front,
	            front_action)
	        
	        v_front = apply_action(v_front, front_action′)
	    else 
	        # front can choose to come back into sensor range 
	        # at a velocity less than the ego
	        if front_action < v_ego
	
	            # Just for good measure
	            v_front = clamp(front_action,
	                mechanics.v_front_min - 1, mechanics.v_front_max + 1)
	
	            # Need to update old_vel. 
	            # This update happens before the call to updateDiscrete() 
	            # in the UPPAAL model.
	            old_vel = v_front - v_ego;
	            distance = 200
	        else
	            v_front = mechanics.v_front_max
	        end
	    end
	
	    action′ = speed_limit(mechanics.v_ego_min, 
	        mechanics.v_ego_max, 
	        v_ego,
	        action)
	    
	    v_ego = apply_action(v_ego, action′)
	
	    new_vel = v_front - v_ego;
	
	    distance += (old_vel + new_vel)/2;
	    distance = clamp(distance, -1., mechanics.ego_sensor_range + 1.)
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

# ╔═╡ 5db3cdc1-c8ec-4053-a058-b1ed03d2b95e
function plot_sequence(states, times; dim=1, plotargs...)
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
		if d <= 0
			push!(unsafe_ts, t)
			push!(unsafe_ds, d)
		end
	end
	if length(unsafe_ts) > 0
		scatter!(unsafe_ts, unsafe_ds, label="safety violation", marker=:ltriangle, ms=10)
	end
	
	plot(p1, p2, layout=layout, size=(800, 400))
end

# ╔═╡ 00b22e0a-7809-4a1e-9997-71e7135d825c
let
	animation = @animate for i in 1:10
		trace = simulate_sequence(m, 120, (0, 0, 50), (_...) -> rand([backwards neutral forwards]))
	
		plot_sequence(trace..., title="Random Trace", legend=:topleft)
	end
	gif(animation, fps=1, show_msg=false)
end

# ╔═╡ 4c0f483c-147a-4325-b907-16d914e9205e
md"""
## Shielding

Code to generate the actual shield
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

# ╔═╡ e49c01cf-93da-4893-9fdb-4ccb69b80a0b
int_to_actions(CCAction, 5)

# ╔═╡ 7b4fcf6a-ebef-419a-8fda-665feac45885
let
	foof = sort([(actions_to_int(i), i) for i in powerset(instances(CCAction))])
	@info join(["const int $(join([string(z) for z in y], "_")) = $x;"
		for (x, y) in foof
	], "\n")
end

# ╔═╡ f00d17b3-12ef-4248-ae19-ae8b952c51e1
md"""
### Simulation function

The function for taking a single step needs to be wrapped up, so that it only takes the arguments `point`, `action` and `random_outcomes`.
"""

# ╔═╡ d42f6a70-d65f-4e68-8481-d51a3c1ab8fb
simulation_function(p, a, r) = 
	simulate_point(m, p, r, a)

# ╔═╡ 32d19beb-b4cb-4767-a094-22d7952d9be8
md"""
### Safety Property
The cars should not crash, so the distance between cars should always be greater than zero.
"""

# ╔═╡ 07645bb8-9f8d-4b0e-90ec-34466a966786
begin
	is_safe(point) = m.ego_sensor_range > point[3] > 0
	is_safe(bounds::Bounds) = is_safe((nothing, nothing, bounds.lower[3]))
end

# ╔═╡ 270796fb-2c5b-4fb1-b27c-58d354c87e36
md"""
### Grid
The grid is defined by the upper and lower bounds on the state space, and some `granularity` which determines the size of the partitions.

`granularity_v_ego =` $(@bind granularity_v_ego NumberField(0.001:0.001:1, default=1))

`granularity_v_front =` $(@bind granularity_v_front NumberField(0.001:0.001:1, default=1))

`granularity_distance =` $(@bind granularity_distance NumberField(0.001:0.001:1, default=1))
"""

# ╔═╡ 82cb8845-5eb9-4dac-bab2-47a5e9761bee
begin
	granularity = [granularity_v_ego, granularity_v_front, granularity_distance]

	grid = Grid(granularity, 
		(m.v_ego_min, m.v_front_min - 1, -1 ),
		(m.v_ego_max + 1 + granularity_v_ego,
			m.v_front_max + 1 + granularity_v_front,
			m.ego_sensor_range + 1 + granularity_distance ))

	initialize!(grid, x -> is_safe(x) ? any_action : no_action)

	grid
end

# ╔═╡ e3d5c8b9-0e93-42b1-ad7b-e66e61ff842a
md"""
### Drawing the grid
"""

# ╔═╡ b3e8b012-57c0-48f1-86a8-cd06b8971d46
md"""
### Simulation Model

All of this is wrapped up in the following model `struct` just to make the call signatures shorter. 

`samples_per_axis =` $(@bind samples_per_axis NumberField(1:10, default=2))
"""

# ╔═╡ b4a84cfd-13a3-4c00-81e2-b28d288b23d2
md"""
### Front behaviour

The random behaviour of the front car is based on a number between 0 and 1, which is interpreted in different ways depending on the state. (Wheter it is inside sensor range or not.)
"""

# ╔═╡ c4cbe6e7-3497-4b84-b66a-947fa85b0ee2
randomness_space = Bounds((0,), (1,))

# ╔═╡ bc6d7025-7567-4a7d-b3d3-70161f65c3f4
model = SimulationModel(simulation_function, randomness_space, samples_per_axis)

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

# ╔═╡ dfc8cb50-b08f-4006-8e6f-de058ee0bf98
if make_shield_button > 0
	reachability_function_precomputed = 
		get_transitions(reachability_function, CCAction, grid)
end

# ╔═╡ 0f5ee444-afe5-4314-ab8e-a7dfff02964d
begin
	shield, max_steps_reached = grid, false
	
	if make_shield_button > 0

		# here is the computation
		shield, max_steps_reached = 
			make_shield(reachability_function_precomputed, CCAction, grid; max_steps)
		
	end
end

# ╔═╡ 85e07e50-a0fc-42bb-813c-8d0ab6af2b4c
if max_steps_reached
	Markdown.parse("""
	!!! warn "Max steps reached"
		The method reached a maximum iteration steps of $max_steps before a fixed point was reached. The strategy is only safe for a finite horizon of $max_steps steps.""")
end

# ╔═╡ 1537138d-1e9a-4c2e-a1ce-0e3b696d5c8d
md"""

`v_ego =` $(@bind v_ego NumberField(m.v_ego_min:2:m.v_ego_max))

`v_front =` $(@bind v_front NumberField(m.v_front_min:2:m.v_front_max))

`distance =` $(@bind distance NumberField(0:2:m.ego_sensor_range + 1))
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

# ╔═╡ c403ff95-26db-4d72-87a2-a00d4ea3a77e
SupportingPoints(model.samples_per_axis, box(grid, v_ego, v_front, distance)) |> collect

# ╔═╡ 99aabe32-7c65-4a9d-9397-ba2db2ca5cab
@bind action Select([backwards, neutral, forwards])

# ╔═╡ b7d66268-8a40-499d-aaca-d6e59f0ee14f
partition = box(grid, v_ego, v_front, distance)

# ╔═╡ 5b3b198d-f0df-4991-8eb7-f208418b0be0
possible_outcomes(model, partition, action)

# ╔═╡ 28f000ec-9538-4c9c-afbc-ece4af32d3af
let
	draw′(shield)
	slice = [box(grid, v_ego, v_front, distance).indices[1], :, :]
	draw_barbaric_transition!(model, partition, action, slice)
end

# ╔═╡ 048a5418-1f52-429a-b291-0907f17955bd
get_value(box(shield, v_ego, v_front, distance))

# ╔═╡ fff19afb-c91b-4c74-9ca7-50f5fcb86c2e
int_to_actions(CCAction, get_value(box(shield, v_ego, v_front, distance)))

# ╔═╡ da36d839-6bb1-4805-b780-2b44f5af44f9
unique(shield.array)

# ╔═╡ 10d8e4b6-d7ea-4bdf-95a4-22a520a7c918
shield

# ╔═╡ 1dcf9abe-0063-4225-ada2-2d66e3155eef


# ╔═╡ 0382588a-ac96-4528-9fee-67ab93d4a1f8
if make_shield_button > 0 let
	animation = @animate for i in 1:10
		shielded_random = s -> begin
			if s ∈ shield
				partition = box(shield, s)
				allowed = int_to_actions(CCAction, get_value(partition))
				if allowed == []
					@warn "unsaef" s
					return rand(instances(CCAction))
				end
				return rand(allowed)
			else
				 @warn "out of bounds" s
				return rand(instances(CCAction))
			end
		end
		
		trace = simulate_sequence(m, 120, (0, 2, 180), shielded_random)
	
		plot_sequence(trace..., title="Shielded Trace", legend=:topleft)
	end
	gif(animation, fps=1, show_msg=false)
end end

# ╔═╡ ce847193-9e56-4dd2-9f54-d9879c88802c


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
# ╠═3a57c06f-0adb-4f92-9f64-f22edbefcadf
# ╠═21b97e3c-e969-49ed-a4ab-3231893e96f9
# ╟─5f3af2ba-af4e-4591-bc56-dbebfcb06de5
# ╠═f7233b81-e182-4b23-aa31-409ee53daf77
# ╠═7ba18477-7d3a-4004-b422-46e7c850fc23
# ╠═7dd403fc-878d-45d3-9976-655f10dfd8bc
# ╠═0fedc544-3a81-45b3-b8b0-94c86d291f1b
# ╟─f8a8834e-b8fe-4dc8-8528-4b72148fda6f
# ╠═f30f1c2f-14a9-4f47-8abe-7d6a73017e3e
# ╠═0fba5442-bba5-4a82-9821-77068368227e
# ╟─1431a6cc-1a91-4357-b624-8ed77311a426
# ╠═d5a28ba8-70fe-4fb2-a9b6-a151ec52fd8b
# ╟─62e0bad2-9a11-473a-a36f-5ab977df2c44
# ╟─5db3cdc1-c8ec-4053-a058-b1ed03d2b95e
# ╟─00b22e0a-7809-4a1e-9997-71e7135d825c
# ╟─4c0f483c-147a-4325-b907-16d914e9205e
# ╠═7c436a91-c2a2-49d1-94c9-828b53b7a901
# ╠═9fb76adf-fdbd-46df-8ae9-073cacf0fb58
# ╠═e49c01cf-93da-4893-9fdb-4ccb69b80a0b
# ╠═7b4fcf6a-ebef-419a-8fda-665feac45885
# ╟─f00d17b3-12ef-4248-ae19-ae8b952c51e1
# ╠═d42f6a70-d65f-4e68-8481-d51a3c1ab8fb
# ╟─32d19beb-b4cb-4767-a094-22d7952d9be8
# ╠═07645bb8-9f8d-4b0e-90ec-34466a966786
# ╟─270796fb-2c5b-4fb1-b27c-58d354c87e36
# ╠═82cb8845-5eb9-4dac-bab2-47a5e9761bee
# ╟─e3d5c8b9-0e93-42b1-ad7b-e66e61ff842a
# ╟─05305c4a-a1e6-40b4-bb94-e15e77929ef3
# ╟─b3e8b012-57c0-48f1-86a8-cd06b8971d46
# ╟─b4a84cfd-13a3-4c00-81e2-b28d288b23d2
# ╟─c4cbe6e7-3497-4b84-b66a-947fa85b0ee2
# ╠═bc6d7025-7567-4a7d-b3d3-70161f65c3f4
# ╠═c403ff95-26db-4d72-87a2-a00d4ea3a77e
# ╠═4b651d7e-7e05-4cdf-a5d7-734653183e96
# ╟─da8a843d-b5c7-4155-b90c-3df160996c13
# ╟─1f9b85b7-43f8-4cf6-90b1-581694f4a8f2
# ╟─1995a818-3309-458a-b753-0636bc680c27
# ╠═dfc8cb50-b08f-4006-8e6f-de058ee0bf98
# ╠═0f5ee444-afe5-4314-ab8e-a7dfff02964d
# ╟─85e07e50-a0fc-42bb-813c-8d0ab6af2b4c
# ╟─1537138d-1e9a-4c2e-a1ce-0e3b696d5c8d
# ╠═99aabe32-7c65-4a9d-9397-ba2db2ca5cab
# ╠═b7d66268-8a40-499d-aaca-d6e59f0ee14f
# ╠═5b3b198d-f0df-4991-8eb7-f208418b0be0
# ╟─28f000ec-9538-4c9c-afbc-ece4af32d3af
# ╠═048a5418-1f52-429a-b291-0907f17955bd
# ╠═fff19afb-c91b-4c74-9ca7-50f5fcb86c2e
# ╠═da36d839-6bb1-4805-b780-2b44f5af44f9
# ╠═10d8e4b6-d7ea-4bdf-95a4-22a520a7c918
# ╠═1dcf9abe-0063-4225-ada2-2d66e3155eef
# ╠═0382588a-ac96-4528-9fee-67ab93d4a1f8
# ╠═ce847193-9e56-4dd2-9f54-d9879c88802c
# ╠═298dadf8-41a4-443d-90c9-9dba1a87145c
