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
	using Parameters
	include("../FlatUI Colors.jl")
end

# ╔═╡ d2204fe6-a71e-4131-a568-349572ce28d4
begin
	Pkg.develop("GridShielding")
	@revise using GridShielding
end

# ╔═╡ 3a57c06f-0adb-4f92-9f64-f22edbefcadf
TableOfContents(title="Chemical Production")

# ╔═╡ 9aead72a-8c20-4565-a4bf-26d72ef832ab
md"""
**Simple Chemical Production Example**

Okay, all that other stuff was too complex. Time to KISS. 

A tank can control pumps attached to **3** ingoing pipes to control its inflow. Likewise, there are **3** outgoing pipes which are uncontrollable. 

The top row of tanks will have unlimited access to material. The bottom row will be supplying material to partially random consumers. 

Maybe some of the pipes will be double-width, and others will be connected to unlimited material. 

![image](https://i.imgur.com/N3SRgfe.png)
"""

# ╔═╡ 1e159603-fc61-45f8-9595-f75e55318344
md"""
# Preamble
"""

# ╔═╡ 2b50bd80-1506-4ad3-abbe-589952fddf3c
← = push!

# ╔═╡ 9be0a063-d016-4081-8c5d-dbff0e31de87
md"""
# Simulating the System
"""

# ╔═╡ fd85cc40-217a-4f76-b979-adacb1e0ea9b
md"""
## Mechanics
"""

# ╔═╡ 69001b1e-5208-430b-a809-800a5df71b03
# Actions

@enum CPAction wait=0 input_one input_two input_three

# ╔═╡ a73bed3f-9e0f-45ad-a32c-935d17a52bb7
begin
	@with_kw struct CPMechanics
		t_act::Float64=0.5
		min_stored::Float64=2.0
		max_stored::Float64=50.0
		flow_rate::Float64=2.65
		flow_rate_variance::Float64=0.5
	end
end

# ╔═╡ e019f426-8a0f-4698-8b6d-ed487a68ae5c
m_defaults = CPMechanics()

# ╔═╡ 240cd0df-8f69-4749-8567-a6b560af4aea
md"""
The space of random outcomes has 3 dimensions:
- The environment action (`wait`, `input_one`, `input_two`)
- Random variance of inflows
- Random variance of outflows.
"""

# ╔═╡ cd9ba9af-db52-485b-af56-d14827926137
randomness_space = Bounds((0, 0, 0), (1, 1, 1))

# ╔═╡ af920ac1-a57a-44fe-8026-f18d527becb3
begin
	struct CPState
		volume::Float64
	end

	function CPState(t::NTuple{6, Float64})
		CPState(t...)
	end

	Base.convert(::Type{CPState}, x::NTuple{6, Float64}) = CPState(x)
	Base.length(::CPState) = 1
	Base.tail(s::CPState) = s.volume
	Base.iterate(s::CPState) = s.volume, :done
	Base.iterate(s::CPState, iter) = nothing # simple case
end

# ╔═╡ 14d4416b-ef73-4777-942e-f621c3ef801d
begin
	function multi_field(names, types, defaults=nothing)

		if defaults == nothing
			defaults = zeros(length(names))
		end
		return PlutoUI.combine() do Field
			fields = []
	
			for (n, t, d) in zip(names, types, defaults)
				field = "`Unsupported type`"
				if t<:Number
					field = md" $n = $(Field(n, NumberField(-10000.:0.0001:10000., default=d)))"
				elseif t == String
					field = md" $n = $(Field(n, TextField(80), default=d))"
				end
				push!(fields, field)
			end
			
			md"$fields"
		end
	end

	function multi_field(typ::Type)
		multi_field(fieldnames(typ), fieldtypes(typ))
	end

	function multi_field(elem)
		defaults = [getfield(elem, f) for f in fieldnames(typeof(elem))]
		names = fieldnames(typeof(elem))
		types = fieldtypes(typeof(elem))
		multi_field(names, types, defaults)
	end
end

# ╔═╡ 39de57fd-ddf5-41f7-9c33-6a0759d0e5a7
@bind m_inputs multi_field(m_defaults)

# ╔═╡ 8b0e8b12-3b16-4d71-9d29-6fb5db82a47a
m = CPMechanics(;m_inputs...)

# ╔═╡ e945773a-6365-4eb0-a384-5fc7c1dfa70e
@assert 3*m.flow_rate > 
	    2*m.flow_rate + 2*m.flow_rate_variance; (
	3*m.flow_rate, 
	2*m.flow_rate + 2*m.flow_rate_variance)

# ╔═╡ 4dadcdaa-4fce-4a14-9dd7-e4baf141bd42
# Index-name pairs. Used for choosing axes to draw the shield.
state_variables = [1 => "volume"]

# ╔═╡ cc75006e-d258-47a4-830f-a00f800b8bf3
middle_volume = m.min_stored + (m.max_stored - m.min_stored)/2

# ╔═╡ 098ca31f-e1e5-4ee4-a42e-7d169915aace
s0 = CPState(middle_volume)

# ╔═╡ f6b985da-e65e-4842-921d-8200ba17c157
[x for x in s0], Base.tail(s0)

# ╔═╡ c3598256-2917-4546-9066-b4d785e2d55f
md"""
## Simulation Function
"""

# ╔═╡ fed037e7-5100-45a4-9031-ef830c61533d
m

# ╔═╡ 84d04b11-efef-4f02-a9b4-0d266430a655
s_unsafe = CPState(m.min_stored)

# ╔═╡ 6ecc0cf7-d7a1-46ef-a840-717fe0784f59
# Only two outgoing pipes
function environment_action(rvar)
	if     (rvar < 1/3)	return wait
	elseif (rvar < 2/3)	return input_one
	else return input_two
	end
end

# ╔═╡ ed8ea3e2-8a9e-4a90-a19e-11134f9fe2ab
function get_flow_rate(m::CPMechanics, r, a::CPAction)
	multiplier = Int(a) # wait = 0, input_one = 1, ...
	return multiplier*m.flow_rate + multiplier*r*m.flow_rate_variance
end

# ╔═╡ 54d35405-0859-4b1f-ba89-9ae9f8660cc3
get_flow_rate(m, 0, input_three), 
get_flow_rate(m, 0.5, input_three), 
get_flow_rate(m, 1, input_three)

# ╔═╡ 7ecdeacb-fccf-4406-98ea-5f8e7a4b3c84
begin
	# rvar = Random VARiable.
	function simulate_point(m::CPMechanics, 
		point::CPState, rvar, action::CPAction)::CPState
		(;volume) = point
	
		volume_in = get_flow_rate(m, rvar[2], action)

		volume_out = get_flow_rate(m, rvar[3], environment_action(rvar[1]))
		
		volume′ = volume + (volume_in - volume_out)*m.t_act
		
		return CPState(volume′)
	end
	
	function simulate_point(m::CPMechanics, point, rvar, action::CPAction)::CPState
		simulate_point(m, CPState(point...), rvar, action)
	end
	
	function simulate_point(m::CPMechanics, point::CPState, action::CPAction)::CPState
		simulate_point(m, point, (rand(0:1/6:1), rand(0:0.1:1), rand(0:0.1:1)), action)
	end
end

# ╔═╡ 88fc5464-030d-4732-b9d1-5b05a93e1df5
md"""
### Simulating Whole Traces
"""

# ╔═╡ 0a5b97c3-b03f-4418-bb36-af0ca6d6471e
struct CPTrace
	states::Vector{CPState}
	times::Vector{Float64}
	actions::Vector{CPAction}
end

# ╔═╡ 58410e5a-0c4a-4afa-b1c0-390b53905fa6
function simulate_sequence(m::CPMechanics, duration, s0, policy)::CPTrace
	states, times, actions = CPState[s0], Float64[0], CPAction[]

	s, t = s0, 0
    while times[end] <= duration - m.t_act
        a = policy(s)
        s = simulate_point(m, s, a)
		t += m.t_act
        push!(states, s)
        push!(times, t)
        push!(actions, a)
    end
    CPTrace(states, times, actions)
end

# ╔═╡ 534ee19b-69ed-4d6d-b80c-ff8b954b6293
random_policy = (_...) -> rand(instances(CPAction))

# ╔═╡ d6016b3e-3d40-4a4c-914f-55a0d5edfa83
trace = simulate_sequence(m, 100, s0, random_policy)

# ╔═╡ 85b4f24c-3567-4b77-ab26-f29de2348181
md"""
## Visualising Traces
"""

# ╔═╡ f6162914-dd94-46e6-868f-478f6280d1cb
function plot_sequence(trace::CPTrace; time=nothing, plotargs...)
	volumes = [s.volume for s in trace.states]

	📈 = plot(trace.times, volumes, 
		legend=:outerright;
		label="volume",
		color=colors.EMERALD, 
		linewidth=2,
		xlabel="time (\$s\$)",
		ylabel="Volume (\$l\$)",
		plotargs...)
	
	hline!([m.min_stored, m.max_stored], color=colors.WET_ASPHALT, label=nothing)
	if !isnothing(time)
		vline!([time], color=colors.WET_ASPHALT, label=nothing)
	end
	plot!()
end

# ╔═╡ fb61867c-89ca-4685-b3da-2ad7eb18267d
plot_sequence(trace)

# ╔═╡ 1260d5e5-1f2b-4578-909e-a5d0a367b126
#gif(@animate(for _ in 1:10 plot_sequence(simulate_sequence(m, 100, s0, random_policy)) end), show_msg=false, fps=1)

# ╔═╡ 4faea1ce-ad42-456a-8f8f-6cf3bc9787ff
md"""
## Try it out!

Interactive control of the simulation.
"""

# ╔═╡ 67893b1c-ad3e-45f3-90a4-c684b29438a1
md"""
Agent action

$(@bind interactive_action Select([instances(CPAction)...]))
"""

# ╔═╡ b35e34d2-6557-4f67-84fe-949f8d8eeed8
md"""
# Shielding the System
"""

# ╔═╡ d4561dbf-40bd-4411-bfda-714554286893
md"""
## Safety Property
No underflow or overflow; in either tank. Additionally, the moving average of input and output should stay within some constraints.
"""

# ╔═╡ 41584071-89c1-45f9-bded-61fbe98a9b78
begin
	function is_safe(s::CPState)
		return (m.min_stored < s.volume < m.max_stored)
	end

	function is_safe(s) return is_safe(CPState(s...)) end
	
	function is_safe(b::Bounds) return is_safe(b.lower) && is_safe(b.upper) end
end

# ╔═╡ 2a89484b-0eb1-4175-89b7-58a1806bda89
md"""
## Building the Grid
"""

# ╔═╡ 557c1aee-1ab6-43f0-9394-4509ff7ecf3f
function get_state_space_bounds(m::CPMechanics)
	Bounds([m.min_stored],[m.max_stored])
end

# ╔═╡ e4e4e610-7fe6-4322-a8fd-b65042bc3838
state_space_bounds = get_state_space_bounds(m)

# ╔═╡ 394f9428-f2d6-46aa-b82e-de3a59dab5ee
function get_bounds(m::CPMechanics, granularity)
	state_space = get_state_space_bounds(m)
	return Bounds(state_space.lower, state_space.upper .+ granularity)
end

# ╔═╡ ed11b92e-283a-454f-9f7c-b75b00dcb921
md"""
### 🛠 `granularity`
`granularity_V =` $(@bind granularity_V NumberField(0.01:0.01:2, default=1))
"""

# ╔═╡ b4382746-4cbc-4b75-979e-a3b52d877489
granularity = [granularity_V]

# ╔═╡ 2a5749b2-0b3d-4e34-9bbe-60ffa6c867ae
grid_bounds = get_bounds(m, granularity)

# ╔═╡ 5abfeedd-3a3c-4a20-9ade-673ac225f2a1
let
	# Stolen from StackOverflow.
	function commas(num::Integer)
	    str = string(num)
	    return replace(str, r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => ",")
	end
	size = get_size(granularity, grid_bounds)
	length = prod(size)
	size = join(size, "×")
	length = commas(length)
	Markdown.parse("""
	!!! info "Resulting grid size"
		**$size = $length**

		Tip: *This cell won't be affected if you disable the cell defining `grid`. Use this cell to estimate memory footprint before allocating. Mind that caching reachability takes up orders of magnitude more space than the grid itself.*
	""")
end

# ╔═╡ c52e7c97-0711-4330-95f1-11ffddbfb8c7
any_action, no_action = actions_to_int(instances(CPAction)), actions_to_int([])

# ╔═╡ 81b3f1a4-ecb9-4684-b1a7-d6eb6c989b75
grid  = let
	grid = Grid(granularity, grid_bounds)
	initialize!(grid, x -> is_safe(x) ? any_action : no_action)
	grid
end

# ╔═╡ 1708aee6-8d26-4d32-ae78-2357fbe2cecf
grid

# ╔═╡ b89e6235-f6d6-4943-a7a3-1992d857be10
GridShielding.box(grid::Grid, s::CPState) = box(grid, s...)

# ╔═╡ 3fac2081-fbc1-4969-b5db-369d6314f073
Tuple(s0) ∈ grid, Tuple(s_unsafe) ∈ grid

# ╔═╡ b9c584c6-9530-4785-970a-85805797b8f3
unique(grid.array)

# ╔═╡ 4f1f36cb-f338-4c00-a576-a9c9eb7ff285
grid.array

# ╔═╡ 32c0ec89-42ea-4e3b-a284-9317c7920165
begin
	ch_color_labels = [("{$(join(actions, ", "))}", actions_to_int(actions)) 
		for actions in powerset(instances(CPAction))]

	sort!(ch_color_labels, by=(x -> x[2]))
	ch_color_labels = [x[1] for x in ch_color_labels]
	
	ch_colors = [colors[1 + i%length(colors)] 
		for (i, _) in enumerate(ch_color_labels)]
	
	replace!(ch_colors, 
		colors.MIDNIGHT_BLUE => colors.TURQUOISE, 
		colors.WET_ASPHALT => colors.POMEGRANATE,
		colors.CLOUDS => colors.ASBESTOS)
	
	ch_colors[1] = colors.MIDNIGHT_BLUE
	ch_colors[end] = colors.CLOUDS
end;

# ╔═╡ 98d6efed-136f-4d2e-b851-0bbb190e7bf9
md"""
## Simulation Model

Amon other things, we get to use the `randomness_space` variable we defined way earlier.
"""

# ╔═╡ d307696e-54e1-497e-aca0-1f0314a1fdcd
function simulation_function(p, a, r)
	clamp!([simulate_point(m, p, r, a)...], state_space_bounds)
end

# ╔═╡ 56f86d5c-02d0-4252-8984-d9fb4baca1ee
md"""
### 🛠 `spa_*`

`spa_V =` $(@bind spa_V NumberField(1:9, default=3))

`spa_random_action =` $(@bind spa_random_action NumberField(1:9, default=3))

The value of `spa_random_action`  was specifically chosen because there are **3** possile actions the adversarial agents can take.

`spa_random_variance =` $(@bind spa_random_variance NumberField(1:9, default=3))
"""

# ╔═╡ 05bcbcc1-aa0e-4949-beb2-ab45f06ce81c
spa_random = (spa_random_action, spa_random_variance, spa_random_variance)

# ╔═╡ 34e7038c-0267-4ea9-a5fd-485d773dbb05
[environment_action(x[1]) 
	for x in SupportingPoints(spa_random, randomness_space)]

# ╔═╡ a2b19e10-e4b1-4476-8544-3ae960ae1a29
[environment_action(x[1]) 
	for x in SupportingPoints(spa_random, randomness_space)]

# ╔═╡ 8d10f70a-9a5d-4c7d-9d09-6f0fa8aee90a
[environment_action(x[1]) 
	for x in SupportingPoints(spa_random, randomness_space)]

# ╔═╡ 429e77b7-73ad-452e-a188-aee86c1cd28f
[x for x in SupportingPoints(spa_random, randomness_space)]

# ╔═╡ a3572115-75ee-42a8-926c-b2099b4f7cc5
samples_per_axis = (spa_V,)

# ╔═╡ 8e2fcfff-a319-4a5a-813b-65bd8072c6dc
model = SimulationModel(
	simulation_function, 
	randomness_space, 
	samples_per_axis, 
	spa_random)

# ╔═╡ fb6af406-731d-40b9-8f3f-47ddb48c1f5d
m, model; @bind reset_button Button("Reset")

# ╔═╡ 22205344-1445-41fb-bab9-3fced063d62b
# Initialize or reset trace. Will be modified using reactivity of Pluto Notebooks.
reset_button; reactive_trace = CPTrace(CPState[], Float64[], CPAction[]);

# ╔═╡ 29654ee9-9e10-4d1b-b4a4-aef6f3d4f33f
reset_button; @bind step_button CounterButton("Step")

# ╔═╡ ebf8f146-1aa5-4525-aba5-47ffefb4dc45
step_button; md"""
Anatagonist actions (randomized each step)

$(@bind rvar1 NumberField(randomness_space.lower[1]:1/4:randomness_space.upper[1], 
	default=rand(randomness_space.lower[1]:0.1:randomness_space.upper[1])))
$(@bind rvar2 NumberField(randomness_space.lower[2]:0.1:randomness_space.upper[2], 
	default=rand(randomness_space.lower[2]:0.1:randomness_space.upper[2])))
$(@bind rvar3 NumberField(randomness_space.lower[3]:0.1:randomness_space.upper[3], 
	default=rand(randomness_space.lower[3]:0.1:randomness_space.upper[3])))
"""

# ╔═╡ 388cace6-e8d3-4fb1-8e86-eeda23b19d2d
let 
	if step_button > 0
		reactive_trace.times ← reactive_trace.times[end] + m.t_act
		reactive_trace.actions ← interactive_action
		s = reactive_trace.states[end]
		s′ = simulate_point(m, s, (rvar1, rvar2, rvar3), interactive_action)
		reactive_trace.states ← s′
	else
		reactive_trace.times ← 0
		reactive_trace.states ← s0
	end
end; "this cell does the reactive computation"

# ╔═╡ 45543b62-c6fb-4797-a336-e3c456b6e0cb
step_button > 0 ? plot_sequence(reactive_trace) : "plot appears here"

# ╔═╡ 20830df6-e46b-44e2-acb2-a2c291f9b14a
if step_button > 0 && !is_safe(reactive_trace.states[end])
	md"""!!! danger "Unsafe state reached" """
else 
	md"""Current state is safe."""
end

# ╔═╡ f1040518-fc20-4310-8d84-440cd28f0beb
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ 5f8e4725-711b-4ee9-834e-47603f26b9eb
md"""
## Time to make the shield!
"""

# ╔═╡ 29275ad2-7509-4cce-b6ee-7ddd8c0c37a2
begin
	grid, m, model # reactivity
	@bind make_shield_button CounterButton("Do it.")
end

# ╔═╡ 789d1abe-abff-478a-aff2-3ebf40119954
md"""
### 🛠 `max_steps`

Try starting at 1 and then stepping through the iterations.

`max_steps=` $(@bind max_steps NumberField(1:1000, default=1000))
"""

# ╔═╡ 7dedba0d-f017-4af3-805f-3fd945abbddb
if make_shield_button > 0
	reachability_function_precomputed = 
		get_transitions(reachability_function, CPAction, grid)
end

# ╔═╡ 939245b5-e393-4b16-b881-b8d5d41b5646
begin
	shield, max_steps_reached = grid, false
	
	if make_shield_button > 0

		# here
		shield, max_steps_reached = 
			make_shield(reachability_function_precomputed, CPAction, grid; max_steps)
		
	end
end

# ╔═╡ 0aee3c2e-44b7-419d-88d3-434d49494835
if max_steps_reached
	Markdown.parse("""
	!!! warning "Max steps reached"
		The method reached a maximum iteration steps of $max_steps before a fixed point was reached. The strategy is only safe for a finite horizon of $max_steps steps.""")
end

# ╔═╡ c9d8a8ea-5ffe-44a6-b8a8-ca955eed3184
md"""
### 🛠 `s`, `a`

`volume =` $(@bind volume NumberField(m.min_stored:granularity_V:m.max_stored - granularity_V, default=s0.volume))

`action =` $(@bind action Select([instances(CPAction)...]))

"""

# ╔═╡ 2060621f-84b6-448a-a857-0d6c556e3f4f
s = CPState(volume)

# ╔═╡ 14643fb4-54b1-4c92-9511-4051b337a258
is_safe(s0), is_safe(s), !is_safe(s_unsafe)

# ╔═╡ cea6063e-277c-40eb-9b36-893a20a7aa28
partition = box(grid, s)

# ╔═╡ e81836f7-ba93-4735-b30a-35b980ef2ab4
bounds = Bounds(partition)

# ╔═╡ 37dcadc9-f699-4913-ae83-585bf9e6f415
is_safe(bounds)

# ╔═╡ 55dc7ecb-af07-4de9-a900-b0b5ce40131e
bounds

# ╔═╡ 814609db-2993-453a-b17a-bfc84da4542a
length(SupportingPoints(model.samples_per_axis, partition) |> collect)*
length(SupportingPoints(model.samples_per_random_axis, model.randomness_space) |> collect)

# ╔═╡ b1c86b79-1a18-4702-8652-427d20460208
partition.indices

# ╔═╡ ca3fe131-a504-48a6-bfa9-77869d76689d
simulate_point(m, s, action)

# ╔═╡ 6f46d18a-9853-466c-a59f-30234ab96a51
[(box(grid, s)).indices for s in possible_outcomes(model, partition, action)]

# ╔═╡ 54f69492-100d-4720-ba0d-bf7962808d35
[s ∈ grid for s in possible_outcomes(model, partition, action)]

# ╔═╡ aab9d926-b488-4e78-8789-d311096ce4f0
[s for s in possible_outcomes(model, partition, action)]

# ╔═╡ 64e93875-0581-457b-b8e8-981aed2797b8
@bind draw_transition CheckBox(default=false)

# ╔═╡ f73b6e42-c024-4018-83b2-2eac30e96fda
let
	# Horrible hack to turn a 1D grid into a 1D grid
	width = 30. # width of squares
	granularity = shield.granularity[1]
	shield_2d = Grid([width, granularity], 
		(0., shield.bounds.lower[1]),
		(width, shield.bounds.upper[1])
	)
	
	for partition in shield
		shield_2d.array[partition.indices[1]] = get_value(partition)
	end

	draw(shield_2d; colors=ch_colors, color_labels=ch_color_labels, 
		#show_grid=true,
		legend=:outerright,
		aspectratio=:equal,
		ylabel="Volume",
		xlim=(0, width),
		xticks=nothing
	)

	if draw_transition
		outcomes = [s for s in possible_outcomes(model, partition, action)]
		outcomes = [s[1] for s in outcomes]
		scatter!(outcomes, [width/2 for _ in outcomes], 
			marker=(3, colors.ASBESTOS),
			markerstrokewidth=0,
			label=nothing)
		
		scatter!([s.volume], [width/2], 
			marker=(:+, 6, colors.WET_ASPHALT),
			markerstrokewidth=4,
			label=nothing)
	else
		plot!()
	end
end

# ╔═╡ 2df83fee-956c-4e01-964c-493b6f5c98d9
shield.array

# ╔═╡ cf64d90e-dd40-4d93-b210-37dd3485c852
get_value(box(shield, s))

# ╔═╡ ce5aad22-f447-4502-af51-84f4d48e9413
int_to_actions(CPAction, get_value(box(shield, s)))

# ╔═╡ 1857b91b-de36-44b9-afeb-5739c19ffea0
make_shield_button; unique(shield.array)

# ╔═╡ cbaf2ad3-9d1b-4a58-9f76-797bca422fe3
function shielded_random(s::CPState)
	if [s...] ∉ grid
		return rand(instances(CPAction))
	end
	partition = box(shield, s)
	allowed = int_to_actions(CPAction, get_value(partition))
	if length(allowed) == 0
		return rand(instances(CPAction))
	end
	rand(allowed)
end

# ╔═╡ b40d36af-9d76-4226-88e1-899167a84179
function evaluate_safety(m::CPMechanics, shield::Grid; checks=1000)
	example_trace = nothing
	safe = 0
	for c in 1:checks
		trace = simulate_sequence(m, 120, s0, shielded_random)
		if all([is_safe(s) for s in trace.states])
			safe += 1
			continue
		end
		example_trace = trace
	end

	return (;safe, checks, example_trace)
end

# ╔═╡ 71cbbe67-1015-4369-90dd-b03dc2d7ca69
(;safe, checks, example_trace) = evaluate_safety(m, shield; checks=10000)

# ╔═╡ 347f06a4-5524-4407-a833-7cae548b6439
if !isnothing(example_trace)
	shielded_trace = example_trace
else
	shielded_trace = simulate_sequence(m, 100, s0, shielded_random)
end

# ╔═╡ 17bbfa1f-cf25-45ca-8a1b-f62b8cae5759
@bind i NumberField(1:length(shielded_trace.states))

# ╔═╡ 3d48fcd3-abd6-48dd-a600-c72221209377
if !isnothing(example_trace)
	plot_sequence(shielded_trace, time=shielded_trace.times[i], title="Unsafe trace")
else
	plot_sequence(shielded_trace, time=shielded_trace.times[i], title="Safe trace")
end

# ╔═╡ a62e8c4b-46f9-4d4d-aac5-9cd839e52765
shielded_trace.states[i], shielded_trace.actions[i], shielded_trace.times[i]

# ╔═╡ cf7aee84-d05f-4786-abe9-970e5b57484f
int_to_actions(CPAction, get_value(box(shield, shielded_trace.states[i])))

# ╔═╡ 95faabfd-14d4-474f-99af-50cf410b5797
shielded_trace.actions[i] ∈ int_to_actions(CPAction, get_value(box(shield, shielded_trace.states[i])))

# ╔═╡ 52c571b4-a6e3-4674-9053-8c02768d91da
possible_i = possible_outcomes(model, 
	box(shield, shielded_trace.states[i]), 
	shielded_trace.actions[i])

# ╔═╡ bf102935-b72a-4bdf-b18b-bd656d956975
min(possible_i...), max(possible_i...)

# ╔═╡ 14ae0be0-1395-44e6-bb2c-39f6318d2f60
if !isnothing(example_trace)
	md"""
	!!! danger "Unsafe trace found"
		:-(
	"""
else
	md"""
	!!! success "👍👍"
		Only safe traces found.
	"""
end

# ╔═╡ 5ff82f30-fabe-4a39-912f-6aadd31228f1
md"""
### Download result
"""

# ╔═╡ 8d0e55c3-ea57-408b-8c9b-d8484226b43d
let
	buffer = IOBuffer()
	robust_grid_serialization(buffer, shield)
	DownloadButton(take!(buffer), "Chemical Production.shield")
end

# ╔═╡ a3ea7ead-3589-405e-94f3-1d523e5e0a6c
let
	libshield_so = get_libshield(shield)
	DownloadButton(libshield_so |> read, "libcpshield.so")
end

# ╔═╡ Cell order:
# ╠═3a57c06f-0adb-4f92-9f64-f22edbefcadf
# ╟─9aead72a-8c20-4565-a4bf-26d72ef832ab
# ╟─1e159603-fc61-45f8-9595-f75e55318344
# ╠═c1bdc9f0-3d96-11ee-00af-b341a715281c
# ╠═d2204fe6-a71e-4131-a568-349572ce28d4
# ╠═2b50bd80-1506-4ad3-abbe-589952fddf3c
# ╟─14d4416b-ef73-4777-942e-f621c3ef801d
# ╠═e019f426-8a0f-4698-8b6d-ed487a68ae5c
# ╟─9be0a063-d016-4081-8c5d-dbff0e31de87
# ╟─fd85cc40-217a-4f76-b979-adacb1e0ea9b
# ╠═69001b1e-5208-430b-a809-800a5df71b03
# ╠═a73bed3f-9e0f-45ad-a32c-935d17a52bb7
# ╟─39de57fd-ddf5-41f7-9c33-6a0759d0e5a7
# ╠═8b0e8b12-3b16-4d71-9d29-6fb5db82a47a
# ╠═e945773a-6365-4eb0-a384-5fc7c1dfa70e
# ╟─240cd0df-8f69-4749-8567-a6b560af4aea
# ╠═cd9ba9af-db52-485b-af56-d14827926137
# ╠═af920ac1-a57a-44fe-8026-f18d527becb3
# ╠═4dadcdaa-4fce-4a14-9dd7-e4baf141bd42
# ╠═f6b985da-e65e-4842-921d-8200ba17c157
# ╠═2060621f-84b6-448a-a857-0d6c556e3f4f
# ╠═cc75006e-d258-47a4-830f-a00f800b8bf3
# ╠═098ca31f-e1e5-4ee4-a42e-7d169915aace
# ╟─c3598256-2917-4546-9066-b4d785e2d55f
# ╠═fed037e7-5100-45a4-9031-ef830c61533d
# ╠═84d04b11-efef-4f02-a9b4-0d266430a655
# ╠═6ecc0cf7-d7a1-46ef-a840-717fe0784f59
# ╠═34e7038c-0267-4ea9-a5fd-485d773dbb05
# ╠═a2b19e10-e4b1-4476-8544-3ae960ae1a29
# ╠═8d10f70a-9a5d-4c7d-9d09-6f0fa8aee90a
# ╠═ed8ea3e2-8a9e-4a90-a19e-11134f9fe2ab
# ╠═54d35405-0859-4b1f-ba89-9ae9f8660cc3
# ╠═7ecdeacb-fccf-4406-98ea-5f8e7a4b3c84
# ╠═ca3fe131-a504-48a6-bfa9-77869d76689d
# ╟─88fc5464-030d-4732-b9d1-5b05a93e1df5
# ╠═0a5b97c3-b03f-4418-bb36-af0ca6d6471e
# ╠═58410e5a-0c4a-4afa-b1c0-390b53905fa6
# ╠═534ee19b-69ed-4d6d-b80c-ff8b954b6293
# ╠═d6016b3e-3d40-4a4c-914f-55a0d5edfa83
# ╟─85b4f24c-3567-4b77-ab26-f29de2348181
# ╟─f6162914-dd94-46e6-868f-478f6280d1cb
# ╟─fb61867c-89ca-4685-b3da-2ad7eb18267d
# ╠═1260d5e5-1f2b-4578-909e-a5d0a367b126
# ╟─4faea1ce-ad42-456a-8f8f-6cf3bc9787ff
# ╟─fb6af406-731d-40b9-8f3f-47ddb48c1f5d
# ╠═22205344-1445-41fb-bab9-3fced063d62b
# ╟─ebf8f146-1aa5-4525-aba5-47ffefb4dc45
# ╟─67893b1c-ad3e-45f3-90a4-c684b29438a1
# ╟─29654ee9-9e10-4d1b-b4a4-aef6f3d4f33f
# ╟─388cace6-e8d3-4fb1-8e86-eeda23b19d2d
# ╟─45543b62-c6fb-4797-a336-e3c456b6e0cb
# ╟─20830df6-e46b-44e2-acb2-a2c291f9b14a
# ╟─b35e34d2-6557-4f67-84fe-949f8d8eeed8
# ╟─d4561dbf-40bd-4411-bfda-714554286893
# ╠═41584071-89c1-45f9-bded-61fbe98a9b78
# ╠═14643fb4-54b1-4c92-9511-4051b337a258
# ╠═37dcadc9-f699-4913-ae83-585bf9e6f415
# ╠═55dc7ecb-af07-4de9-a900-b0b5ce40131e
# ╟─2a89484b-0eb1-4175-89b7-58a1806bda89
# ╠═557c1aee-1ab6-43f0-9394-4509ff7ecf3f
# ╠═e4e4e610-7fe6-4322-a8fd-b65042bc3838
# ╠═394f9428-f2d6-46aa-b82e-de3a59dab5ee
# ╟─ed11b92e-283a-454f-9f7c-b75b00dcb921
# ╠═b4382746-4cbc-4b75-979e-a3b52d877489
# ╠═2a5749b2-0b3d-4e34-9bbe-60ffa6c867ae
# ╟─5abfeedd-3a3c-4a20-9ade-673ac225f2a1
# ╠═c52e7c97-0711-4330-95f1-11ffddbfb8c7
# ╠═81b3f1a4-ecb9-4684-b1a7-d6eb6c989b75
# ╠═1708aee6-8d26-4d32-ae78-2357fbe2cecf
# ╠═b89e6235-f6d6-4943-a7a3-1992d857be10
# ╠═3fac2081-fbc1-4969-b5db-369d6314f073
# ╠═cea6063e-277c-40eb-9b36-893a20a7aa28
# ╠═e81836f7-ba93-4735-b30a-35b980ef2ab4
# ╠═b9c584c6-9530-4785-970a-85805797b8f3
# ╠═4f1f36cb-f338-4c00-a576-a9c9eb7ff285
# ╟─32c0ec89-42ea-4e3b-a284-9317c7920165
# ╟─98d6efed-136f-4d2e-b851-0bbb190e7bf9
# ╠═d307696e-54e1-497e-aca0-1f0314a1fdcd
# ╟─56f86d5c-02d0-4252-8984-d9fb4baca1ee
# ╠═05bcbcc1-aa0e-4949-beb2-ab45f06ce81c
# ╠═429e77b7-73ad-452e-a188-aee86c1cd28f
# ╠═a3572115-75ee-42a8-926c-b2099b4f7cc5
# ╠═8e2fcfff-a319-4a5a-813b-65bd8072c6dc
# ╠═f1040518-fc20-4310-8d84-440cd28f0beb
# ╟─5f8e4725-711b-4ee9-834e-47603f26b9eb
# ╟─29275ad2-7509-4cce-b6ee-7ddd8c0c37a2
# ╟─789d1abe-abff-478a-aff2-3ebf40119954
# ╠═7dedba0d-f017-4af3-805f-3fd945abbddb
# ╠═814609db-2993-453a-b17a-bfc84da4542a
# ╠═b1c86b79-1a18-4702-8652-427d20460208
# ╠═6f46d18a-9853-466c-a59f-30234ab96a51
# ╠═54f69492-100d-4720-ba0d-bf7962808d35
# ╠═aab9d926-b488-4e78-8789-d311096ce4f0
# ╠═939245b5-e393-4b16-b881-b8d5d41b5646
# ╟─0aee3c2e-44b7-419d-88d3-434d49494835
# ╟─c9d8a8ea-5ffe-44a6-b8a8-ca955eed3184
# ╠═64e93875-0581-457b-b8e8-981aed2797b8
# ╟─f73b6e42-c024-4018-83b2-2eac30e96fda
# ╠═2df83fee-956c-4e01-964c-493b6f5c98d9
# ╠═cf64d90e-dd40-4d93-b210-37dd3485c852
# ╠═ce5aad22-f447-4502-af51-84f4d48e9413
# ╠═1857b91b-de36-44b9-afeb-5739c19ffea0
# ╠═cbaf2ad3-9d1b-4a58-9f76-797bca422fe3
# ╠═3d48fcd3-abd6-48dd-a600-c72221209377
# ╠═17bbfa1f-cf25-45ca-8a1b-f62b8cae5759
# ╠═a62e8c4b-46f9-4d4d-aac5-9cd839e52765
# ╠═cf7aee84-d05f-4786-abe9-970e5b57484f
# ╠═95faabfd-14d4-474f-99af-50cf410b5797
# ╠═bf102935-b72a-4bdf-b18b-bd656d956975
# ╠═52c571b4-a6e3-4674-9053-8c02768d91da
# ╠═b40d36af-9d76-4226-88e1-899167a84179
# ╠═71cbbe67-1015-4369-90dd-b03dc2d7ca69
# ╟─347f06a4-5524-4407-a833-7cae548b6439
# ╟─14ae0be0-1395-44e6-bb2c-39f6318d2f60
# ╟─5ff82f30-fabe-4a39-912f-6aadd31228f1
# ╟─8d0e55c3-ea57-408b-8c9b-d8484226b43d
# ╟─a3ea7ead-3589-405e-94f3-1d523e5e0a6c
