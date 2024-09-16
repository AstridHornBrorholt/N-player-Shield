### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# ╔═╡ d0db8070-41a9-11ee-2b97-818668d7efa8
begin
	using Pkg
	Pkg.activate("..")
	using CSV
	using DataFrames
	using Plots
	using Statistics
	using StatsPlots
	
	include("Results to CSV.jl")
	include("../FlatUI Colors.jl")
end;

# ╔═╡ 61c15d44-75be-4613-8b60-484d94847b8a
# ╠═╡ skip_as_script = true
#=╠═╡
begin
	using PlutoUI
end
  ╠═╡ =#

# ╔═╡ 7da0c88c-6353-4273-90d5-1cb414f1023b
# Hahah yea. So I have two notebooks that expose almost identical functions.
#But they are specific to different things. So this is my way of dealing with that.
module centralized_to_csv
	include("../CP Centralized Controller/Results to CSV.jl")
end

# ╔═╡ 2bd47b9e-31e3-4ee1-aa87-60dfc40869a9
html"""
<script>
// oneko.js: https://github.com/adryd325/oneko.js
 
(function oneko() {
  const nekoEl = document.createElement("div");
  let nekoPosX = 32;
  let nekoPosY = 32;
  let mousePosX = 0;
  let mousePosY = 0;
  const isReduced = window.matchMedia(`(prefers-reduced-motion: reduce)`) === true || window.matchMedia(`(prefers-reduced-motion: reduce)`).matches === true;
  if (isReduced) {
    return;
  }
 
  let frameCount = 0;
  let idleTime = 0;
  let idleAnimation = null;
  let idleAnimationFrame = 0;
  const nekoSpeed = 10;
  const spriteSets = {
    idle: [[-3, -3]],
    alert: [[-7, -3]],
    scratchSelf: [
      [-5, 0],
      [-6, 0],
      [-7, 0],
    ],
    scratchWallN: [
      [0, 0],
      [0, -1],
    ],
    scratchWallS: [
      [-7, -1],
      [-6, -2],
    ],
    scratchWallE: [
      [-2, -2],
      [-2, -3],
    ],
    scratchWallW: [
      [-4, 0],
      [-4, -1],
    ],
    tired: [[-3, -2]],
    sleeping: [
      [-2, 0],
      [-2, -1],
    ],
    N: [
      [-1, -2],
      [-1, -3],
    ],
    NE: [
      [0, -2],
      [0, -3],
    ],
    E: [
      [-3, 0],
      [-3, -1],
    ],
    SE: [
      [-5, -1],
      [-5, -2],
    ],
    S: [
      [-6, -3],
      [-7, -2],
    ],
    SW: [
      [-5, -3],
      [-6, -1],
    ],
    W: [
      [-4, -2],
      [-4, -3],
    ],
    NW: [
      [-1, 0],
      [-1, -1],
    ],
  };
 
  function create() {
    nekoEl.id = "oneko";
    nekoEl.style.width = "32px";
    nekoEl.style.height = "32px";
    nekoEl.style.position = "fixed";
    nekoEl.style.pointerEvents = "none";
    nekoEl.style.backgroundImage = "url('https://github.com/adryd325/oneko.js/blob/main/oneko.gif?raw=true')";
    nekoEl.style.imageRendering = "pixelated";
    nekoEl.style.left = `${nekoPosX - 16}px`;
    nekoEl.style.top = `${nekoPosY - 16}px`;

    nekoEl.style.zIndex = 99999;
 
    document.body.appendChild(nekoEl);
 
    document.addEventListener("mousemove",function(){
      mousePosX = event.clientX;
      mousePosY = event.clientY;
    });
 
    window.onekoInterval = setInterval(frame, 100);
  }
 
  function setSprite(name, frame) {
    const sprite = spriteSets[name][frame % spriteSets[name].length];
    nekoEl.style.backgroundPosition = `${sprite[0] * 32}px ${sprite[1] * 32}px`;
  }
 
  function resetIdleAnimation() {
    idleAnimation = null;
    idleAnimationFrame = 0;
  }
 
  function idle() {
    idleTime += 1;
 
    // every ~ 20 seconds
    if (
      idleTime > 10 &&
      Math.floor(Math.random() * 200) == 0 &&
      idleAnimation == null
    ) {
      let avalibleIdleAnimations = ["sleeping", "scratchSelf"];
      if (nekoPosX < 32) {
        avalibleIdleAnimations.push("scratchWallW");
      }
      if (nekoPosY < 32) {
        avalibleIdleAnimations.push("scratchWallN");
      }
      if (nekoPosX > window.innerWidth - 32) {
        avalibleIdleAnimations.push("scratchWallE");
      }
      if (nekoPosY > window.innerHeight - 32) {
        avalibleIdleAnimations.push("scratchWallS");
      }
      idleAnimation =
        avalibleIdleAnimations[
          Math.floor(Math.random() * avalibleIdleAnimations.length)
        ];
    }
 
    switch (idleAnimation) {
      case "sleeping":
        if (idleAnimationFrame < 8) {
          setSprite("tired", 0);
          break;
        }
        setSprite("sleeping", Math.floor(idleAnimationFrame / 4));
        if (idleAnimationFrame > 192) {
          resetIdleAnimation();
        }
        break;
      case "scratchWallN":
      case "scratchWallS":
      case "scratchWallE":
      case "scratchWallW":
      case "scratchSelf":
        setSprite(idleAnimation, idleAnimationFrame);
        if (idleAnimationFrame > 9) {
          resetIdleAnimation();
        }
        break;
      default:
        setSprite("idle", 0);
        return;
    }
    idleAnimationFrame += 1;
  }
 
  function frame() {
    frameCount += 1;
    const diffX = nekoPosX - mousePosX;
    const diffY = nekoPosY - mousePosY;
    const distance = Math.sqrt(diffX ** 2 + diffY ** 2);
 
    if (distance < nekoSpeed || distance < 48) {
      idle();
      return;
    }
 
    idleAnimation = null;
    idleAnimationFrame = 0;
 
    if (idleTime > 1) {
      setSprite("alert", 0);
      // count down after being alerted before moving
      idleTime = Math.min(idleTime, 7);
      idleTime -= 1;
      return;
    }
 
    let direction;
    direction = diffY / distance > 0.5 ? "N" : "";
    direction += diffY / distance < -0.5 ? "S" : "";
    direction += diffX / distance > 0.5 ? "W" : "";
    direction += diffX / distance < -0.5 ? "E" : "";
    setSprite(direction, frameCount);
 
    nekoPosX -= (diffX / distance) * nekoSpeed;
    nekoPosY -= (diffY / distance) * nekoSpeed;
 
    nekoPosX = Math.min(Math.max(16, nekoPosX), window.innerWidth - 16);
    nekoPosY = Math.min(Math.max(16, nekoPosY), window.innerHeight - 16);
 
    nekoEl.style.left = `${nekoPosX - 16}px`;
    nekoEl.style.top = `${nekoPosY - 16}px`;
  }
 
  create();
})();
</script>

<marquee> uwu Purr eow mrow purr purr uwu owo meow purr owo uwu meow purr purr owo mrow uwu uwu meow purr mrow mew owo uwu owo uwu mrow mew purr owo uwu puirr mrow meow mew mmmeoww purr uwu owo mrow meow mew ow purr hsss *scratches you* mrow meow purr uwu purr uwu owo mrow mew ow purr meow uwu </marquee>
"""; "🐈"

# ╔═╡ c9e1bc2c-a6f7-4b88-8038-51cf2ef2a008
html"""
<style>
pluto-editor {
	background-image: url("https://www.freevector.com/uploads/vector/preview/30278/Red_Flower_Pattern.jpg");
}
pluto-notebook {
	background: none;
}

pluto-output  {
	border-radius: 4pt;
	padding: 4pt;
}

pluto-input .cm-editor {
	background: #fafafafa;
}

pluto-cell.code_differs .cm-editor .cm-gutters {
	background: #c8dcfa;
}

body:not(.___) pluto-cell.code_differs > pluto-trafficlight {
	background: #b4caed;
	border-left-color: #b4caed;
}

body:not(.___) pluto-cell.errored > pluto-trafficlight {
	background: #ffa18a;
}

body:not(.___) pluto-cell:focus-within > pluto-trafficlight {
	background: #b4caed;
}
</style>

<p>🎨 Custom style sheet loaded.</p>
"""

# ╔═╡ 4362212e-0f0e-4425-bfb1-a6c3808ed808
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

# ╔═╡ 95e38fbd-142d-4926-9291-27e69ddf7c75
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

# ╔═╡ 4b3789f9-759d-405b-a369-fb50a4a5a42a
#=╠═╡
TableOfContents(title="Chemical Production Plots")
  ╠═╡ =#

# ╔═╡ 15f0808f-8424-4d27-9247-274c7751bf8e
Plots.default(fontfamily="serif-roman") 

# ╔═╡ 26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
← = push!

# ╔═╡ ce5168ba-17e5-4d70-84b9-e396aaf9f9bf
⨝ = joinpath

# ╔═╡ 193a3fb9-92c9-4ac2-8f41-2a2e4540486f
md"""
# The Main Plot

This is the performance vs training time plot.
"""

# ╔═╡ d7848c71-86c8-4f1b-b8dd-49b9158e627e
md"""
!!! info "Cost? Performance?"
	Costs are the raw values extracted from the queries. Reward is individual to agents, and is just negative cost.
	Performance is the metric for the global system, and is mean negative cost. 
"""

# ╔═╡ a04f12e3-479b-4312-b531-66d12c59e911
const n_agents = 10

# ╔═╡ c644df51-eef9-4c39-9ca9-d7a971d07e70
function local_reward(cost)
	-cost
end

# ╔═╡ 01af1a0e-8806-40c6-9c8f-a3391368072d
function global_performance(sum_of_costs)
	# Queries compute sum of costs for historical reasons, so we divide by number of agents to get mean.
	-sum_of_costs/n_agents
end

# ╔═╡ 802bb5e1-f2e1-4788-abcb-c1716683693e
function plot_results!(;runs, performance)
	plot!(runs, performance)
end

# ╔═╡ 10dc113e-aaa0-46f8-80ef-c345d52d5eec
#=╠═╡
md"""
`distributed =` $(@bind distributed TextField(70, 
	default=homedir()⨝"Results/N-player CP Non-specialized"))

`cascading =` $(@bind cascading TextField(70, 
	default=homedir()⨝"Results/N-player CP"))

`centralized =` $(@bind centralized TextField(70, 
	default=homedir()⨝"Results/N-player CP Centralized Controller"))
"""
  ╠═╡ =#

# ╔═╡ 60a6c2c5-e5af-4b33-9976-9054b51814d1
md"""
# Detailed Plots

A bunch of other plots which were made to explore the data.
"""

# ╔═╡ 1f3a2bee-2817-4314-901e-7dd3743fbab9
#=╠═╡
@bind results_dir TextField(80, default=homedir() ⨝ "Results/N-player CP")
  ╠═╡ =#

# ╔═╡ db1720fb-1134-4d81-b0b0-7da700d38798
# String to vector
function to_vector(str::T, element_type=Float64) where T<:AbstractString
	🐟 = match(r"\[(.*)\]", str)[1]
	if 🐟 == ""
		return []
	else
		🎣 = split(🐟, ", ")
	 	return [parse(element_type, 🍣) for 🍣 in 🎣]
	end
end

# ╔═╡ be64568d-f451-46f4-8336-bd94fff82471
to_vector("[3377.35, 2655.58, 2868.0, 2781.98]")

# ╔═╡ 85871e02-b379-4306-a547-1d6239e61fc2
function elementwise_mean(vec)
	result = []
	length(vec) > 0 || return result |> string
	for (i, _) in enumerate(vec[1])
		result ← mean([v[i] for v in vec])
	end
	result |> string
end

# ╔═╡ 5d35a941-ea93-45ed-b309-98db9ad9fc47
#=╠═╡
@bind refresh_button CounterButton("Refresh")
  ╠═╡ =#

# ╔═╡ 62086f17-badc-4ec9-a5e8-25ebb0f6cdc8
#=╠═╡
refresh_button; csv_string = to_csv(results_dir)
  ╠═╡ =#

# ╔═╡ e1ddadeb-e9fd-4c37-a206-dff03363724e
#=╠═╡
csv_string |> multiline
  ╠═╡ =#

# ╔═╡ 7cd7f277-8388-413a-b993-9b81fdb495b8
#=╠═╡
raw_results = CSV.read(IOBuffer(csv_string), DataFrame)
  ╠═╡ =#

# ╔═╡ 1f973cbe-a416-44fa-8e3b-e6392f6ddb16
#=╠═╡
# Discard all experiment repetitions except the first
# Essentially avoids taking the mean of the data
# and just shows result for single run.
@bind only_first_repetition CheckBox(default=false)
  ╠═╡ =#

# ╔═╡ 5484bf48-11be-4ac7-9557-e6fa36802f1d
#=╠═╡
cleandata = let
	cleandata = raw_results
	
	if only_first_repetition
		cleandata = filter(:repetition => (x -> x == 1), cleandata)
	end
	
	episode_length = 100
	
	cleandata = transform(cleandata, 
		:trained_global_cost => ByRow(global_performance) => :global_performance,
		:trained_individual_cost => ByRow(local_reward) => :individual_reward,
		:pre_trained_units => ByRow(p -> p + 1) => :trained_units,
	)
	
	cleandata
end
  ╠═╡ =#

# ╔═╡ 02859499-80f9-413d-9488-fcba9728031a
#=╠═╡
all_runs = cleandata[!, :runs] |> unique |> sort
  ╠═╡ =#

# ╔═╡ b9e07438-ea07-4b89-a983-378b706a695b
#=╠═╡
@bind runs_shown MultiSelect(all_runs, default=[r for r in all_runs if r <= 2000])
  ╠═╡ =#

# ╔═╡ 782b14e8-a0d4-4584-9082-dded2699b70a
#=╠═╡
# Extract just mean performance as a function of the number of runs.
function runs_performance(result_dir)
	
	buf = IOBuffer(to_csv(result_dir))
	df = CSV.read(buf, DataFrame, delim=";")
	df = filter(:pre_trained_units => (==)(n_agents - 1), df)
	df = filter(:runs => r -> r ∈ runs_shown, df)

	grouping =  groupby(df, [:runs])
	
	df = combine(grouping, 
		:trained_global_cost => mean,
		renamecols=false)

	df = sort(df, :runs)

	return (runs=[(r) for r  in df.runs], 
	performance=[global_performance(p) for p in df.trained_global_cost])
end
  ╠═╡ =#

# ╔═╡ b7d13d00-1b8e-4875-affe-9756ee74ea7f
#=╠═╡
runs_performance(cascading)
  ╠═╡ =#

# ╔═╡ ea282e41-f786-4c5c-b2e6-e42826949516
#=╠═╡
# Yea and for centralized control the format is completely different.
function centralized_runs_performance(result_dir)
	
	buf = IOBuffer(centralized_to_csv.to_csv(result_dir))
	df = CSV.read(buf, DataFrame, delim=";")
	df = filter(:runs => r -> r ∈ runs_shown, df)

	grouping =  groupby(df, [:runs])
	
	df = combine(grouping, 
		:trained_performance => mean,
		renamecols=false)

	df = sort(df, :runs)

	return (runs=[r for r  in df.runs],  
	performance=[global_performance(p) for p in df.trained_performance])
end
  ╠═╡ =#

# ╔═╡ afe6e072-a335-4e72-a1d4-389ebd624493
#=╠═╡
centralized_runs_performance(centralized)
  ╠═╡ =#

# ╔═╡ 5160269e-c0fe-4643-bbaf-9094bb4bd537
#=╠═╡
function do_the_plot_of_the_results(;distributed, 
		cascading, 
		centralized)


	#distributed = runs_performance(distributed)
	cascading = runs_performance(cascading)
	centralized = centralized_runs_performance(centralized)

	
	all_performances = [#distributed.performance..., 	
		cascading.performance..., centralized.performance...]

	ylims = (min(all_performances...) - 10, max(all_performances...) + 50)

	stylings = (linewidth=2,
		markerstrokewidth=2,
		markerstrokecolor=:white)
	
	plot(;size=(350, 250),
		ylims,
		legend=:bottomright,
		xlabel="Total episodes trained",
		ylabel="Performance")
	
	#plot!(distributed.runs, distributed.performance;
	#	label="Distributed",
	#	color=colors.PETER_RIVER,
	#	marker=(:diamond, 6),
	#	stylings...)
	
	plot!(cascading.runs, cascading.performance;
		label="Cascading",
		color=colors.NEPHRITIS,
		marker=(:rtriangle, 9),
		stylings...)
	
	plot!(centralized.runs, centralized.performance;
		label="Centralized",
		color=colors.AMETHYST,
		marker=(:circle, 6),
		stylings...)
	
	
end
  ╠═╡ =#

# ╔═╡ de90ff81-dace-447e-8d0c-7573536d64a0
#=╠═╡
do_the_plot_of_the_results(;distributed, cascading, centralized)
  ╠═╡ =#

# ╔═╡ a675d6b9-0f2b-4023-af2a-1bb43303f6a7
#=╠═╡
means = let
	grouping =  groupby(cleandata, [:runs, :trained_units])
	
	means = combine(grouping, 
		:untrained_global_cost => mean, 
		:trained_global_cost => mean, 
		:trained_individual_cost => mean,
		:untrained_individual_cost => mean,
		:individual_reward => mean,
		:global_performance => mean,
		renamecols=false)
end
  ╠═╡ =#

# ╔═╡ 85625fdb-5ad9-4021-a601-1d50c420902a
md"""
## Reward Plot
"""

# ╔═╡ e4d4e047-c252-4d2f-b48d-29e4e6266012
#=╠═╡
max_trained_units = max(cleandata[!, :trained_units]...)
  ╠═╡ =#

# ╔═╡ 734ffc56-5fac-4ede-b0d4-b2a9ecde09aa
#=╠═╡
default_y_min, default_y_max = let
	df = filter(:trained_units => t -> t == max_trained_units, means)
	
	default_y_min = min(df[!, :global_performance]...) - 100
	
	default_y_max = max(df[!, :global_performance]...) + 100
	
	default_y_min, default_y_max
end
  ╠═╡ =#

# ╔═╡ 64921a92-ce9a-4a79-9349-445c8eb4fe15
#=╠═╡
md"""
`y_min` = $(@bind y_min NumberField(-100000.:1.:100000., default=default_y_min))

`y_max` = $(@bind y_max NumberField(-100000.:1.:100000., default=default_y_max))
"""
  ╠═╡ =#

# ╔═╡ 2b5eb5be-3e34-4eca-84c9-18a32aacdfab
#=╠═╡
ylims = (y_min, y_max)
  ╠═╡ =#

# ╔═╡ b1090c8e-9f46-429a-93a7-42cedba24188
#=╠═╡
md"""
`width` = $(@bind width NumberField(0:10:typemax(Int64), default=350))

`height` = $(@bind height NumberField(0:10:typemax(Int64), default=250))
"""
  ╠═╡ =#

# ╔═╡ 8ff26541-30b4-42bb-85a0-1d08e1c8d2aa
#=╠═╡
size = (width, height)
  ╠═╡ =#

# ╔═╡ 7909f497-55cd-4f9d-b34d-515a80241873
md"""
## Individual performance
"""

# ╔═╡ 2cc917ff-7098-4c32-a1f8-e75360c37e2c
begin
	function individual_performance_plot!(means::DataFrame, 
			runs;
			color=colors.POMEGRANATE,
			label=nothing,
			plotargs...)
		
		df = filter(:runs => (x -> x == runs), means)
		trained_unit_counts = df[!, :trained_units]
		df = sort(df, :trained_units)
		trained_min = min(trained_unit_counts...)
		trained_max = max(trained_unit_counts...)
		
		xticks = (collect(trained_min:trained_max), ["$(n_agents - x + 1)" for x in 1:trained_max])
		xlims = (trained_min - 1, trained_max + 1)
		
		marker = (markercolor=color, markershape=:circle, markersize=3, markerstrokecolor=:white)
		
		@df df plot!(:trained_units, :individual_reward;
			color=color,
			linewidth=2,
			xticks,
			xlims,
			xlabel="Unit ID",
			ylabel="Individual Reward",
			label=something(label, "Trained for $runs runs each"),
			#marker...,
			plotargs...)
	end
	function individual_performance_plot(x...; plotargs...)
		plot(;plotargs...)
		individual_performance_plot!(x...)
	end
end

# ╔═╡ 37e95259-e575-45c3-a0a3-4b0115c12694
#=╠═╡
unique_runs = means[!, :runs] |> unique |> sort
  ╠═╡ =#

# ╔═╡ 48cdb277-800b-4f12-bf20-5a7d48af5fff
#=╠═╡
@bind runs Select(unique_runs)
  ╠═╡ =#

# ╔═╡ 8a8ad7a8-94cb-4f94-9e78-7684091272c8
#=╠═╡
@info "Repetitions found: $(nrow(filter(:pre_trained_units => (x -> x == 1), filter(:runs => (x -> x == runs), cleandata))))"
  ╠═╡ =#

# ╔═╡ 65b36dde-10b2-448b-8367-027a5b072d50
#=╠═╡
filter(:runs => (x -> x == runs), 
			means)
  ╠═╡ =#

# ╔═╡ 109601c9-4c25-4b39-b059-47c2255c9159
#=╠═╡
let 
	readme = results_dir ⨝ "$runs Runs" ⨝ "readme.txt"
	if isfile(readme)
		md"""
		!!! info "`Readme` found"
		
		at $(readme)
		
		$(readme |> read |> String |> multiline)
		"""
	else
		md"""No readme found.
		
		If there is a file `readme.txt` in the Runs folder, it will be displayed here."""
	end
end
  ╠═╡ =#

# ╔═╡ 46892975-b58b-4d27-87a5-83dc5ab23965
#=╠═╡
@bind selected_runs MultiSelect(unique_runs, 
		default=[r for r in unique_runs if (r > 1000 && r%100==0)])
  ╠═╡ =#

# ╔═╡ 275f6004-3c83-4ffd-b5da-1425edd99dce
#=╠═╡
let
	df = sort(means, :runs)
	df = filter(:trained_units => t -> t == max_trained_units, df)
	df = filter(:runs => r -> r ∈ selected_runs, df)
	#df = transform(df, :runs => ByRow(r -> "$r"), renamecols=false)
	@df df plot(:runs, :global_performance;
		size,
		ylims,
		color=colors.POMEGRANATE,
		marker=:square,
		markerstrokewidth=0,
		label=nothing,
		xlabel="Episodes per unit",
		ylabel="Total reward")
end
  ╠═╡ =#

# ╔═╡ dc0bf1be-f6a5-4c76-b62d-7fdf234cd601
#=╠═╡
filter((x -> x[:runs] ∈ selected_runs), means)
  ╠═╡ =#

# ╔═╡ f00c8154-36be-495e-b681-fd3c24f97561
#=╠═╡
let
	df = filter((x -> x[:runs] ∈ selected_runs), means)
	
	plot(legend=:outerright,
		size=(800, 400))

	c = [colors.POMEGRANATE, colors.BELIZE_HOLE, colors.GREEN_SEA, colors.CARROT, colors.WISTERIA, colors.EMERALD, colors.SUNFLOWER, colors.PETER_RIVER]
	
	strokes = [:dashdot, :dash, :dot, :solid, ]
	
	for (i, r) in enumerate(selected_runs)
		individual_performance_plot!(means, r, 
			color=c[1 + (i - 1)%length(c)],
			line=strokes[1 + (i - 1)%length(strokes)],
			markerstrokecolor=:white)
	end
	plot!()
end
  ╠═╡ =#

# ╔═╡ 3c202730-71e2-4cf6-b334-b30a8dfc14a5
#=╠═╡
filter((x -> x[:runs] ∈ selected_runs && x[:trained_units] == 10), means)
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═d0db8070-41a9-11ee-2b97-818668d7efa8
# ╠═7da0c88c-6353-4273-90d5-1cb414f1023b
# ╟─2bd47b9e-31e3-4ee1-aa87-60dfc40869a9
# ╟─c9e1bc2c-a6f7-4b88-8038-51cf2ef2a008
# ╟─4362212e-0f0e-4425-bfb1-a6c3808ed808
# ╟─95e38fbd-142d-4926-9291-27e69ddf7c75
# ╠═61c15d44-75be-4613-8b60-484d94847b8a
# ╠═4b3789f9-759d-405b-a369-fb50a4a5a42a
# ╠═15f0808f-8424-4d27-9247-274c7751bf8e
# ╠═26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
# ╠═ce5168ba-17e5-4d70-84b9-e396aaf9f9bf
# ╟─193a3fb9-92c9-4ac2-8f41-2a2e4540486f
# ╠═d7848c71-86c8-4f1b-b8dd-49b9158e627e
# ╠═a04f12e3-479b-4312-b531-66d12c59e911
# ╠═c644df51-eef9-4c39-9ca9-d7a971d07e70
# ╠═01af1a0e-8806-40c6-9c8f-a3391368072d
# ╠═782b14e8-a0d4-4584-9082-dded2699b70a
# ╠═b7d13d00-1b8e-4875-affe-9756ee74ea7f
# ╠═ea282e41-f786-4c5c-b2e6-e42826949516
# ╠═afe6e072-a335-4e72-a1d4-389ebd624493
# ╠═802bb5e1-f2e1-4788-abcb-c1716683693e
# ╟─10dc113e-aaa0-46f8-80ef-c345d52d5eec
# ╠═02859499-80f9-413d-9488-fcba9728031a
# ╠═b9e07438-ea07-4b89-a983-378b706a695b
# ╠═5160269e-c0fe-4643-bbaf-9094bb4bd537
# ╠═de90ff81-dace-447e-8d0c-7573536d64a0
# ╟─60a6c2c5-e5af-4b33-9976-9054b51814d1
# ╠═1f3a2bee-2817-4314-901e-7dd3743fbab9
# ╠═62086f17-badc-4ec9-a5e8-25ebb0f6cdc8
# ╠═e1ddadeb-e9fd-4c37-a206-dff03363724e
# ╠═7cd7f277-8388-413a-b993-9b81fdb495b8
# ╠═db1720fb-1134-4d81-b0b0-7da700d38798
# ╠═be64568d-f451-46f4-8336-bd94fff82471
# ╠═5484bf48-11be-4ac7-9557-e6fa36802f1d
# ╠═85871e02-b379-4306-a547-1d6239e61fc2
# ╠═a675d6b9-0f2b-4023-af2a-1bb43303f6a7
# ╠═8a8ad7a8-94cb-4f94-9e78-7684091272c8
# ╠═65b36dde-10b2-448b-8367-027a5b072d50
# ╠═5d35a941-ea93-45ed-b309-98db9ad9fc47
# ╠═48cdb277-800b-4f12-bf20-5a7d48af5fff
# ╟─109601c9-4c25-4b39-b059-47c2255c9159
# ╠═1f973cbe-a416-44fa-8e3b-e6392f6ddb16
# ╟─85625fdb-5ad9-4021-a601-1d50c420902a
# ╠═e4d4e047-c252-4d2f-b48d-29e4e6266012
# ╠═734ffc56-5fac-4ede-b0d4-b2a9ecde09aa
# ╟─64921a92-ce9a-4a79-9349-445c8eb4fe15
# ╟─2b5eb5be-3e34-4eca-84c9-18a32aacdfab
# ╟─b1090c8e-9f46-429a-93a7-42cedba24188
# ╠═8ff26541-30b4-42bb-85a0-1d08e1c8d2aa
# ╠═46892975-b58b-4d27-87a5-83dc5ab23965
# ╠═275f6004-3c83-4ffd-b5da-1425edd99dce
# ╟─7909f497-55cd-4f9d-b34d-515a80241873
# ╠═2cc917ff-7098-4c32-a1f8-e75360c37e2c
# ╠═37e95259-e575-45c3-a0a3-4b0115c12694
# ╠═dc0bf1be-f6a5-4c76-b62d-7fdf234cd601
# ╠═f00c8154-36be-495e-b681-fd3c24f97561
# ╠═3c202730-71e2-4cf6-b334-b30a8dfc14a5
