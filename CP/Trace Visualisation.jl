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
	Pkg.activate("..")
	using Plots
	using Measures
	using PlutoUI
	using StatsBase
	using Unzip
	include("../FlatUI Colors.jl")
end

# ╔═╡ 3a57c06f-0adb-4f92-9f64-f22edbefcadf
TableOfContents(title="Fancy animation")

# ╔═╡ 3198dfc1-7571-4fd9-9fc6-35b6bc831bef
md"""
Create a fancy animation showing the levels and maybe even the consumption patterns from a trace of a chemical production plant.
"""

# ╔═╡ 1e159603-fc61-45f8-9595-f75e55318344
md"""
# Preamble
"""

# ╔═╡ a24231ca-1d55-4637-b3bc-bbbcb732ac04
html"""
<style>
pluto-editor {
	background-image: url("https://static.wikia.nocookie.net/half-life/images/f/f7/HL_BMRF_ResidueProcessing.jpg/revision/latest?cb=20100226160624&path-prefix=en");
}
pluto-notebook {
	background: none;
}
.foldcode, .add_cell, .runtime, .runcell {
	background: white;
	border-radius: 8pt;
}

.depends_on_disabled_cells {
	opacity:1.0;
	background: #fefefe;
}

pluto-output  {
	border-radius: 8pt 8pt 0pt 0pt;
	padding: 16pt;
	margin: 32pt 0 0 0;
	background: #eeeeee;
}

pluto-input .cm-editor {
	border-radius: 0 0 8pt 8pt;
	background: #dce4e8;
}

pluto-cell.code_differs .cm-editor .cm-gutters {
	background: #c8dcfa;
}
body:not(.___) pluto-cell > pluto-trafficlight {
	background: #aaaaaa;
	border-radius: 4pt;
	width: 7pt;
	margin: 6pt 0 6pt -4pt;
}

body:not(.___) pluto-cell.code_differs > pluto-trafficlight {
	background: #b4caed;
	border-left-color: #b4caed;
}

body:not(.___) pluto-cell.errored > pluto-trafficlight {
	background: #EC8B8B;
}

body:not(.___) pluto-cell:focus-within > pluto-trafficlight {
	background: #b4caed;
}

body:not(.___) pluto-cell.queued>pluto-trafficlight:after {
  animation-duration:30s;
  background:repeating-linear-gradient(-45deg,transparent,transparent 8px,var(--normal-cell-color) 8px,var(--normal-cell-color) 16px);
  background-clip:padding-box;
  background-size:4px var(--patternHeight);
  opacity:1.0;
}

body:not(.___) pluto-cell.running>pluto-trafficlight:after {
  background:repeating-linear-gradient(-45deg,var(--normal-cell-color),var(--normal-cell-color) 8px,var(--dark-normal-cell-color) 8px,var(--dark-normal-cell-color) 16px);
  background-clip:content-box;
  background-size:4px var(--patternHeight);
  opacity:1.0;
}

body:not(.___) pluto-cell.queued.errored>pluto-trafficlight:after,
body:not(.___) pluto-cell.running.errored>pluto-trafficlight:after {
  background:repeating-linear-gradient(-45deg,#EC8B8B,#EC8B8B 8px,#CF8A8A 8px,#CF8A8A 16px);
  background-clip:content-box;
  background-size:4px var(--patternHeight);
  opacity:1.0;
}

</style>

<p>🎨 Custom style sheet loaded.</p>
"""

# ╔═╡ 2b50bd80-1506-4ad3-abbe-589952fddf3c
← = push!

# ╔═╡ dbe445fe-8fa1-43af-8c18-561fe64f8a1f
⨝ = joinpath

# ╔═╡ b4ced136-b443-4d8f-8ec8-777d052a1710
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
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

# ╔═╡ 9be0a063-d016-4081-8c5d-dbff0e31de87
md"""
# Simulating the System

We are wanting to use `verifyta` to generate whole traces. This code is copy-pasta from the other `Trace Visualisation` notebook.
"""

# ╔═╡ d87a16d5-5cd6-4eb2-8029-f47e86b880c5
@bind working_dir TextField(80, default=mktempdir())

# ╔═╡ 41937a62-f9f9-414a-943d-f4f0f89763ce
md"""
Maybe you want to choose a mostly pre-trained model from the results folder for comparison.
"""

# ╔═╡ 07602a48-7ba8-400a-aacf-e187c4bc9ba4
md"""
## Model and Query
"""

# ╔═╡ 220da967-3034-4a98-9e20-bffd39a072a5
@bind model_file TextField(80, default=pwd() ⨝ "Plant.xml")

# ╔═╡ 55a118e3-a657-4e07-af8a-5ad60f0b509b
@bind query TextField((95, 18), default="""
	// strategy unit10 = loadStrategy {}->{t, stored[10]}
	("/home/asger/Results/N-player CP/20001 Runs/Repetition 1/Models/unit10.json")
	
	simulate[<=100;1] {
		U1.in, U1.r1, U1.r2, U1.r3,
		U2.in, U2.r1, U2.r2, U2.r3,
		U3.in, U3.r1, U3.r2, U3.r3,
		U4.in, U4.r1, U4.r2, U4.r3,
		U5.in, U5.r1, U5.r2, U5.r3,
		U6.in, U6.r1, U6.r2, U6.r3,
		U7.in, U7.r1, U7.r2, U7.r3,
		U8.in, U8.r1, U8.r2, U8.r3,
		U9.in, U9.r1, U9.r2, U9.r3,
		U10.in, U10.r1, U10.r2, U10.r3,
		stored[1], stored[2], stored[3],
		stored[4], stored[5], stored[6],
		stored[7], stored[8], stored[9], stored[10],
		provider_out[1], provider_out[2], provider_out[3],
		provider_out[4], provider_out[5], provider_out[6],
		provider_out[7], provider_out[8], provider_out[9], provider_out[10],
		unit_out[1], unit_out[2], unit_out[3],
		unit_out[4], unit_out[5], unit_out[6],
		unit_out[7], unit_out[8], unit_out[9], unit_out[10]
	}
	// under unit10
""")

# ╔═╡ 16faad42-0357-4fae-a075-333fbe1ee0b0
function remove_single_line_breaks(str)
	line_break_placeholder = "¤NEWLINE¤"
	str= replace(str, r"\n\s*\n" => line_break_placeholder)
	str = replace(str, r"\n\s*" => " ")
	str = replace(str, line_break_placeholder => "\n")
end

# ╔═╡ d8e542db-de75-4da8-a7c9-d4a8bf7910c0
query |> remove_single_line_breaks |> multiline

# ╔═╡ 162772c5-824e-4c84-b72c-6b60d4a569d4
query_file = let
	query_file = working_dir ⨝ "queries.q"
	write(query_file, remove_single_line_breaks(query))
	query_file
end

# ╔═╡ ee1a618a-b8ce-4768-a03f-092175eb018a
md"""
## Verifyta Call
"""

# ╔═╡ 628aa472-d15b-4534-81ef-08200830dcb5
@bind verifyta TextField(80, default=homedir() ⨝ "opt/uppaal-5.0.0-linux64/bin/verifyta")

# ╔═╡ 784fef9e-c40f-481f-a898-24bee6dfb109
if isfile(query_file) && isfile(model_file)
	output = Cmd([
		verifyta,
		"-s",
		model_file,
		query_file
	]) |> read |> String
end;

# ╔═╡ 41931c62-20b3-4efe-8e9e-929645d816d6
output[1:min(10000, length(output))] |> multiline

# ╔═╡ 0da1531a-81ec-49fb-8186-5295f0499c8b
md"""
# Reading Traces

Also copy-pasta but hopefully better organised.
"""

# ╔═╡ 636b5f6d-eb7e-4276-8594-db623f8fdef5
function parse_pair(str)
	left = match(r"\(([-0-9.e]+),", str)
	if isnothing(left) error("left side of pair not found in $str") end
	left = left[1]
	left = parse(Float64, left)
	right = match(r",([-0-9.e]+)\)", str)
	if isnothing(right) error("right side of pair not found in $str") end
	right = right[1]
	right = parse(Float64, right)
	(left, right)
end

# ╔═╡ 5f48e4e9-edbf-4cb0-af59-de97a1374b83
parse_pair("(0.002,50.102)")

# ╔═╡ f78f90e1-cf59-41a7-83ab-8b11552926cb
function parse_pairs(str)
	[parse_pair(s) for s in split(str, " ") if s != ""]
end

# ╔═╡ 748bf0b8-034f-4e7a-83be-0075bfc4eca5
parse_pairs(" (0,50) (0.02,50.0006) (0.04,50.002) (0.06,50.00419999999999)")

# ╔═╡ 507eb843-f485-4f87-8b41-ff7bbb31ef69
let
	keyword = "stored[1]"
	re_trace = Regex("\\Q$keyword\\E:\\n\\[0\\]:(?<values>.*)", "m")
	match(re_trace, output)
end

# ╔═╡ d52a8a89-273d-484d-9455-c1a219111f2a
function get_pairs_for_array(output::String, keyword::String)::Vector{Tuple{Float64, Float64}}
	re_trace = Regex("\\Q$keyword\\E:\\n\\[0\\]:(?<values>.*)", "m")
	m = match(re_trace, output)
	return parse_pairs(m[:values])
end

# ╔═╡ 89a68640-1b8f-454b-9007-1954c46795d8
pairs = get_pairs_for_array(output, "stored[1]")

# ╔═╡ a7c068df-8e5c-46c8-8827-92f3d2da3406
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

# ╔═╡ 39395cf3-9b5c-45db-aa47-9977ff281c80
value_at_time(pairs, 1.4)

# ╔═╡ adb15a71-ed9d-4a2a-8ee9-e9539561dff8
function at_regular_intervals(trace::T, interval::S) where T <: 
		AbstractVector{Tuple{Float64, Float64}} where S <: Number

	t_max = trace[end][1]
	return [ value_at_time(trace, i) for i in 0:interval:prevfloat(t_max) ]
end

# ╔═╡ 8c052cf6-cca3-427e-9239-283ef2fbb758
at_regular_intervals(pairs, 10)

# ╔═╡ a4e9d483-1cbb-406c-bf63-75016c25ceaa
function parse_trace(output, Δt, keywords...)
	result = Dict{String, Vector{Float64}}()
	
	for keyword in keywords
		trace = get_pairs_for_array(output, keyword)
		result[keyword] = at_regular_intervals(trace, Δt)
	end
	result
end

# ╔═╡ 8110e7dc-2a1c-43ba-81f3-83dd0f987ea5
begin
	# consts
	Δt = 0.5 # Decision period in the model.
	n_units = 10
	n_providers = 10
	rate = 2.65 # Approximate rate of flow through a single pipe.
	# Not included: Variance of flow rate in pipes.
end;

# ╔═╡ c165f2d1-f1c1-4eeb-bb24-5dcad0e1bc4a
keywords = let
	keywords = String[]
		
	for i in 1:n_units
		push!(keywords, "stored[$i]", "unit_out[$i]", "U$i.r1", "U$i.r2", "U$i.r3", "U$i.in")
	end
	
	for i in 1:n_providers
		push!(keywords, "provider_out[$i]")
	end
	keywords
end

# ╔═╡ bb40f696-8810-4ba6-a81c-add3d713fd3e
begin
	CCO = 0
	COC = 1
	OCC = 2
	CCC = 3
	OOC = 4
	COO = 5
	OCO = 6
	OOO = 7
	UNK = -1
end;

# ╔═╡ aba61fb1-82e7-4352-8128-2f35cdf64ead
# Okay, so this is some real fuck.
# Basically, the trace barely has enough information to determine 
# which pipes are open at any given time.
# I have to infer this from other values, which I'm doing here.
# Have a look at the model to figure out what's going on I guess.
# Even worse, this is not enough, because my layout is slightly inconsistent.
# So which action matches which pipes will be different for each unit,
# according to the system declaration.

function add_actions!(trace)
	trace_length = length(trace["U1.in"])
	for id in 1:n_units
		actions = []
		for i in 1:trace_length
			r1 = trace["U$id.r1"][i]
			r2 = trace["U$id.r2"][i]
			r3 = trace["U$id.r3"][i]
			inflow = trace["U$id.in"][i]
			if inflow == 0
				actions ← CCC
			elseif inflow ≈ rate + r1
				actions ← OCC
			elseif inflow ≈ rate + r2
				actions ← COC
			elseif inflow ≈ rate + r3
				actions ← CCO
			elseif inflow ≈ 2*rate + r1 + r2
				actions ← OOC
			elseif inflow ≈ 2*rate + r1 + r3
				actions ← OCO
			elseif inflow ≈ 2*rate + r2 + r3
				actions ← COO
			elseif inflow ≈ 3*rate + r1 + r2 + r3
				actions ← OOO
			else
				actions ← UNK
				@warn "Unmatched action. Unexpected values: $((;r1, r2, r3, inflow, rate))"
			end
		end
		trace["action[$id]"] = actions
	end
	trace
end

# ╔═╡ a27ae8e0-c411-4cb8-b844-98fe61a18a0e
begin
	trace = parse_trace(output, Δt, keywords...)
	add_actions!(trace)
end

# ╔═╡ d1fc7529-d474-48ea-9cbe-2fe17f3b8efe
trace["U4.in"]

# ╔═╡ cd1ca4c4-aa08-44e0-8d85-668936e93e92
max_time = length(trace["stored[1]"])*Δt - Δt

# ╔═╡ 6938d095-5d16-4652-a359-60d2e6e6fefe
struct CPState
	stored::Vector{Float64}
	action::Vector{Int64}
	unit_out::Vector{Int64}
	provider_out::Vector{Int64}
end

# ╔═╡ ce089bee-067b-422b-803f-51ad8c306cc1
begin
	struct CPTrace 
		states::Vector{CPState}
		times::Vector{Float64}
	end

	Base.copy(t::CPTrace) = CPTrace(copy(t.states), copy(t.times))
end

# ╔═╡ 80fbc8d8-01cb-4274-8392-f5abaddb7d71
function get_state(trace, t, Δt)
	j = Int(t/Δt)
	result = CPState([], [], [], [])
	for i in 1:n_units
		result.stored ← trace["stored[$i]"][j]
		result.action ← trace["action[$i]"][j]
		result.unit_out ← round(trace["unit_out[$i]"][j]/rate)
	end
	for i in 1:n_providers
		result.provider_out ← round(trace["provider_out[$i]"][j]/rate)
	end
	result
end

# ╔═╡ e5df2174-2335-419e-bbea-a8d4ae9093bc
get_state(trace, 10, Δt)

# ╔═╡ a13479e6-0485-4549-8d04-37c9b9b46546
function get_trace(trace, t_max)::CPTrace
	result = CPTrace([], [])
	for t in Δt:Δt:t_max
		result.times ← t
		result.states ← get_state(trace, t, Δt)
	end
	result
end

# ╔═╡ a3dc6755-524b-4060-8397-4073810dbd8c
findfirst(<(1), [4, 3, 2, 1, 0])

# ╔═╡ 6bcef4d0-4070-4154-a9ad-cf0f23c18065
function interpolate(trace::CPTrace, interpolated_time)
	trace = copy(trace)
	t_max = trace.times[end]
	result = CPTrace([], [])
	for time in interpolated_time:interpolated_time:t_max - interpolated_time
		j = findfirst(>(time), trace.times)
		i = j == 1 ? 1 : j - 1
		result.times ← time
		time_before = trace.times[i]
		time_after = trace.times[j]
		state_before = trace.states[i]
		state_after = trace.states[j]
		time_span = time_after - time_before
		if time_span == 0 # Happens if there is an exact match
			stored = state_after.stored
		else
			fraction = (time - time_before)/time_span
			stored = state_before.stored + 
				fraction*(state_after.stored - state_before.stored)
		end

		result.states ← CPState(stored, 
			state_after.action,
			state_after.unit_out, 
			state_after.provider_out,)
	end
	result
end

# ╔═╡ 5161853d-b0b8-4d40-8f5d-5de7d46ca75a
begin
	# Animation frames per second
	fps = 24
	time_multiplier = 1 # 0.5 = half speed, 1 = normal speed, etc.
end

# ╔═╡ 7fe68f14-a450-4442-99e6-4ac739eb1209
trace′ = let
	trace′ = get_trace(trace, max_time)
	trace′ = interpolate(trace′, 1/fps*time_multiplier)
end

# ╔═╡ 95ca91d5-f821-4417-beae-dfecc4dd49e4
md"""
# Visualising the Trace
So you can just plot the volumes, but we can do better!
"""

# ╔═╡ 14837142-42bc-4f06-9a20-9458171b9cee
let
	plot(
		xlabel="time (s)",
		ylabel="volume (ℓ)",
		legend=:outerright,
		size=(400, 300))
	
	for i in 1:n_units
		plot!(trace["stored[$i]"], label="stored[$i]")
	end
	plot!()
end

# ╔═╡ 96c6deeb-4e7e-41db-9eff-2bab2a67f3c8
md"""
## Drawing the Plant
"""

# ╔═╡ 903dc3c7-6974-4b37-af0d-9593f207c21b
abstract type ProductionPart end

# ╔═╡ d195d292-ff44-476a-a39b-feae659454a2
struct Unit <: ProductionPart
	id::Int64
	volume::Float64
end

# ╔═╡ e7fbfff7-c464-4109-8c57-491b229036f0
begin
	struct Pipe <: ProductionPart
		from::Int64
		to::Int64
		active::Bool
	end

	Pipe(from, to) = Pipe(from, to, false)
end

# ╔═╡ e96794c9-8ea4-4ad7-b90e-a951d2c1844a
begin
	struct Provider <: ProductionPart
		number::Int64 # is this the first or the second etc provider for this unit?
		to::Int64
		active::Bool
	end

	Provider(number, to) = Provider(number, to, false)
end

# ╔═╡ f4ab4bb3-691d-4f85-a487-5f112372b5c7
struct Consumer <: ProductionPart
	id::Int64 # Should start at 11 for corret positioning
	from::Int64
end

# ╔═╡ 472ccaf0-38ea-425d-b10c-c353cce757bb
const min_volume, max_volume = 0, 52

# ╔═╡ a1a2cba6-d6de-4803-bd1a-d586b083fc15
html"""
<img src="https://i.imgur.com/qZdiKOI.png" style="width:30%">
"""

# ╔═╡ 3f8d0161-15a1-4c3c-a3a5-100540af8858
# This includes consumers 1 and 2 who have IDs 11 and 12
function unit_position(id::Int64)
	# layout[3] is positioned as Unit 3 etc.
	# and then layout[11] to layout[15] are the consumers
	# which are drawn as 2 consumers, but actually have 6 pipes into them.
	layout = [
		(1, 5), (2, 5), (3, 5),
		  (1.5, 4), (2.5, 4),
		(1, 3), (2, 3), (3, 3),
		  (1.5, 2), (2.5, 2),
		  # And then the positions of the consumers 
		  (1.5, 1), (2.5, 1), 
		  # ...with space for 2 ingoing pipes
		  (1.4, 1), (1.6, 1), (2.4, 1), (2.6, 1),
	]
	
	layout[id] .* 30
end

# ╔═╡ 79906224-52e5-4703-9a7d-c91d6a1e66e6
unit_position(11)

# ╔═╡ f291493a-d0cc-47f8-bb6a-f2425b8db1b3
unit_width, unit_height = 10, 12

# ╔═╡ 09d11c56-e16c-404e-b430-93e249bec59e
function rectangle(x, y, size_x, size_y)
	xl, yl = (x, y)
	xu, yu = (x + size_x, y + size_y)
	Shape([xl, xl, xu, xu], [yl, yu, yu, yl])
end

# ╔═╡ 6dfb196c-a018-4340-9115-da5775f202dc
unit = (Unit(1, 25))

# ╔═╡ 355fe45c-2589-4691-8bbb-cc0bba132462
unit.volume/(max_volume - min_volume)

# ╔═╡ f23fdcb7-e1a6-4602-bb61-4ccb649f5a00
begin
	struct System <: ProductionPart
		units::Vector{Unit}
		pipes::Vector{Pipe}
		providers::Vector{Provider}
		consumers::Vector{Consumer}
	end
	
	function System(state::CPState)
		units = [Unit(i, state.stored[i]) for i in 1:10]

		a = state.action
		u = state.unit_out
		o = state.provider_out

		# Actions are OOO = Open-Open-Open, COC = Closed-Open-Open etc.
		# There isn't really any rhyme or reason in the 
		# UPPAAL model's system declaration as to which pipe is the 
		# left one, the middle one, or the rightmost one. 
		# For example, Unit4 sees Unit1 as being connected by its middle pipe.
		# While Unit8 sees Unit5 as being connected by its left pipe.
		# I just had to read all the positions manually.
		pipes = [
			Pipe(1, 4, a[4] ∈ (OOO, COC, OOC, COO)),
			Pipe(2, 4, a[4] ∈ (OOO, CCO, COO, OCO)),
			Pipe(2, 5, a[5] ∈ (OOO, OCC, OOC, OCO)),
			Pipe(3, 5, a[5] ∈ (OOO, COC, OOC, COO)),
			
			Pipe(4, 6, a[6] ∈ (OOO, CCO, COO, OCO)),
			Pipe(4, 7, a[7] ∈ (OOO, OCC, OOC, OCO)),
			Pipe(5, 7, a[7] ∈ (OOO, COC, OOC, COO)),
			Pipe(5, 8, a[8] ∈ (OOO, OCC, OOC, OCO)),
			
			Pipe(6, 9, a[9] ∈ (OOO, COC, OOC, COO)),
			Pipe(7, 9, a[9] ∈ (OOO, CCO, COO, OCO)),
			Pipe(7, 10, a[10] ∈ (OOO, OCC, OOC, OCO)),
			Pipe(8, 10, a[10] ∈ (OOO, COC, OOC, COO)),
			
			Pipe(9, 13, u[9] >= 1),
			Pipe(9, 14, u[9] >= 2),
			Pipe(10, 15, u[10] >= 1),
			Pipe(10, 16, u[10] >= 2)
		]

		# All units have at least one provider.
		# Units 1-3 have 3 providers each, while 6 and 8 have 2 each.
		providers = vcat(
			[Provider(1, i, o[i] > 0) for i in 1:10],
			[Provider(2, i, o[i] > 1) for i in [1, 2, 3, 6, 8]],
			[Provider(3, i, o[i] > 2) for i in 1:3])
		
		consumers = vcat([Consumer(11, 9), Consumer(12, 10)])
		
		System(units, pipes, providers, consumers)
	end
end

# ╔═╡ cfecbfd0-3afe-4292-922f-9be6ca45522b
begin
	function draw!(parts::AbstractArray{E}) where E<:ProductionPart
		p = nothing
		for part in parts
			p = draw!(part)
		end
		p
	end
	function draw!(parts::E...) where E<:ProductionPart
		p = nothing
		for part in parts
			p = draw!(part)
		end
		p
	end
	
	function draw!(unit::Unit)
		x, y = unit_position(unit.id)
		tank_level = unit_height*(unit.volume/(max_volume - min_volume))
		
		plot!(rectangle(x, y, unit_width, unit_height),
			color=nothing,
			line=(10, colors.WET_ASPHALT),
			label=nothing)
		
		plot!(rectangle(x, y, unit_width, unit_height),
			color=colors.ASBESTOS,
			line=0,
			label=nothing)
		
		plot!(rectangle(x, y, unit_width, tank_level),
			color=colors.EMERALD,
			line=0,
			label=nothing)
		
		annotate!((x + unit_width/2, y + unit_height/2, unit.id))
	end

	function draw!(pipe::Pipe)
		(x1, y1), (x2, y2) = unit_position(pipe.from), unit_position(pipe.to)
		x1 += unit_width/2
		x2 += unit_width/2
		y1 += unit_height/2
		y2 += unit_height/2
		
		p = plot!([(x1, y1), (x2, y2)],
			line=(5, colors.WET_ASPHALT),
			label=nothing)

		if pipe.active
			plot!([(x1, y1), (x2, y2)],
				line=(2, colors.EMERALD),
				label=nothing)
		end
		p
	end

	function draw!(provider::Provider)
		height = 8 - provider.number*4
		(x1, y1), (x2, y2) = unit_position(provider.to), unit_position(provider.to)
		x1 = x1 + unit_width/2 - 10
		x2 = x2 + unit_width/2
		y1 = y1 + unit_height/2 + height
		y2 = y2 + unit_height/2 + height
		
		p = plot!([(x1, y1), (x2, y2)],
			marker=(4, :circle, colors.EMERALD),
			markerstrokecolor=colors.WET_ASPHALT,
			markerstrokewidth=2,
			line=(5, colors.WET_ASPHALT),
			label=nothing)

		if provider.active
			plot!([(x1, y1), (x2, y2)],
				line=(2, colors.EMERALD),
				label=nothing)
		end
		p
	end

	function draw!(consumer::Consumer)
		x, y = unit_position(consumer.id)
		
		plot!(rectangle(x, y, unit_width, unit_height),
			color=nothing,
			line=nothing,
			label=nothing)
		
		x += unit_width/2
		y += unit_height/2
		
		scatter!([x], [y],
			marker=(unit_width*2, :circle, colors.EMERALD),
			markerstrokewidth=6,
			markerstrokecolor=colors.WET_ASPHALT,
			label=nothing,)
	end

	function draw!(system::System)
		draw!(system.pipes)
		draw!(system.providers)
		draw!(system.consumers)
		draw!(system.units)
	end
end

# ╔═╡ f4d139f0-62ba-4d3e-a261-7f2393f15c19
begin
	plot(aspectratio=:equal, size=(400, 400), ticks=nothing)
	draw!(System(trace′.states[30]))
end

# ╔═╡ af8b0dd5-46f3-472c-a902-9fc60db6e79f
md"""
## Animating!
"""

# ╔═╡ 3a9c8e25-a333-4899-831a-f2e6ff38d71d
function animate_trace(trace::CPTrace, fps)
	# + 1*fps == 1 second wait after animations ends.
	🎥 = @animate for i in 1:length(trace.times) + 1*fps 
		plot(aspectratio=:equal, size=(400, 400), ticks=nothing)
		if i <= length(trace.times)
			draw!(System(trace′.states[i]))
		end
	end

	gif(🎥; show_msg=false, fps)
end

# ╔═╡ 7fba5e3f-59f5-4943-9dd2-acf569ac31df
# Second argument is time between frames.
# Multiply by a value > 1 to make the animation appear slower.
animate_trace(trace′, fps)

# ╔═╡ 05a0f2a9-44a9-4182-b71d-0ecd39902675
[s.action for s in trace′.states]

# ╔═╡ Cell order:
# ╠═3a57c06f-0adb-4f92-9f64-f22edbefcadf
# ╟─3198dfc1-7571-4fd9-9fc6-35b6bc831bef
# ╟─1e159603-fc61-45f8-9595-f75e55318344
# ╠═c1bdc9f0-3d96-11ee-00af-b341a715281c
# ╟─a24231ca-1d55-4637-b3bc-bbbcb732ac04
# ╠═2b50bd80-1506-4ad3-abbe-589952fddf3c
# ╠═dbe445fe-8fa1-43af-8c18-561fe64f8a1f
# ╟─b4ced136-b443-4d8f-8ec8-777d052a1710
# ╟─14d4416b-ef73-4777-942e-f621c3ef801d
# ╟─9be0a063-d016-4081-8c5d-dbff0e31de87
# ╠═d87a16d5-5cd6-4eb2-8029-f47e86b880c5
# ╟─41937a62-f9f9-414a-943d-f4f0f89763ce
# ╟─07602a48-7ba8-400a-aacf-e187c4bc9ba4
# ╠═220da967-3034-4a98-9e20-bffd39a072a5
# ╟─55a118e3-a657-4e07-af8a-5ad60f0b509b
# ╠═16faad42-0357-4fae-a075-333fbe1ee0b0
# ╠═d8e542db-de75-4da8-a7c9-d4a8bf7910c0
# ╠═162772c5-824e-4c84-b72c-6b60d4a569d4
# ╟─ee1a618a-b8ce-4768-a03f-092175eb018a
# ╠═628aa472-d15b-4534-81ef-08200830dcb5
# ╠═784fef9e-c40f-481f-a898-24bee6dfb109
# ╠═41931c62-20b3-4efe-8e9e-929645d816d6
# ╟─0da1531a-81ec-49fb-8186-5295f0499c8b
# ╠═636b5f6d-eb7e-4276-8594-db623f8fdef5
# ╠═5f48e4e9-edbf-4cb0-af59-de97a1374b83
# ╠═f78f90e1-cf59-41a7-83ab-8b11552926cb
# ╠═748bf0b8-034f-4e7a-83be-0075bfc4eca5
# ╠═507eb843-f485-4f87-8b41-ff7bbb31ef69
# ╠═d52a8a89-273d-484d-9455-c1a219111f2a
# ╠═89a68640-1b8f-454b-9007-1954c46795d8
# ╠═a7c068df-8e5c-46c8-8827-92f3d2da3406
# ╠═39395cf3-9b5c-45db-aa47-9977ff281c80
# ╠═adb15a71-ed9d-4a2a-8ee9-e9539561dff8
# ╠═8c052cf6-cca3-427e-9239-283ef2fbb758
# ╠═a4e9d483-1cbb-406c-bf63-75016c25ceaa
# ╠═8110e7dc-2a1c-43ba-81f3-83dd0f987ea5
# ╠═c165f2d1-f1c1-4eeb-bb24-5dcad0e1bc4a
# ╠═a27ae8e0-c411-4cb8-b844-98fe61a18a0e
# ╠═d1fc7529-d474-48ea-9cbe-2fe17f3b8efe
# ╠═bb40f696-8810-4ba6-a81c-add3d713fd3e
# ╠═aba61fb1-82e7-4352-8128-2f35cdf64ead
# ╠═cd1ca4c4-aa08-44e0-8d85-668936e93e92
# ╠═6938d095-5d16-4652-a359-60d2e6e6fefe
# ╠═ce089bee-067b-422b-803f-51ad8c306cc1
# ╠═80fbc8d8-01cb-4274-8392-f5abaddb7d71
# ╠═e5df2174-2335-419e-bbea-a8d4ae9093bc
# ╠═a13479e6-0485-4549-8d04-37c9b9b46546
# ╠═a3dc6755-524b-4060-8397-4073810dbd8c
# ╠═6bcef4d0-4070-4154-a9ad-cf0f23c18065
# ╠═5161853d-b0b8-4d40-8f5d-5de7d46ca75a
# ╠═7fe68f14-a450-4442-99e6-4ac739eb1209
# ╟─95ca91d5-f821-4417-beae-dfecc4dd49e4
# ╟─14837142-42bc-4f06-9a20-9458171b9cee
# ╟─96c6deeb-4e7e-41db-9eff-2bab2a67f3c8
# ╠═903dc3c7-6974-4b37-af0d-9593f207c21b
# ╠═d195d292-ff44-476a-a39b-feae659454a2
# ╠═e7fbfff7-c464-4109-8c57-491b229036f0
# ╠═e96794c9-8ea4-4ad7-b90e-a951d2c1844a
# ╠═f4ab4bb3-691d-4f85-a487-5f112372b5c7
# ╠═472ccaf0-38ea-425d-b10c-c353cce757bb
# ╟─a1a2cba6-d6de-4803-bd1a-d586b083fc15
# ╠═3f8d0161-15a1-4c3c-a3a5-100540af8858
# ╠═79906224-52e5-4703-9a7d-c91d6a1e66e6
# ╠═f291493a-d0cc-47f8-bb6a-f2425b8db1b3
# ╠═cfecbfd0-3afe-4292-922f-9be6ca45522b
# ╠═09d11c56-e16c-404e-b430-93e249bec59e
# ╠═6dfb196c-a018-4340-9115-da5775f202dc
# ╠═355fe45c-2589-4691-8bbb-cc0bba132462
# ╠═f23fdcb7-e1a6-4602-bb61-4ccb649f5a00
# ╠═f4d139f0-62ba-4d3e-a261-7f2393f15c19
# ╟─af8b0dd5-46f3-472c-a902-9fc60db6e79f
# ╠═3a9c8e25-a333-4899-831a-f2e6ff38d71d
# ╠═7fba5e3f-59f5-4943-9dd2-acf569ac31df
# ╠═05a0f2a9-44a9-4182-b71d-0ecd39902675
