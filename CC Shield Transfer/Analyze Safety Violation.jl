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
	include("CC Shield Transfer.jl")
end

# ╔═╡ 1e159603-fc61-45f8-9595-f75e55318344
md"""
# Analyze Safety Violation

Analysis of safety violations that (at some point did) occur when the shield is applied to different cc-mechanics using a projection $\pi$. 

This is Frankenstein'd from like 3 different notebooks so good luck.
"""

# ╔═╡ fdfabe1d-165c-4e05-b4cb-56eda950428a
md"""
# Preamble
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

# ╔═╡ 80df6e1a-58e9-4815-a703-30e6042b0357
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

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

# ╔═╡ 84c15413-a6c8-470e-9254-38ee64971339
md"""
## Simulation Model
"""

# ╔═╡ 89f85fd9-5e94-4070-bc52-c3c7fe664d08
samples_per_axis = (1, 1, 3)

# ╔═╡ d5a00bed-51c6-4e39-b9fc-9c7e681bb67f
samples_per_random_axis = 3

# ╔═╡ 79b9a410-94c1-4cbe-81fa-8e1e1b9ff480
model = SimulationModel(simulation_function, randomness_space, samples_per_axis, samples_per_random_axis)

# ╔═╡ 49d27e6a-d5a1-440a-b7f0-90ef479b1353
reachability_function = get_barbaric_reachability_function(model)

# ╔═╡ da8a843d-b5c7-4155-b90c-3df160996c13
md"""
## Imported Shield
"""

# ╔═╡ 465a1c6a-52f2-4ab9-b950-caaae1c8d3fd
@bind shieldpath TextField(80, 
	default = pwd() ⨝ "../CC Shield/Cruise Control.shield" |> realpath)

# ╔═╡ 8d6cd687-0964-4060-a6b2-4947d595d576
shield = robust_grid_deserialization(shieldpath)

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
	Pr[<=100;100](<> exists (i : int[0, fleetSize - 1]) 
		(velocity[i] < minVelocity || velocity[i] > maxVelocity)
	)
	
	simulate[<=100;10] {
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
			at_regular_intervals(raw_velocities[1][trace_id], m.t_act),
			at_regular_intervals(raw_velocities[0][trace_id], m.t_act),
			at_regular_intervals(raw_distances[0][trace_id], m.t_act),
			at_regular_intervals(raw_accelerations[1][trace_id], m.t_act),
			at_regular_intervals(raw_accelerations[0][trace_id], m.t_act),
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

# ╔═╡ a1363edd-543f-4f2e-8e53-140039360a7b
md"""
# Inspect Specific Trace
"""

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

# ╔═╡ d55205c6-2498-4255-90e7-3a40827942d3
π(s)

# ╔═╡ 95735d07-5c59-4254-a581-d6171f5362c7
s′ = traces[trace_id][time + 1]

# ╔═╡ 71488b0b-6caf-4f07-b657-72c2776e8040
is_safe(s, m=m′)

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
	µ = box(shield, round.(π(s)))
	int_to_actions(CCAction, get_value(µ))
end

# ╔═╡ 33b9bebe-9100-4509-b797-e7ad168ba9e9
function acceleration_to_action(acceleration::Number; m)
	acceleration == m.acceleration ? forwards :
	acceleration == 0 ? neutral :
	acceleration == -m.acceleration ? backwards :
	error("unexpected value for acceleration: $acceleration")
end

# ╔═╡ 98236fa0-bb63-423e-b7cb-6bff0b6d121b
ego_action, front_action = acceleration_to_action(s′[4], m=m′), acceleration_to_action(s′[5], m=m′)

# ╔═╡ 549a6a06-7209-4e03-825b-c0512d5def37
let 
	if ego_action ∉ allowed
		header = "!!! danger \"Shield ignored!\""
	else
		header = "!!! success \"Safe action taken\""
	end

	Markdown.parse(header*"""

		Allowed: `[$(join([string(a) for a in allowed], ", "))]`

		Taken: `$(ego_action)`
	""")
end

# ╔═╡ 8e5a6e54-03d3-491f-8da5-711f4a9a08c9
# Possible outcomes from s
predicted_points = [simulate_point(m′, s, r, ego_action) for r in 0:0.05:1] |> unique

# ╔═╡ 6e56a1ce-42f2-466d-b2d4-686252c324dd
let
	# Applying pi to variables
	s = π(s)
	predicted_points = [π(p) for p in predicted_points]

	draw′(shield, s...)
	plot!(xlabel="velocity",
		ylabel="distance",
		size=(800, 400))

	# Homemade version of draw_barbaric_transition 
	scatter!([s[2]], [s[3]],
		label=nothing,
		marker=(6, :+, :black),
		markerstrokewidth=4,)

	scatter!([p[2] for p in predicted_points], [p[3] for p in predicted_points],
		label=nothing,
		marker=(4, :circle, :gray),
		markerstrokewidth=0,)
end

# ╔═╡ 18001247-5da1-44ad-9609-d514f8a04c1c
function apply_projection(bounds::Bounds, projection)
	Bounds(
		projection(bounds.lower),
		projection(bounds.upper)
	)
end

# ╔═╡ 09201c31-e888-4bbf-8420-503d2450fbfb
granularity_v = (m′.v_ego_max - m′.v_ego_min)/15

# ╔═╡ 327d69de-6176-4b27-b444-40bbe2265d7e
granularity_d = (m′.distance_max - m′.distance_min)/200

# ╔═╡ d49cdfe1-d6fe-4d2a-9b21-e93b0f5fff42
middle = (granularity_v/2, granularity_v/2, granularity_d/2)

# ╔═╡ 231968b7-6ad5-4101-bfff-b5ebe04e5247
partition = box(shield, π(s[1:3] .+ middle))

# ╔═╡ 7effef26-c80e-49b0-9fbf-599a16e43b9b
reachable_ix = reachability_function(partition, ego_action)

# ╔═╡ 695ff5ae-b7f0-4d81-b6e3-ac35a30bc45a
reachable_partitions = [(GridShielding.Partition(shield, i)) for i in reachable_ix]

# ╔═╡ 328ee53c-6671-4e32-9a71-e881f8d82962
reachable_bounds = [Bounds(µ) for µ in reachable_partitions]

# ╔═╡ 60b4f309-767f-4e93-af23-0c5cd799efda
reachable = [apply_projection(b, π⁻¹) for b in reachable_bounds]

# ╔═╡ 4ea987bf-2447-4719-99a9-352d37f554bb
discrepancy = !any([s′[1:3] .+ middle ∈ r for r in reachable])

# ╔═╡ a9fc2526-a740-4f9c-b337-a70cfa59d738
let
	if discrepancy
		header = """!!! danger "Discrepancy" """
		
	else
		header = """!!! success "UPPAAL model in agreement with reachability function." """
	end
	
	Markdown.parse(header * """

		Action: `$ego_action` 
		(front action: `$front_action`)
		
		State: `$(s[1:3])`
		(v\\_ego, v\\_front, distance)
	
		Subsequent state: `$(s′[1:3])` 
		(+ middle:`$(s′[1:3] .+ middle)`)
	
		Predicted squares:
		
		    $(prettyprint(reachable, "\n        "))

		Predicted points: 
	
			$predicted_points

		
	""")
	
end

# ╔═╡ Cell order:
# ╟─1e159603-fc61-45f8-9595-f75e55318344
# ╟─fdfabe1d-165c-4e05-b4cb-56eda950428a
# ╠═c1bdc9f0-3d96-11ee-00af-b341a715281c
# ╠═6a33c245-d3ba-42ff-bac1-174e7082dd92
# ╠═59eac6a7-c4c3-4579-bc23-42549f95ae83
# ╠═77d2442c-8081-4cc0-90f5-65684b51b801
# ╟─dc3c1888-5846-498a-ad37-92c6d5493c1b
# ╟─80df6e1a-58e9-4815-a703-30e6042b0357
# ╟─fe5ecd5a-cda8-4c97-856f-a36401dbaadf
# ╟─308cc16b-1c00-4689-9187-45abf1967ca4
# ╟─20fd3eb5-3bc1-4862-9aa0-d7a01f977fe3
# ╠═84c15413-a6c8-470e-9254-38ee64971339
# ╠═89f85fd9-5e94-4070-bc52-c3c7fe664d08
# ╠═d5a00bed-51c6-4e39-b9fc-9c7e681bb67f
# ╠═79b9a410-94c1-4cbe-81fa-8e1e1b9ff480
# ╠═49d27e6a-d5a1-440a-b7f0-90ef479b1353
# ╟─da8a843d-b5c7-4155-b90c-3df160996c13
# ╠═465a1c6a-52f2-4ab9-b950-caaae1c8d3fd
# ╠═8d6cd687-0964-4060-a6b2-4947d595d576
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
# ╟─a1363edd-543f-4f2e-8e53-140039360a7b
# ╠═6e56a1ce-42f2-466d-b2d4-686252c324dd
# ╟─fdfb6924-2981-481a-af7d-95a23b81428b
# ╟─aaba0fba-5bc2-4ec6-a369-398f83aaf557
# ╠═99aabe32-7c65-4a9d-9397-ba2db2ca5cab
# ╟─dbf47fae-b242-47ef-b15a-668410499d2c
# ╟─74eba11e-23c4-49e1-9139-8cbfe5984a2b
# ╟─a9fc2526-a740-4f9c-b337-a70cfa59d738
# ╟─549a6a06-7209-4e03-825b-c0512d5def37
# ╠═78308964-0faa-4b13-bd54-e6d0368541d2
# ╠═d55205c6-2498-4255-90e7-3a40827942d3
# ╠═95735d07-5c59-4254-a581-d6171f5362c7
# ╠═71488b0b-6caf-4f07-b657-72c2776e8040
# ╠═98236fa0-bb63-423e-b7cb-6bff0b6d121b
# ╠═8e5a6e54-03d3-491f-8da5-711f4a9a08c9
# ╟─bc669799-3d13-4962-b790-b0ee48074036
# ╠═b02a89e3-6c28-48be-a5c1-44a6af2bdc72
# ╠═33b9bebe-9100-4509-b797-e7ad168ba9e9
# ╠═18001247-5da1-44ad-9609-d514f8a04c1c
# ╠═09201c31-e888-4bbf-8420-503d2450fbfb
# ╠═327d69de-6176-4b27-b444-40bbe2265d7e
# ╠═d49cdfe1-d6fe-4d2a-9b21-e93b0f5fff42
# ╠═231968b7-6ad5-4101-bfff-b5ebe04e5247
# ╠═7effef26-c80e-49b0-9fbf-599a16e43b9b
# ╠═695ff5ae-b7f0-4d81-b6e3-ac35a30bc45a
# ╠═328ee53c-6671-4e32-9a71-e881f8d82962
# ╠═60b4f309-767f-4e93-af23-0c5cd799efda
# ╠═4ea987bf-2447-4719-99a9-352d37f554bb
