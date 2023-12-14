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

# ╔═╡ cd9ba9af-db52-485b-af56-d14827926137
randomness_space = Bounds((0, 0), (1, 1))

# ╔═╡ af920ac1-a57a-44fe-8026-f18d527becb3
begin
	struct CHState
		t::Float64
		A::Float64
		B::Float64
		C::Float64
	end

	function CHState(t::NTuple{6, Float64})
		CHState(t...)
	end

	Base.convert(::Type{CHState}, x::NTuple{6, Float64}) = CHState(x)
	Base.length(::CHState) = 4
	Base.tail(s::CHState) = s.C_B
	Base.iterate(s::CHState) = s.t, 2
	Base.iterate(s::CHState, iter) = 
		if     iter == 2 return s.A, 3
		elseif iter == 3 return s.B, 4
		elseif iter == 4 return s.C, :done
		else
			nothing
		end
end

# ╔═╡ a73bed3f-9e0f-45ad-a32c-935d17a52bb7
begin
	@with_kw struct CHMechanics
		t_act::Float64=1.0
		period::Float64=10.0
		min_stored::Float64 = 2.0
		max_stored::Float64 = 20.0
		mix_A::Float64=0.5 # Mix ratio: mix_A/mix_B
		mix_B::Float64=1.0
		outflow_low_rate::Float64=1.0
		outflow_high_rate::Float64=3.0
		inflow_pattern::Function=default_inflow_pattern
		consumption_pattern::Function=default_consumption_pattern
	end
	
	function default_inflow_pattern(t)
		a = 0.5
		b = 1.0
		pattern_A = (a, 0, a, 0, 0, a, 2*a, a, 0, 0, 0)
		pattern_B = (0, b, b, b, 0, b, 0, 0, 2*b, 0, 0)
		l = length(pattern_A)
		t = 1 + floor(t)%l
		return (pattern_A[t], pattern_B[t])
	end
	
	function default_consumption_pattern(t)
		a = 0.5
		b = 1.0
		c = a + b
		pattern_C = (c, 0, c, 0, 0, c, 2*c, c, 0, 0, 0)
		l = length(pattern_C)
		t = 1 + floor(t)%l
		return pattern_C[t]
	end
end

# ╔═╡ 55cced0c-6b84-4503-a2fe-c8f9a963220e
begin
	defaults = CHMechanics()
md"""
### 🛠 Mechanics

`t_act` = $(@bind t_act NumberField(0:0.1:100, default=defaults.t_act))

`min_stored` = $(@bind min_stored NumberField(0:0.1:100, default=defaults.min_stored))
`max_stored` = $(@bind max_stored NumberField(0:0.1:100, default=defaults.max_stored))

`mix_A` = $(@bind mix_A NumberField(0:0.001:100, default=defaults.mix_A))
`mix_B` = $(@bind mix_B NumberField(0:0.001:100, default=defaults.mix_B))

`outflow_low_rate` = $(@bind outflow_low_rate NumberField(0:0.1:100, default=defaults.outflow_low_rate))
`outflow_high_rate` = $(@bind outflow_high_rate NumberField(0:0.1:100, default=defaults.outflow_high_rate))
"""
end

# ╔═╡ 8b0e8b12-3b16-4d71-9d29-6fb5db82a47a
m = CHMechanics(;t_act, min_stored, max_stored, mix_A, mix_B, outflow_low_rate, outflow_high_rate)

# ╔═╡ f082608a-6a20-4faa-a88d-0f9aa6b2152f
let
	mix_ratio = m.mix_A/m.mix_B
	inflow_A, inflow_B = unzip([m.inflow_pattern(t) for t in 0:m.t_act:m.period])
	inflow_A, inflow_B = sum(inflow_A), sum(inflow_B)
	inflow_ratio = inflow_A/inflow_B
	if abs(inflow_ratio - mix_ratio) > 0.001
		Markdown.parse("""
		!!! danger "Error"
			The periodic inflow of compounds A and B do not match mix ratio. There won't be a safe strategy since one of the tanks will eventually overflow.

			Inflow of A per period: **$inflow_A**
		
			Inflow of B per period: **$inflow_B**

			Ratio of the two: **$(inflow_A/inflow_B)**
		
			Mix ratio: **$(m.mix_A)/$(m.mix_B) = $(mix_ratio)**
			
		""")
	else
		Markdown.parse("""
		!!! success "Inflow is fine."
			There's a correct ratio between inflows: $(m.mix_A)/$(m.mix_B) = $(mix_ratio)
		""")
	end
end

# ╔═╡ b5bd0c64-2816-4f5a-af85-4a23b81d8ec3
let
	inflow_A, inflow_B = unzip([m.inflow_pattern(t) for t in 0:m.t_act:m.period])
	inflow_A, inflow_B = sum(inflow_A), sum(inflow_B)
	outflow = sum([m.consumption_pattern(t) for t in 0:m.t_act:m.period])
	if outflow != inflow_A + inflow_B
		Markdown.parse("""
		!!! danger "Error"
			The consumption is greater than the inflows. The agent won't be able to keep up.

			Inflow of A per period: **$inflow_A**
		
			Inflow of B per period: **$inflow_B**

			Outflow: **$(outflow)**
			
		""")
	else
		Markdown.parse("""
		!!! success "Outflow matches inflow."
			Inflow and consumption are both: $outflow
		""")
	end
end

# ╔═╡ f55e0563-b965-482f-a51e-75d792eb5f1b
let
	ylim = (0, 8)
	
	p1 = plot(x -> default_inflow_pattern(x)[1];
		ylim,
		legend=:outerright,
		xlabel="time",
		ylabel="volume",
		label="Inflow A",
		line=(3, :dot),
		xlim=(0, m.period),
	)
	
	p2 = plot(x -> default_inflow_pattern(x)[2];
		ylim,
		legend=:outerright,
		xlabel="time",
		ylabel="volume",
		label="Inflow B",
		line=(3, :solid),
		xlim=(0, m.period),
	)
	
	p3 = plot(x -> default_consumption_pattern(x);
		ylim,
		legend=:outerright,
		xlabel="time",
		ylabel="volume",
		label="Consumption",
		xlim=(0, m.period),
		line=(3, :dash),
		size=(600, 250)
	)

	plot(p1, p2, p3, layout=(3, 1))
end

# ╔═╡ 4dadcdaa-4fce-4a14-9dd7-e4baf141bd42
# Index-name pairs. Used for choosing axes to draw the shield.
state_variables =[1 => "t", 2 => "A", 3 => "B", 4 => "C"]

# ╔═╡ 34c374e5-dff5-40fb-a641-b25aa597aa26
rand([0, 1], 2)

# ╔═╡ cc75006e-d258-47a4-830f-a00f800b8bf3
middle_volume = m.min_stored + (m.max_stored - m.min_stored)/2

# ╔═╡ 098ca31f-e1e5-4ee4-a42e-7d169915aace
s0 = CHState(0, middle_volume, middle_volume, middle_volume)

# ╔═╡ f6b985da-e65e-4842-921d-8200ba17c157
[x for x in s0]

# ╔═╡ 69001b1e-5208-430b-a809-800a5df71b03
@enum CHAction wait mix output_low output_high

# ╔═╡ c3598256-2917-4546-9066-b4d785e2d55f
md"""
## Simulation Function -- Putting it All Together
"""

# ╔═╡ fed037e7-5100-45a4-9031-ef830c61533d
m

# ╔═╡ 84d04b11-efef-4f02-a9b4-0d266430a655
s_unsafe = CHState(0, m.min_stored, m.min_stored, m.min_stored - 2)

# ╔═╡ 7ecdeacb-fccf-4406-98ea-5f8e7a4b3c84
begin
	# rvar = Random VARiable.
	function simulate_point(m::CHMechanics, point::CHState, rvar, action)::CHState
		if point == s_unsafe
			return s_unsafe
		end
		(;t, A, B, C) = point

		in_A, in_B = m.inflow_pattern(t)

		out_A = action == mix ? m.mix_A : 0 
		out_B = action == mix ? m.mix_B : 0
		
		out_C = action == output_low ? m.outflow_low_rate : 
				action == output_high ? m.outflow_high_rate : 0
		
		t′ = (t + m.t_act)%m.period
		A′ = A + (in_A - out_A)*m.t_act
		B′ = B + (in_B - out_B)*m.t_act
		C′ = C + (out_A + out_B - out_C)*m.t_act
		
		return CHState(t′, A′, B′, C′)
	end
	
	function simulate_point(m::CHMechanics, point, rvar, action)::CHState
		simulate_point(m, CHState(point...), rvar, action)
	end
	
	function simulate_point(m::CHMechanics, point::CHState, action)::CHState
		simulate_point(m, point, rand([0, 1], 2), action)
	end
end

# ╔═╡ 0a5b97c3-b03f-4418-bb36-af0ca6d6471e
struct CHTrace
	states::Vector{CHState}
	times::Vector{Float64}
	actions::Vector{CHAction}
end

# ╔═╡ 58410e5a-0c4a-4afa-b1c0-390b53905fa6
function simulate_sequence(m::CHMechanics, duration, s0, policy)::CHTrace
	states, times, actions = CHState[s0], Float64[0], CHAction[]

	s, t = s0, 0
    while times[end] <= duration - m.t_act
        a = policy(s)
        s = simulate_point(m, s, a)
		t += m.t_act
        push!(states, s)
        push!(times, t)
        push!(actions, a)
    end
    CHTrace(states, times, actions)
end

# ╔═╡ 534ee19b-69ed-4d6d-b80c-ff8b954b6293
random_policy = (_...) -> rand(instances(CHAction))

# ╔═╡ d6016b3e-3d40-4a4c-914f-55a0d5edfa83
trace = simulate_sequence(m, 100, s0, random_policy)

# ╔═╡ 85b4f24c-3567-4b77-ab26-f29de2348181
md"""
## Visualising Traces
"""

# ╔═╡ f6162914-dd94-46e6-868f-478f6280d1cb
function plot_sequence(trace::CHTrace; plotargs...)
	As = [s.A for s in trace.states]
	Bs = [s.B for s in trace.states]
	Cs = [s.C for s in trace.states]

	📈 = plot(trace.times, As, 
		label="A",
		color=colors.EMERALD, 
		linewidth=2,
		xlabel="time (\$s\$)",
		ylabel="Volume (\$l\$)")
	
	plot!(trace.times, Bs, 
		label="B",
		color=colors.PETER_RIVER, 
		linewidth=2)

	hline!([m.min_stored, m.max_stored], color=colors.WET_ASPHALT, label=nothing)

	plot!(trace.times, Cs,
		label="C",
		color=colors.SUNFLOWER,
		linewidth=1,
		xlabel="time (\$s\$)",
		ylabel="Average volume (\$l/s\$)",
		legend=:outerright;
		plotargs...)
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

# ╔═╡ fb6af406-731d-40b9-8f3f-47ddb48c1f5d
m; @bind reset_button Button("Reset")

# ╔═╡ 22205344-1445-41fb-bab9-3fced063d62b
# Initialize or reset trace. Will be modified using reactivity of Pluto Notebooks.
reset_button; reactive_trace = CHTrace(CHState[], Float64[], CHAction[]);

# ╔═╡ 67893b1c-ad3e-45f3-90a4-c684b29438a1
md"""
Agent action

$(@bind interactive_action Select([instances(CHAction)...]))
"""

# ╔═╡ ebf8f146-1aa5-4525-aba5-47ffefb4dc45
md"""
Anatagonist actions (randomized each step)

$(@bind rvar1 NumberField(randomness_space.lower[1]:randomness_space.upper[1], 
	default=rand(randomness_space.lower[1]:randomness_space.upper[1])))
$(@bind rvar2 NumberField(randomness_space.lower[2]:randomness_space.upper[2], 
	default=rand(randomness_space.lower[2]:randomness_space.upper[2])))
"""

# ╔═╡ 29654ee9-9e10-4d1b-b4a4-aef6f3d4f33f
reset_button; @bind step_button CounterButton("Step")

# ╔═╡ 388cace6-e8d3-4fb1-8e86-eeda23b19d2d
let 
	if step_button > 0
		reactive_trace.times ← reactive_trace.times[end] + m.t_act
		reactive_trace.actions ← interactive_action
		s = reactive_trace.states[end]
		s′ = simulate_point(m, s, (rvar1, rvar2), interactive_action)
		reactive_trace.states ← s′
	else
		reactive_trace.times ← 0
		reactive_trace.states ← s0
	end
end;

# ╔═╡ 45543b62-c6fb-4797-a336-e3c456b6e0cb
step_button;plot_sequence(reactive_trace; size=(600, 250))

# ╔═╡ 20830df6-e46b-44e2-acb2-a2c291f9b14a
reactive_trace

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
	function is_safe(s::CHState)
		return (m.min_stored < s.A < m.max_stored
			 && m.min_stored < s.B < m.max_stored
			 && m.min_stored < s.C < m.max_stored
		)
	end

	function is_safe(s) return is_safe(CHState(s...)) end
	
	function is_safe(b::Bounds) return is_safe(b.lower) && is_safe(b.upper) end
end

# ╔═╡ b65725d8-04ed-4a76-ae18-61076211d516
m.min_stored < s0.A < m.max_stored,
m.min_stored < s0.B < m.max_stored,
m.min_stored < s0.C < m.max_stored

# ╔═╡ 2a89484b-0eb1-4175-89b7-58a1806bda89
md"""
## Building the Grid
"""

# ╔═╡ 394f9428-f2d6-46aa-b82e-de3a59dab5ee
function get_bounds(m::CHMechanics)
	Bounds(
		[0, m.min_stored, m.min_stored, m.min_stored],
		[m.period, m.max_stored, m.max_stored, m.max_stored]
	)
end

# ╔═╡ 2a5749b2-0b3d-4e34-9bbe-60ffa6c867ae
grid_bounds = get_bounds(m)

# ╔═╡ daf5778c-10b4-4975-8c72-c65acb388586
# The set of floats actually contained in the grid,
# since the upper bounds are non-inclusive.
grid_bounds_inner = Bounds(grid_bounds.lower, 
	[prevfloat(u) for u in grid_bounds.upper])

# ╔═╡ c52e7c97-0711-4330-95f1-11ffddbfb8c7
any_action, no_action = actions_to_int(instances(CHAction)), actions_to_int([])

# ╔═╡ ed11b92e-283a-454f-9f7c-b75b00dcb921
md"""
### 🛠 `granularity`
`granularity_t =` $(@bind granularity_t NumberField(0.01:0.01:2, default=1))
`granularity_V =` $(@bind granularity_V NumberField(0.01:0.01:2, default=1))
"""

# ╔═╡ b4382746-4cbc-4b75-979e-a3b52d877489
granularity = [granularity_t, granularity_V, granularity_V, granularity_V]

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

# ╔═╡ 81b3f1a4-ecb9-4684-b1a7-d6eb6c989b75
grid  = let
	
	grid = Grid(granularity, grid_bounds)
	initialize!(grid, x -> is_safe(x) ? any_action : no_action)
	grid
end

# ╔═╡ b89e6235-f6d6-4943-a7a3-1992d857be10
GridShielding.box(grid::Grid, s::CHState) = box(grid, s...)

# ╔═╡ b9c584c6-9530-4785-970a-85805797b8f3
unique(grid.array)

# ╔═╡ 32c0ec89-42ea-4e3b-a284-9317c7920165
begin
	ch_color_labels = ["{$(join(actions, ", "))}" 
		for actions in powerset(instances(CHAction))]
	
	ch_colors = [colors[1 + i%length(colors)] 
		for (i, _) in enumerate(ch_color_labels)]
	
	replace!(ch_colors, 
		colors.WET_ASPHALT => colors.POMEGRANATE, 
		colors.CLOUDS => colors.SILVER)
	
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
	clamp!([simulate_point(m, p, r, a)...], grid_bounds_inner)
end

# ╔═╡ 56f86d5c-02d0-4252-8984-d9fb4baca1ee
md"""
### 🛠 `spa_*`

`spa_t =` $(@bind spa_t NumberField(1:9, default=1))

`spa_V =` $(@bind spa_V NumberField(1:9, default=1))

`spa_random =` $(@bind spa_random NumberField(1:9, default=2))
"""

# ╔═╡ a3572115-75ee-42a8-926c-b2099b4f7cc5
samples_per_axis = (spa_t, spa_V, spa_V, spa_V)

# ╔═╡ 8e2fcfff-a319-4a5a-813b-65bd8072c6dc
model = SimulationModel(simulation_function, randomness_space, samples_per_axis, spa_random)

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
		get_transitions(reachability_function, CHAction, grid)
end

# ╔═╡ 939245b5-e393-4b16-b881-b8d5d41b5646
begin
	shield, max_steps_reached = grid, false
	
	if make_shield_button > 0

		# here
		shield, max_steps_reached = 
			make_shield(reachability_function_precomputed, CHAction, grid; max_steps)
		
	end
end

# ╔═╡ 0aee3c2e-44b7-419d-88d3-434d49494835
if max_steps_reached
	Markdown.parse("""
	!!! warning "Max steps reached"
		The method reached a maximum iteration steps of $max_steps before a fixed point was reached. The strategy is only safe for a finite horizon of $max_steps steps.""")
end

# ╔═╡ 7b6080bd-e682-4a6c-a4f1-469ba2a166b0
md"""
### 🛠 Configure display projection

$(@bind index_1 Select(state_variables))

$(@bind index_2 Select(state_variables,	default=2))
"""

# ╔═╡ 84a538ee-c780-4b73-bc98-638bc5da2b93
begin
	xlabel = min(index_1, index_2)
	ylabel = max(index_1, index_2)
	xlabel = Dict(state_variables)[xlabel]
	ylabel = Dict(state_variables)[ylabel]
	(;xlabel, ylabel)
end

# ╔═╡ c9d8a8ea-5ffe-44a6-b8a8-ca955eed3184
md"""
### 🛠 `s`, `a`
`t =` $(@bind t NumberField(0:m.period - granularity_t, default=s0.t))

`A =` $(@bind A NumberField(m.min_stored:m.max_stored - granularity_V, default=s0.A))
`B =` $(@bind B NumberField(m.min_stored:m.max_stored - granularity_V, default=s0.B))

`C =` $(@bind C NumberField(m.min_stored:m.max_stored - granularity_V, default=s0.C))

`action =` $(@bind action Select([instances(CHAction)...]))

"""

# ╔═╡ 2060621f-84b6-448a-a857-0d6c556e3f4f
s = CHState(t, A, B, C)

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

# ╔═╡ 94ba7109-6600-4ad9-96d7-145130092566
slice = let
	slice = Any[partition.indices...]
	slice[index_1] = Colon()
	slice[index_2] = Colon()
	slice
end

# ╔═╡ ca3fe131-a504-48a6-bfa9-77869d76689d
simulate_point(m, s, action)

# ╔═╡ 9798d4b5-b740-4f16-a013-adfa93d722bf
simulate_point(m, s, action)

# ╔═╡ f73b6e42-c024-4018-83b2-2eac30e96fda
draw(shield, slice; colors=ch_colors, color_labels=ch_color_labels, #show_grid=true,
	legend=:outerright,
	size=(800,400),
	xlabel, 
	ylabel
)

# ╔═╡ 1857b91b-de36-44b9-afeb-5739c19ffea0
make_shield_button; unique(shield.array)

# ╔═╡ cbaf2ad3-9d1b-4a58-9f76-797bca422fe3
function shielded_random(s::CHState)
	if [s...] ∉ grid
		return rand(instances(CHAction))
	end
	partition = box(shield, s)
	allowed = int_to_actions(CHAction, get_value(partition))
	if length(allowed) == 0
		return rand(instances(CHAction))
	end
	rand(allowed)
end

# ╔═╡ 6a7c19f3-964a-453a-b93c-fc7c8bb1e434
grid_bounds

# ╔═╡ 5ebdad31-631d-4552-a699-931b1a0679c1
shielded_trace = simulate_sequence(m, 100, s0, shielded_random)

# ╔═╡ 3d48fcd3-abd6-48dd-a600-c72221209377
plot_sequence(shielded_trace)

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
	DownloadButton(libshield_so |> read, "libprshield.so")
end

# ╔═╡ Cell order:
# ╠═3a57c06f-0adb-4f92-9f64-f22edbefcadf
# ╟─1e159603-fc61-45f8-9595-f75e55318344
# ╠═c1bdc9f0-3d96-11ee-00af-b341a715281c
# ╠═d2204fe6-a71e-4131-a568-349572ce28d4
# ╠═2b50bd80-1506-4ad3-abbe-589952fddf3c
# ╟─9be0a063-d016-4081-8c5d-dbff0e31de87
# ╟─fd85cc40-217a-4f76-b979-adacb1e0ea9b
# ╟─55cced0c-6b84-4503-a2fe-c8f9a963220e
# ╠═a73bed3f-9e0f-45ad-a32c-935d17a52bb7
# ╟─f082608a-6a20-4faa-a88d-0f9aa6b2152f
# ╟─b5bd0c64-2816-4f5a-af85-4a23b81d8ec3
# ╟─f55e0563-b965-482f-a51e-75d792eb5f1b
# ╠═8b0e8b12-3b16-4d71-9d29-6fb5db82a47a
# ╠═cd9ba9af-db52-485b-af56-d14827926137
# ╠═af920ac1-a57a-44fe-8026-f18d527becb3
# ╠═4dadcdaa-4fce-4a14-9dd7-e4baf141bd42
# ╠═f6b985da-e65e-4842-921d-8200ba17c157
# ╠═34c374e5-dff5-40fb-a641-b25aa597aa26
# ╠═2060621f-84b6-448a-a857-0d6c556e3f4f
# ╠═cc75006e-d258-47a4-830f-a00f800b8bf3
# ╠═098ca31f-e1e5-4ee4-a42e-7d169915aace
# ╠═69001b1e-5208-430b-a809-800a5df71b03
# ╟─c3598256-2917-4546-9066-b4d785e2d55f
# ╠═fed037e7-5100-45a4-9031-ef830c61533d
# ╠═84d04b11-efef-4f02-a9b4-0d266430a655
# ╠═7ecdeacb-fccf-4406-98ea-5f8e7a4b3c84
# ╠═ca3fe131-a504-48a6-bfa9-77869d76689d
# ╠═0a5b97c3-b03f-4418-bb36-af0ca6d6471e
# ╠═58410e5a-0c4a-4afa-b1c0-390b53905fa6
# ╠═534ee19b-69ed-4d6d-b80c-ff8b954b6293
# ╠═d6016b3e-3d40-4a4c-914f-55a0d5edfa83
# ╟─85b4f24c-3567-4b77-ab26-f29de2348181
# ╠═f6162914-dd94-46e6-868f-478f6280d1cb
# ╟─fb61867c-89ca-4685-b3da-2ad7eb18267d
# ╠═1260d5e5-1f2b-4578-909e-a5d0a367b126
# ╟─4faea1ce-ad42-456a-8f8f-6cf3bc9787ff
# ╟─fb6af406-731d-40b9-8f3f-47ddb48c1f5d
# ╠═22205344-1445-41fb-bab9-3fced063d62b
# ╟─67893b1c-ad3e-45f3-90a4-c684b29438a1
# ╟─ebf8f146-1aa5-4525-aba5-47ffefb4dc45
# ╟─29654ee9-9e10-4d1b-b4a4-aef6f3d4f33f
# ╟─388cace6-e8d3-4fb1-8e86-eeda23b19d2d
# ╠═45543b62-c6fb-4797-a336-e3c456b6e0cb
# ╠═20830df6-e46b-44e2-acb2-a2c291f9b14a
# ╟─b35e34d2-6557-4f67-84fe-949f8d8eeed8
# ╟─d4561dbf-40bd-4411-bfda-714554286893
# ╠═41584071-89c1-45f9-bded-61fbe98a9b78
# ╠═b65725d8-04ed-4a76-ae18-61076211d516
# ╠═14643fb4-54b1-4c92-9511-4051b337a258
# ╠═37dcadc9-f699-4913-ae83-585bf9e6f415
# ╠═55dc7ecb-af07-4de9-a900-b0b5ce40131e
# ╟─2a89484b-0eb1-4175-89b7-58a1806bda89
# ╠═2a5749b2-0b3d-4e34-9bbe-60ffa6c867ae
# ╠═daf5778c-10b4-4975-8c72-c65acb388586
# ╠═394f9428-f2d6-46aa-b82e-de3a59dab5ee
# ╠═c52e7c97-0711-4330-95f1-11ffddbfb8c7
# ╟─ed11b92e-283a-454f-9f7c-b75b00dcb921
# ╟─5abfeedd-3a3c-4a20-9ade-673ac225f2a1
# ╠═b4382746-4cbc-4b75-979e-a3b52d877489
# ╠═81b3f1a4-ecb9-4684-b1a7-d6eb6c989b75
# ╠═b89e6235-f6d6-4943-a7a3-1992d857be10
# ╠═cea6063e-277c-40eb-9b36-893a20a7aa28
# ╠═e81836f7-ba93-4735-b30a-35b980ef2ab4
# ╟─84a538ee-c780-4b73-bc98-638bc5da2b93
# ╠═b9c584c6-9530-4785-970a-85805797b8f3
# ╠═32c0ec89-42ea-4e3b-a284-9317c7920165
# ╟─98d6efed-136f-4d2e-b851-0bbb190e7bf9
# ╠═d307696e-54e1-497e-aca0-1f0314a1fdcd
# ╟─56f86d5c-02d0-4252-8984-d9fb4baca1ee
# ╠═a3572115-75ee-42a8-926c-b2099b4f7cc5
# ╠═8e2fcfff-a319-4a5a-813b-65bd8072c6dc
# ╠═f1040518-fc20-4310-8d84-440cd28f0beb
# ╟─5f8e4725-711b-4ee9-834e-47603f26b9eb
# ╟─29275ad2-7509-4cce-b6ee-7ddd8c0c37a2
# ╟─789d1abe-abff-478a-aff2-3ebf40119954
# ╠═7dedba0d-f017-4af3-805f-3fd945abbddb
# ╠═814609db-2993-453a-b17a-bfc84da4542a
# ╠═939245b5-e393-4b16-b881-b8d5d41b5646
# ╠═0aee3c2e-44b7-419d-88d3-434d49494835
# ╟─94ba7109-6600-4ad9-96d7-145130092566
# ╟─7b6080bd-e682-4a6c-a4f1-469ba2a166b0
# ╟─c9d8a8ea-5ffe-44a6-b8a8-ca955eed3184
# ╠═9798d4b5-b740-4f16-a013-adfa93d722bf
# ╠═f73b6e42-c024-4018-83b2-2eac30e96fda
# ╠═1857b91b-de36-44b9-afeb-5739c19ffea0
# ╠═cbaf2ad3-9d1b-4a58-9f76-797bca422fe3
# ╠═6a7c19f3-964a-453a-b93c-fc7c8bb1e434
# ╠═5ebdad31-631d-4552-a699-931b1a0679c1
# ╠═3d48fcd3-abd6-48dd-a600-c72221209377
# ╟─5ff82f30-fabe-4a39-912f-6aadd31228f1
# ╟─8d0e55c3-ea57-408b-8c9b-d8484226b43d
# ╟─a3ea7ead-3589-405e-94f3-1d523e5e0a6c
