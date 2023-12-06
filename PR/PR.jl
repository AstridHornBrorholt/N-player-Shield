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

# ╔═╡ 9be0a063-d016-4081-8c5d-dbff0e31de87
md"""
# Simulating the System
"""

# ╔═╡ fd85cc40-217a-4f76-b979-adacb1e0ea9b
md"""
## Mechanics
"""

# ╔═╡ a73bed3f-9e0f-45ad-a32c-935d17a52bb7
@with_kw struct PRMechanics
	t_act::Float64 = 1
	min_stored::Float64 = 2
	max_stored::Float64 = 12
	n::Int64 = 5
	min_average::Float64 = 0.4
	max_average::Float64 = 0.6
	production_rate::Float64=1
end

# ╔═╡ 55cced0c-6b84-4503-a2fe-c8f9a963220e
md"""
### 🛠 Mechanics

`n =` $(@bind n NumberField(1:1000, default=5))

`min_average =` $(@bind min_average NumberField(0:0.02:1, default=0.4))
`max_average =` $(@bind max_average NumberField(0:0.02:1, default=0.6))

"""

# ╔═╡ 8b0e8b12-3b16-4d71-9d29-6fb5db82a47a
m = PRMechanics(;min_average, max_average, n)

# ╔═╡ c756989a-4492-4ef2-9aae-a63c23e46c63
md"""
## Contract between production units

There needs to be some sort of contract between production units enforced as a safety property. Otherwise, it won't be possible to have decentralized shields, as there is no safe strategy if one tank overflows while the other stays empty.

### Moving Average
It is my hope that restrictions on a moving average will prevent both overload and starvation of the recipients.

https://stackoverflow.com/questions/12636613/how-to-calculate-moving-average-without-keeping-the-count-and-data-total

I am having to find a better source for this if it makes it into the article.
"""

# ╔═╡ 6414f65a-0580-40a6-ad52-a7ddb475995c
function moving_average(n, current_average, new_value)
	# current_average - current_average/n + new_value/n <=>
	return current_average + (new_value - current_average)/n
end

# ╔═╡ f79a92ce-0dc2-431f-947a-e5820d5073c0
let
	computed_average = []
	current_average = .5
	number_of_samples = 50
	samples = [i%2 for i in 1:number_of_samples]
	samples[24] = 1
	samples[26] = 1
	for i in 1:number_of_samples
		push!(computed_average, current_average)
		current_average = moving_average(n, current_average, samples[i])
	end
	plot(computed_average,
		marker=(:square, 3),
		label="moving average (n=$n)",
		xlabel="number of samples",
		title="Illustration of a moving average",
		ylim=(-1, 2),
		size=(600, 300),
		legend=:outerbottom
	)
	plot!(samples,
		marker=(:utriangle, 3),
		label="sample values"
	)
	hline!([0.5], label=nothing)
end

# ╔═╡ 1b5ae809-48fa-4765-9151-b9a3b7e0b008
md"""
Okay this seems workable. Now, what can an agent do, under some restrictions to min and max average?
"""

# ╔═╡ b2dcc6f7-f7de-4d7d-ba1a-e5b112ceaeb7
begin
	function input_behaviour(m::PRMechanics, current_average, random_variable)
		if moving_average(m.n, current_average, m.production_rate) > m.max_average
			return 0
		elseif moving_average(m.n, current_average, 0) < m.min_average
			return m.production_rate
		else
			# I expect the random variable to be either 0 or 1, but just in case
			if random_variable < 0.5 return 0 else return m.production_rate end
		end
	end

	function input_behaviour(m::PRMechanics, current_average)
		return input_behaviour(m, current_average, rand([0, 1]))
	end
end

# ╔═╡ 2d23f896-a12e-445f-8345-fd71286661c7
md"""
## State-space, action-space and random variables

The state is expressed as 
-  $V_a$ volume of material in tank $a$. 
-  $V_b$ volume of material in tank $b$.
-  $µ_{in, left}$ average inflow from left input.
-  $µ_{in, right}$ average inflow from right input.
-  $µ_{out, left}$ average outflow from left output.
-  $µ_{out, right}$ average outflow from right output.

Random outcomes are drawn uniformly from the random variable $R ∈ \left(\matrix{b_1\\b_2} \right)$ where $b_1, b_2 ∈ \{0, 1\}$
"""

# ╔═╡ cd9ba9af-db52-485b-af56-d14827926137
randomness_space = Bounds((0, 0), (1, 1))

# ╔═╡ af920ac1-a57a-44fe-8026-f18d527becb3
begin
	struct PRState
		V_a::Float64
		V_b::Float64
		µ_in_a::Float64
		µ_in_b::Float64
		µ_out_a::Float64
		µ_out_b::Float64
	end

	function PRState(t::NTuple{6, Float64})
		PRState(t...)
	end

	Base.convert(::Type{PRState}, x::NTuple{6, Float64}) = PRState(x)
	Base.length(::PRState) = 6
	Base.tail(s::PRState) = s.µ_out_b
	Base.iterate(s::PRState) = s.V_a, 2
	Base.iterate(s::PRState, iter) = if iter == 2 return s.V_b, 3
		elseif iter == 3 return s.µ_in_a, 4
		elseif iter == 4 return s.µ_in_b, 5
		elseif iter == 5 return s.µ_out_a, 6
		elseif iter == 6 return s.µ_out_b, :done
		else
			nothing
		end
end

# ╔═╡ 34c374e5-dff5-40fb-a641-b25aa597aa26
rand([0, 1], 2)

# ╔═╡ 21b66dc8-ad0f-4172-abc9-c4c7a96dbc0e
V_init = m.min_stored + (m.max_stored - m.min_stored)/2

# ╔═╡ 7a951e93-75f5-4159-a506-a1ad657ba808
µ_init = m.min_average + (m.max_average - m.min_average)/2

# ╔═╡ fba4cf5d-3b9b-47d9-b2e0-0e18545d7140
let
	computed_average = []
	samples = []
	current_average = µ_init
	number_of_samples = 100
	for i in 1:number_of_samples
		push!(computed_average, current_average)
		push!(samples, input_behaviour(m, current_average))
		current_average = moving_average(n, current_average, samples[i])
	end
	plot(computed_average,
		marker=(:square, 3),
		label="moving average (n=$n)",
		xlabel="number of samples",
		title="Input behaviour under moving average constraints",
		ylim=(-1, 2),
		size=(600, 300),
		legend=:outerbottom
	)
	plot!(samples,
		marker=(:utriangle, 3),
		label="sample values"
	)
	hline!([min_average, max_average], label=nothing, color=:gray)
end

# ╔═╡ 098ca31f-e1e5-4ee4-a42e-7d169915aace
s0 = PRState(V_init, V_init, µ_init, µ_init, µ_init, µ_init)

# ╔═╡ 1f7ac0fd-7885-4a6e-816c-70efd61601b4
PRState[s0]

# ╔═╡ 69001b1e-5208-430b-a809-800a5df71b03
@enum PRAction off_off on_off off_on on_on

# ╔═╡ c3598256-2917-4546-9066-b4d785e2d55f
md"""
## Simulation Function -- Putting it All Together
"""

# ╔═╡ 7ecdeacb-fccf-4406-98ea-5f8e7a4b3c84
begin
	# rvar = Random VARiable.
	function simulate_point(mechanics::PRMechanics, point::PRState, rvar, action)
		(;V_a, V_b, µ_in_a, µ_in_b, µ_out_a, µ_out_b) = point

		in_a = input_behaviour(mechanics, µ_in_a, rvar[1])
		in_b = input_behaviour(mechanics, µ_in_b, rvar[2])

		out_a = (action == on_on || action == on_off) ? m.production_rate : 0 
		out_b = (action == on_on || action == off_on) ? m.production_rate : 0 

		V_a′ = V_a + (in_a - out_a)*m.t_act
		V_b′ = V_b + (in_b - out_b)*m.t_act
		µ_in_a′ = moving_average(m.n, µ_in_a, in_a)
		µ_in_b′ = moving_average(m.n, µ_in_b, in_b)
		µ_out_a′ = moving_average(m.n, µ_out_a, out_a)
		µ_out_b′ = moving_average(m.n, µ_out_b, out_b)
		
		return PRState(V_a′, V_b′, µ_in_a′, µ_in_b′, µ_out_a′, µ_out_b′)
	end
	
	function simulate_point(mechanics::PRMechanics, point, rvar, action)
		simulate_point(mechanics, PRState(point...), rvar, action)
	end
	
	function simulate_point(mechanics::PRMechanics, point::PRState, action)
		simulate_point(mechanics, point, rand([0, 1], 2), action)
	end
end

# ╔═╡ 14a019b1-4d13-4a6f-ac6e-bba252bc0a50
simulate_point(m, s0, off_off)

# ╔═╡ 0a5b97c3-b03f-4418-bb36-af0ca6d6471e
struct PRTrace
	states::Vector{PRState}
	times::Vector{Float64}
	actions::Vector{PRAction}
end

# ╔═╡ 58410e5a-0c4a-4afa-b1c0-390b53905fa6
function simulate_sequence(m::PRMechanics, duration, s0, policy)::PRTrace
	states, times, actions = PRState[s0], Float64[0], PRAction[]

	s, t = s0, 0
    while times[end] <= duration - m.t_act
        a = policy(s)
        s = simulate_point(m, s, a)
		t += m.t_act
        push!(states, s)
        push!(times, t)
        push!(actions, a)
    end
    PRTrace(states, times, actions)
end

# ╔═╡ 534ee19b-69ed-4d6d-b80c-ff8b954b6293
random_policy = (_...) -> rand(instances(PRAction))

# ╔═╡ d6016b3e-3d40-4a4c-914f-55a0d5edfa83
trace = simulate_sequence(m, 100, s0, random_policy)

# ╔═╡ 85b4f24c-3567-4b77-ab26-f29de2348181
md"""
## Visualising Traces
"""

# ╔═╡ f6162914-dd94-46e6-868f-478f6280d1cb
function plot_sequence(trace::PRTrace)
	V_as = [s.V_a for s in trace.states]
	V_bs = [s.V_b for s in trace.states]
	µ_in_as = [s.µ_in_a for s in trace.states]
	µ_in_bs = [s.µ_in_b for s in trace.states]
	µ_out_as = [s.µ_out_a for s in trace.states]
	µ_out_bs = [s.µ_out_b for s in trace.states]

	📈 = plot(trace.times, V_as, 
		label="\$V_a\$",
		color=colors.EMERALD, 
		linewidth=2,
		xlabel="time (\$s\$)",
		ylabel="Volume (\$l\$)")
	
	plot!(trace.times, V_bs, 
		label="\$V_b\$",
		color=colors.PETER_RIVER, 
		linewidth=2)

	hline!([m.min_stored, m.max_stored], color=colors.WET_ASPHALT, label=nothing)

	📉 = plot(trace.times, µ_in_as,
		label="\$µ_{in,a}\$",
		color=colors.SUNFLOWER,
		linewidth=1,
		xlabel="time (\$s\$)",
		ylabel="Average volume (\$l/s\$)")

	plot!(trace.times, µ_in_bs,
		label="\$µ_{in,b}\$",
		color=colors.ALIZARIN,
		linewidth=1)

	plot!(trace.times, µ_out_as,
		label="\$µ_{out,a}\$",
		linewidth=3,
		color=colors.EMERALD)

	plot!(trace.times, µ_out_bs,
		label="\$µ_{out,b}\$",
		linewidth=3,
		color=colors.PETER_RIVER)

	hline!([m.min_average, m.max_average], color=colors.WET_ASPHALT, label=nothing)
	
	plot(📉, 📈, 
		#size=(800, 600),
		layout=(2, 1), 
		legend=:outerright)
end

# ╔═╡ fb61867c-89ca-4685-b3da-2ad7eb18267d
plot_sequence(trace)

# ╔═╡ 1260d5e5-1f2b-4578-909e-a5d0a367b126
gif(@animate(for _ in 1:10 plot_sequence(simulate_sequence(m, 100, s0, random_policy)) end), show_msg=false, fps=1)

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
	function is_safe(s::PRState)
		return (m.min_stored < s.V_a < m.max_stored
			 && m.min_stored < s.V_b < m.max_stored
			 # Assuming for now that inputs stick to the contract
			 # && m.min_average <= s.μ_in_a <= m.max_average
			 # && m.min_average <= s.μ_in_b <= m.max_average
			 && m.min_average < s.μ_out_a < m.max_average
			 && m.min_average < s.μ_out_b < m.max_average
		)
	end

	function is_safe(s) return is_safe(PRState(s...)) end
	
	function is_safe(b::Bounds) return is_safe(b.lower) && is_safe(b.upper) end
end

# ╔═╡ 2a89484b-0eb1-4175-89b7-58a1806bda89
md"""
## Building the Grid
"""

# ╔═╡ 394f9428-f2d6-46aa-b82e-de3a59dab5ee
function get_bounds(m::PRMechanics)
	Bounds(
		[m.min_stored, m.min_stored, 
			m.min_average, m.min_average, m.min_average, m.min_average],
		[m.max_stored, m.max_stored, 
			m.max_average, m.max_average, m.max_average, m.max_average]
	)
end

# ╔═╡ 2a5749b2-0b3d-4e34-9bbe-60ffa6c867ae
grid_bounds = get_bounds(m)

# ╔═╡ ed11b92e-283a-454f-9f7c-b75b00dcb921
md"""
### 🛠 `granularity_V`, `granularity_µ`
`granularity_V =` $(@bind granularity_V NumberField(0.01:0.01:2, default=1))
`granularity_µ =` $(@bind granularity_µ NumberField(0.01:0.01:2, default=0.02))
"""

# ╔═╡ c52e7c97-0711-4330-95f1-11ffddbfb8c7
any_action, no_action = actions_to_int(instances(PRAction)), actions_to_int([])

# ╔═╡ 81b3f1a4-ecb9-4684-b1a7-d6eb6c989b75
grid = let
	granularity = [granularity_V, granularity_V, 
		granularity_μ, granularity_μ, granularity_μ, granularity_μ]
	
	grid = Grid(granularity, grid_bounds)
	initialize!(grid, x -> is_safe(x) ? any_action : no_action)
	grid
end

# ╔═╡ 0927b85a-6625-4c9b-a319-98626d2a03b1
size(grid), length(grid)

# ╔═╡ b89e6235-f6d6-4943-a7a3-1992d857be10
GridShielding.box(grid::Grid, s::PRState) = box(grid, s...)

# ╔═╡ 4dadcdaa-4fce-4a14-9dd7-e4baf141bd42
state_variables =[1 => "V_a", 2 => "V_b", 3 => "µ_in_a", 4 => "µ_in_b", 5 => "µ_out_a", 6 => "µ_out_b"]

# ╔═╡ b9c584c6-9530-4785-970a-85805797b8f3
unique(grid.array)

# ╔═╡ 32c0ec89-42ea-4e3b-a284-9317c7920165
begin
	pr_color_labels = ["{$(join(actions, ", "))}" for actions in powerset(instances(PRAction))]
	pr_colors = [colors[i] for (i, _) in enumerate(pr_color_labels)]
end;

# ╔═╡ 98d6efed-136f-4d2e-b851-0bbb190e7bf9
md"""
## Simulation Model

Amon other things, we get to use the `randomness_space` variable we defined way earlier.
"""

# ╔═╡ d307696e-54e1-497e-aca0-1f0314a1fdcd
function simulation_function(p, a, r)
	simulate_point(m, p, r, a)
end

# ╔═╡ 56f86d5c-02d0-4252-8984-d9fb4baca1ee
md"""
### 🛠 `spa_*`

`spa_V =` $(@bind spa_V NumberField(1:9, default=1))
`spa_µ =` $(@bind spa_µ NumberField(1:9, default=2))

`spa_random =` $(@bind spa_random NumberField(1:9, default=2))
"""

# ╔═╡ a3572115-75ee-42a8-926c-b2099b4f7cc5
samples_per_axis = (spa_V, spa_V, spa_µ, spa_µ, spa_µ, spa_µ)

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
		get_transitions(reachability_function, PRAction, grid)
end;

# ╔═╡ 939245b5-e393-4b16-b881-b8d5d41b5646
begin
	shield, max_steps_reached = grid, false
	
	if make_shield_button > 0

		# here is the computation
		shield, max_steps_reached = 
			make_shield(reachability_function_precomputed, CCAction, grid; max_steps)
		
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

`V_a =` $(@bind V_a NumberField(m.min_stored:m.max_stored - granularity_V))
`V_b =` $(@bind V_b NumberField(m.min_stored:m.max_stored - granularity_V))

`µ_in_a =` $(@bind µ_in_a NumberField(m.min_average:0.02:m.max_average - granularity_µ))
`µ_in_b =` $(@bind µ_in_b NumberField(m.min_average:0.02:m.max_average - granularity_µ))

`µ_out_a =` $(@bind µ_out_a NumberField(m.min_average:0.02:m.max_average - granularity_µ))
`µ_out_b =` $(@bind µ_out_b NumberField(m.min_average:0.02:m.max_average - granularity_µ))


`action =` $(@bind action Select([instances(PRAction)...]))

"""

# ╔═╡ 2060621f-84b6-448a-a857-0d6c556e3f4f
s = PRState(V_a, V_b, µ_in_a, µ_in_b, µ_out_a, µ_out_b)

# ╔═╡ cea6063e-277c-40eb-9b36-893a20a7aa28
partition = box(grid, s)

# ╔═╡ e81836f7-ba93-4735-b30a-35b980ef2ab4
bounds = Bounds(partition)

# ╔═╡ 14643fb4-54b1-4c92-9511-4051b337a258
is_safe(s0), !is_safe(PRState(-10, 100, 0, 0, 0, 0)), is_safe(bounds)

# ╔═╡ 55dc7ecb-af07-4de9-a900-b0b5ce40131e
bounds

# ╔═╡ ca3fe131-a504-48a6-bfa9-77869d76689d
simulate_point(m, s, action)

# ╔═╡ 7b6080bd-e682-4a6c-a4f1-469ba2a166b0
md"""
### 🛠 Axis display

$(@bind index_1 Select(state_variables))

$(@bind index_2 Select(state_variables,	default=2))
"""

# ╔═╡ 94ba7109-6600-4ad9-96d7-145130092566
slice = let
	slice = Any[partition.indices...]
	slice[index_1] = Colon()
	slice[index_2] = Colon()
	slice
end

# ╔═╡ 84a538ee-c780-4b73-bc98-638bc5da2b93
begin
	xlabel = min(index_1, index_2)
	ylabel = max(index_1, index_2)
	xlabel = Dict(state_variables)[xlabel]
	ylabel = Dict(state_variables)[ylabel]
	(;xlabel, ylabel)
end

# ╔═╡ f73b6e42-c024-4018-83b2-2eac30e96fda
draw(shield, slice; colors=pr_colors, color_labels=pr_color_labels, show_grid=true,
	legend=:outerright,
	xlabel, 
	ylabel
)

# ╔═╡ 5ff82f30-fabe-4a39-912f-6aadd31228f1
md"""
### Download result
"""

# ╔═╡ 8d0e55c3-ea57-408b-8c9b-d8484226b43d
let
	buffer = IOBuffer()
	robust_grid_serialization(buffer, shield)
	DownloadButton(take!(buffer), "Cruise Control.shield")
end

# ╔═╡ a3ea7ead-3589-405e-94f3-1d523e5e0a6c
let
	libshield_so = get_libshield(shield)
	DownloadButton(libshield_so |> read, "libshield.so")
end

# ╔═╡ Cell order:
# ╠═3a57c06f-0adb-4f92-9f64-f22edbefcadf
# ╠═1e159603-fc61-45f8-9595-f75e55318344
# ╠═c1bdc9f0-3d96-11ee-00af-b341a715281c
# ╠═d2204fe6-a71e-4131-a568-349572ce28d4
# ╟─9be0a063-d016-4081-8c5d-dbff0e31de87
# ╟─fd85cc40-217a-4f76-b979-adacb1e0ea9b
# ╠═a73bed3f-9e0f-45ad-a32c-935d17a52bb7
# ╠═1f7ac0fd-7885-4a6e-816c-70efd61601b4
# ╟─55cced0c-6b84-4503-a2fe-c8f9a963220e
# ╠═8b0e8b12-3b16-4d71-9d29-6fb5db82a47a
# ╟─c756989a-4492-4ef2-9aae-a63c23e46c63
# ╠═6414f65a-0580-40a6-ad52-a7ddb475995c
# ╟─f79a92ce-0dc2-431f-947a-e5820d5073c0
# ╟─1b5ae809-48fa-4765-9151-b9a3b7e0b008
# ╠═b2dcc6f7-f7de-4d7d-ba1a-e5b112ceaeb7
# ╟─fba4cf5d-3b9b-47d9-b2e0-0e18545d7140
# ╟─2d23f896-a12e-445f-8345-fd71286661c7
# ╠═cd9ba9af-db52-485b-af56-d14827926137
# ╠═af920ac1-a57a-44fe-8026-f18d527becb3
# ╠═34c374e5-dff5-40fb-a641-b25aa597aa26
# ╠═2060621f-84b6-448a-a857-0d6c556e3f4f
# ╠═21b66dc8-ad0f-4172-abc9-c4c7a96dbc0e
# ╠═7a951e93-75f5-4159-a506-a1ad657ba808
# ╠═098ca31f-e1e5-4ee4-a42e-7d169915aace
# ╠═69001b1e-5208-430b-a809-800a5df71b03
# ╟─c3598256-2917-4546-9066-b4d785e2d55f
# ╠═7ecdeacb-fccf-4406-98ea-5f8e7a4b3c84
# ╠═14a019b1-4d13-4a6f-ac6e-bba252bc0a50
# ╠═ca3fe131-a504-48a6-bfa9-77869d76689d
# ╠═0a5b97c3-b03f-4418-bb36-af0ca6d6471e
# ╠═58410e5a-0c4a-4afa-b1c0-390b53905fa6
# ╠═534ee19b-69ed-4d6d-b80c-ff8b954b6293
# ╠═d6016b3e-3d40-4a4c-914f-55a0d5edfa83
# ╟─85b4f24c-3567-4b77-ab26-f29de2348181
# ╟─f6162914-dd94-46e6-868f-478f6280d1cb
# ╠═fb61867c-89ca-4685-b3da-2ad7eb18267d
# ╠═1260d5e5-1f2b-4578-909e-a5d0a367b126
# ╟─b35e34d2-6557-4f67-84fe-949f8d8eeed8
# ╟─d4561dbf-40bd-4411-bfda-714554286893
# ╠═41584071-89c1-45f9-bded-61fbe98a9b78
# ╠═14643fb4-54b1-4c92-9511-4051b337a258
# ╠═55dc7ecb-af07-4de9-a900-b0b5ce40131e
# ╟─2a89484b-0eb1-4175-89b7-58a1806bda89
# ╠═2a5749b2-0b3d-4e34-9bbe-60ffa6c867ae
# ╠═394f9428-f2d6-46aa-b82e-de3a59dab5ee
# ╟─ed11b92e-283a-454f-9f7c-b75b00dcb921
# ╠═c52e7c97-0711-4330-95f1-11ffddbfb8c7
# ╠═0927b85a-6625-4c9b-a319-98626d2a03b1
# ╠═81b3f1a4-ecb9-4684-b1a7-d6eb6c989b75
# ╠═b89e6235-f6d6-4943-a7a3-1992d857be10
# ╠═cea6063e-277c-40eb-9b36-893a20a7aa28
# ╠═e81836f7-ba93-4735-b30a-35b980ef2ab4
# ╟─4dadcdaa-4fce-4a14-9dd7-e4baf141bd42
# ╟─94ba7109-6600-4ad9-96d7-145130092566
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
# ╠═939245b5-e393-4b16-b881-b8d5d41b5646
# ╠═0aee3c2e-44b7-419d-88d3-434d49494835
# ╟─c9d8a8ea-5ffe-44a6-b8a8-ca955eed3184
# ╟─7b6080bd-e682-4a6c-a4f1-469ba2a166b0
# ╠═f73b6e42-c024-4018-83b2-2eac30e96fda
# ╟─5ff82f30-fabe-4a39-912f-6aadd31228f1
# ╠═8d0e55c3-ea57-408b-8c9b-d8484226b43d
# ╠═a3ea7ead-3589-405e-94f3-1d523e5e0a6c
