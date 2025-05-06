### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ d0db8070-41a9-11ee-2b97-818668d7efa8
begin
	using Pkg
	Pkg.activate("..", io=devnull)
	using CSV
	using DataFrames
	using Plots
	using Statistics
	using StatsPlots
	using Measures
	using Printf
	using Unzip
end;

# ╔═╡ 61c15d44-75be-4613-8b60-484d94847b8a
# ╠═╡ skip_as_script = true
#=╠═╡
begin
	using PlutoUI
	include("Results to CSV.jl")
	include("../FlatUI Colors.jl")
end
  ╠═╡ =#

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
	background-image: url("https://i.kym-cdn.com/photos/images/original/000/511/922/ea9.jpg");
	background-size: 270pt;
}
pluto-notebook {
	background: none;
}

pluto-output  {
	border-radius: 4pt 4pt 0 0;
	padding: 4pt;
	background: #efefefc0;
	backdrop-filter: blur(5px)brightness(150%)grayscale(60%);
}

pluto-input .cm-editor {
	background: #efefefc0;
	backdrop-filter: blur(15px)brightness(180%)grayscale(60%);
}

pluto-logs-container {
	margin-right: 0;
	background: #efefefc0;
	backdrop-filter: blur(15px)brightness(180%)grayscale(60%);
}

table.pluto-table .schema-names th,
table.pluto-table tbody th:first-child{
	background: none;
}

pluto-cell.code_differs .cm-editor .cm-gutters {
	background: #c8dcfa;
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
  opacity:.99
}

body:not(.___) pluto-cell.running>pluto-trafficlight:after {
  background:repeating-linear-gradient(-45deg,var(--normal-cell-color),var(--normal-cell-color) 8px,var(--dark-normal-cell-color) 8px,var(--dark-normal-cell-color) 16px);
  background-clip:content-box;
  background-size:4px var(--patternHeight);
  opacity:.99
}

body:not(.___) pluto-cell.queued.errored>pluto-trafficlight:after,
body:not(.___) pluto-cell.running.errored>pluto-trafficlight:after {
  background:repeating-linear-gradient(-45deg,#EC8B8B,#EC8B8B 8px,#CF8A8A 8px,#CF8A8A 16px);
  background-clip:content-box;
  background-size:4px var(--patternHeight);
  opacity:.99
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

# ╔═╡ cd4fb0d2-d1b6-4301-97e4-9ddb3505e061
#=╠═╡
TableOfContents(title="Cruise-control Plots")
  ╠═╡ =#

# ╔═╡ 15f0808f-8424-4d27-9247-274c7751bf8e
Plots.default(fontfamily="serif-roman") 

# ╔═╡ 26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
← = push!

# ╔═╡ ce5168ba-17e5-4d70-84b9-e396aaf9f9bf
⨝ = joinpath

# ╔═╡ 24f1af15-c323-4407-92ca-b55cc14263de
md"""
## The Raw Data
"""

# ╔═╡ 9b4d6b4d-d958-480b-af15-d07a4dc4b8ca
#=╠═╡
md"""
`cascading_path =` $(@bind cascading_path TextField(70, 
	default=homedir()⨝"Results/N-player CC"))

`centralized_path =` $(@bind centralized_path TextField(70, 
	default=homedir()⨝"Results/N-player CC Centralized Controller"))

`mappo_path =` $(@bind mappo_path TextField(70, 
	default=homedir()⨝"Results/N-player CC MAPPO"))

`random_shielded_path =` $(@bind random_shielded_path TextField(70, 
	default=homedir()⨝"Results/N-player CC Random Shielded"))
"""
  ╠═╡ =#

# ╔═╡ 10ca302d-f5f3-4e66-877f-1974138235f5
function read_csv(path)
	buf = IOBuffer(to_csv(path))
	df = CSV.read(buf, DataFrame, delim=";")
end

# ╔═╡ f467cbb0-ac89-462a-86b2-55e4d3580ee6
#=╠═╡
cascading_raw = read_csv(cascading_path)
  ╠═╡ =#

# ╔═╡ 0a71b644-8499-46f9-9614-c65baf23957e
#=╠═╡
centralized_raw = read_csv(centralized_path)
  ╠═╡ =#

# ╔═╡ ec3df7e5-80d3-4bc7-8dda-54551ee1936c
#=╠═╡
all_runs = (vcat(cascading_raw[!, :runs], centralized_raw[!, :runs]) 
	|> unique |> sort)
  ╠═╡ =#

# ╔═╡ 47f85802-4082-40d6-9854-8ded4441d1e4
#=╠═╡
mappo = CSV.read(mappo_path ⨝ "Exported Results.csv", DataFrame)
  ╠═╡ =#

# ╔═╡ 6698877b-632c-4049-949f-9d7ea0465d23
#=╠═╡
random_shielded_exported_results = random_shielded_path ⨝ "Exported Results.txt"
  ╠═╡ =#

# ╔═╡ b9adeac6-5a91-4c69-b1b1-4b1931c23840
#=╠═╡
random_baseline = parse(Float64, 
	random_shielded_exported_results |> read |> String)
  ╠═╡ =#

# ╔═╡ 572cade9-c131-4206-b79d-e1ee118f230b
#=╠═╡
@bind first_repetition_only CheckBox(default=false)
  ╠═╡ =#

# ╔═╡ abb7365c-1d40-4f92-9664-e005117b5c00
md"""
!!! info "Cost?"
	We're back to reporting sum of costs in our figures. Pretty simple. Maybe I'll use `global_cost` and `sum_of_costs` interchangably, idk.
"""

# ╔═╡ a2256c72-3686-4f89-9adf-6684270946b6
const episode_length = 100

# ╔═╡ 2655802d-f3b9-4850-8164-81a860ca5716
function append(a, b::V) where {V<:AbstractVector}
	vcat(b, a)
end

# ╔═╡ 12e5d573-610c-4c9e-a555-237f1fd983b4
append(5, [1, 2, 3, 4])

# ╔═╡ ef5c1d6e-9046-4da7-bfd1-2a12832d0e7d
md"""
# The Main Plot

This is the performance vs training time plot.
"""

# ╔═╡ ae5337da-bd26-4229-a72c-0602bc68f774
function get_ribbon(mins, means, maxes)
	lower = means .- mins
	upper = maxes .- means
	lower, upper
end

# ╔═╡ 712fde99-ce98-48df-a487-f78bd2a7f4fd
#=╠═╡
random_baseline
  ╠═╡ =#

# ╔═╡ 3f9a588d-6e0c-4bd4-a123-447c313703cc
#=╠═╡
minimum(mappo.min_cost)
  ╠═╡ =#

# ╔═╡ f5561b0b-f16f-454f-bdc5-cbf3b93ecf91
function do_the_plot_of_the_results(;
		cascading, 
		centralized,
		random_baseline,
		mappo)
	
	all_costs = vcat(cascading.min_cost, 
		centralized.min_cost,
		cascading.max_cost, 
		centralized.max_cost)

	
	ymin, ymax = min(all_costs...), max(all_costs...)
	ylims = (ymin - abs(ymin)*0.25, ymax + abs(ymax)*0.25)
	ylims = (0, 200000)

	yticks = [(y, @sprintf("%.f", y)) for y in LinRange(ylims[1], ylims[2], 5)] |> unzip

	xmin, xmax = minimum(centralized.runs), maximum(centralized.runs)
	xticks = [(x, @sprintf("%.f", x)) for x in LinRange(0, xmax, 4)] |> unzip

	# Global styles #
	plot(;size=(400, 200),
		bottommargin=1mm,
		rightmargin=3mm,
		legend=(0.1, 0.95),
		legend_columns=2,
		ylims,
		yrot=45,
		xticks,
		yticks,
		xlabel="Total episodes trained",
		ylabel="Cost")
	

	# Actual data plotting #
	# I want the legends to be in another order, hence the X_stylings variables.
	mappo_stylings = (linewidth=2,
		label="MAPPO", 
		color=colors.PETER_RIVER,)
	
	plot!(mappo.episodes, mappo.mean_cost;
		ribbon=get_ribbon(mappo.min_cost, mappo.mean_cost, mappo.max_cost),
		mappo_stylings...,
		label=nothing,)
	
	centralized_stylings = (linewidth=2,
		label="Centralized learning",
		color=colors.AMETHYST,)
	
	plot!(centralized.runs, centralized.mean_cost;
		ribbon=get_ribbon(centralized.min_cost, centralized.mean_cost, centralized.max_cost),
		#marker=(:circle, 6),
		centralized_stylings...,
		label=nothing)

	cascading_stylings = (linewidth=2,
		label="Cascading learning",
		color=colors.NEPHRITIS,)
	
	plot!(cascading.runs, cascading.mean_cost;
		ribbon=get_ribbon(cascading.min_cost, cascading.mean_cost, cascading.max_cost),
		cascading_stylings...,
		label=nothing,)


	random_stylings = (linewidth=1,
		linestyle=:dash,
		color=colors.WET_ASPHALT,
		label="Shielded random agents",)
	
	hline!([random_baseline];
		random_stylings...,
		label=nothing,)
	# Labels #
	plot!([]; centralized_stylings...)
	plot!([]; cascading_stylings...)
	plot!([]; mappo_stylings...)
	plot!([]; random_stylings...)
end

# ╔═╡ a0159339-14f3-4280-8160-447702f19d2a
md"""
# Old junk

A bunch of other plots which were made to explore the data.
"""

# ╔═╡ db1720fb-1134-4d81-b0b0-7da700d38798
# String to vector
function to_vector(str::T, element_type=Float64) where T<:AbstractString
	🐟 = match(r"\[(.*)\]", str)[1]
	if 🐟 == ""
		return Float64[]
	else
		🎣 = split(🐟, ", ")
	 	return Float64[parse(element_type, 🍣) for 🍣 in 🎣]
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

# ╔═╡ 2cc917ff-7098-4c32-a1f8-e75360c37e2c
begin
	function learned_performance_plot!(means::DataFrame, 
			runs;
			color=colors.POMEGRANATE,
			show_other_measurements=true,
			label=nothing,
			plotargs...)
		
		df = filter(:runs => (x -> x == runs), 
			means)
		fleet_sizes = df[!, :fleet_size]
		df = sort(df, :fleet_size)
		fleet_min = min(fleet_sizes...)
		fleet_max = max(fleet_sizes...)
		
		xticks = (collect(2:(fleet_max)), ["$x" for x in 1:(fleet_max)])
		xlims = (1, fleet_max + 1)
		
		marker = (markercolor=color, markershape=:circle, markersize=3, markerstrokecolor=:white)
		
		@df df plot!(:fleet_size, :learned_cost;
			color=color,
			linewidth=2,
			xflip=true,
			xticks,
			xlims,
			xlabel="Car number",
			ylabel="Cost",
			label=something(label, "Trained for $runs runs each"),
			legend=:outertop,
			#marker...,
			plotargs...)

		if show_other_measurements
			for f in fleet_min:fleet_max
				df′ = filter(:fleet_size => (x -> x == f), df)
				other_cars = df′[!, :other_cars_costs]
				other_cars = get(other_cars, 1, [])
				
				scatter!(fleet_min:length(other_cars) + 1, other_cars, 
					plotargs...;
					marker..., 
					label= f == fleet_min ? "Performance measured when re-imported for subsequent training" : nothing)
			end
		end
		plot!(;plotargs...)
	end
	function learned_performance_plot(x...; plotargs...)
		plot(;plotargs...)
		learned_performance_plot!(x...)
	end
end

# ╔═╡ 5d35a941-ea93-45ed-b309-98db9ad9fc47
#=╠═╡
@bind refresh_button CounterButton("Refresh")
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
	cleandata = cascading_raw
	
	cleandata = transform(cleandata, 
		:other_cars_costs => ByRow(to_vector) => :other_cars_costs)
	
	if only_first_repetition
		cleandata = filter(:repetition => (x -> x == 1), cleandata)
	end

	# Global cost: Sum of costs.
	cleandata = transform(cleandata,
		[:learned_cost, :other_cars_costs] => ByRow((r, s) -> (r + sum(s))) => :global_cost)

	cleandata = sort(cleandata, :fleet_size)
	
	cleandata
end
  ╠═╡ =#

# ╔═╡ a675d6b9-0f2b-4023-af2a-1bb43303f6a7
#=╠═╡
means = let
	grouping =  groupby(cleandata, [:runs, :fleet_size])
	
	means = combine(grouping, 
		:learned_cost => mean, 
		:other_cars_costs => (elementwise_mean),
		:global_cost => mean,
		renamecols=false)

	# elementwise_mean returns a string because otherwise it creates a row for each element in returned vector
	means = transform(means,
		:other_cars_costs => ByRow(to_vector), 
		renamecols=false)
end
  ╠═╡ =#

# ╔═╡ a0a064b3-0abf-4277-aaeb-3f8551436f5e
md"""
## Global Cost
"""

# ╔═╡ 846b023b-5fda-4112-b1d9-64a0477199c1
#=╠═╡
means_fully_trained  = filter(:fleet_size => f -> f == 10, means)
  ╠═╡ =#

# ╔═╡ 734ffc56-5fac-4ede-b0d4-b2a9ecde09aa
#=╠═╡
default_y_min, default_y_max = let
	
	default_y_min = min(means_fully_trained[!, :global_cost]...) - 30
	
	default_y_max = max(means_fully_trained[!, :global_cost]...) + 30
	
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

# ╔═╡ 9a298f2a-5194-41c9-813d-afbf56ef92eb
md"""
## Performance compared to when it is imported
"""

# ╔═╡ ef7d9898-c2be-493b-913e-51a854d74c32
#=╠═╡
@bind runs Select(means[!, :runs] |> unique)
  ╠═╡ =#

# ╔═╡ 8a8ad7a8-94cb-4f94-9e78-7684091272c8
#=╠═╡
@info "Repetitions found: $(nrow(filter(:fleet_size => (x -> x == 2), filter(:runs => (x -> x == runs), cleandata))))"
  ╠═╡ =#

# ╔═╡ 65b36dde-10b2-448b-8367-027a5b072d50
#=╠═╡
filter(:runs => (x -> x == runs), 
			means)
  ╠═╡ =#

# ╔═╡ 0c7a6078-b795-4f85-99a8-3c1d47f49500
#=╠═╡
ylims_local = let
	default_y_min = min(means[!, :learned_cost]..., 
		Iterators.flatten(means[!, :other_cars_costs])...) - 2
	
	default_y_max = max(means[!, :learned_cost]..., 
		Iterators.flatten(means[!, :other_cars_costs])...) + 2
	
	default_y_min, default_y_max
end
  ╠═╡ =#

# ╔═╡ 33d2e7c5-f272-4ecd-93cb-c927ceb735ab
#=╠═╡
let 
	readme = cascading_path ⨝ "$runs Runs" ⨝ "readme.txt"
	if isfile(readme)
		md"""
		!!! info "`Readme` found"
		
		at $(readme)
		
		$(readme |> read |> String |> multiline)
		"""
	else
		md"""No readme found in this subfolder"""
	end
end
  ╠═╡ =#

# ╔═╡ 3f04b408-1027-4c87-b138-35e63ab4697a
#=╠═╡
let
	df = filter((x -> x[:runs] == runs), means)
	
	learned_performance_plot(means, runs; ylims=ylims_local, size=(500, 400))
end
  ╠═╡ =#

# ╔═╡ 5a0cac52-ed7d-4177-b8b1-3e6abd2bd8d8
#=╠═╡
unique_runs = means[!, :runs] |> unique |> sort
  ╠═╡ =#

# ╔═╡ 7909f497-55cd-4f9d-b34d-515a80241873
md"""
## Performance for different numbers of runs
"""

# ╔═╡ ff362535-2cc2-4784-88b8-1b3ae48d6293
md"""
## Compared to non-specialized run

The specialized and non-specialized have been hard-coded to 20k and 20k+1 respectively.
"""

# ╔═╡ f267c827-7e5d-466c-9ad0-bfdb004befe3
md"""
## Plot for centralized learner experiment
"""

# ╔═╡ af2912dc-4fdb-49ad-b22a-df877e2b845a
#=╠═╡
let	
	df = filter(:runs => (x -> x == runs), means)
	df = sort(df, :fleet_size, rev=true)
	
	fleet_sizes = df[!, :fleet_size]
	fleet_min = min(fleet_sizes...)
	fleet_max = max(fleet_sizes...)
	xticks = (collect(0:(fleet_max - 1)), ["$x" for x in 0:(fleet_max - 1)])
	#xticks = (collect(0:(fleet_max - 1)), ["car$x" for x in 0:(fleet_max - 1)])
	#xticks[2][1] = "car0\n(random)"
	xlims = (-1, fleet_max)
	
	plot(;xticks,
		xlims,
		xflip=true,
		xlabel="Car number",
		ylabel="Cost")

	c = [colors.POMEGRANATE, colors.BELIZE_HOLE, colors.GREEN_SEA, colors.CARROT, colors.WISTERIA, colors.EMERALD, colors.SUNFLOWER, colors.PETER_RIVER]
	markers = [(4, :pentagon), (4, :square), (4, :utriangle), (5, :star4), (5, :star), (4, :circle),]
	
	for (i, row) in enumerate(eachrow(df))
		label = "Fleet size $(row[:fleet_size])"
		color = c[1 + (i - 1)%length(c)]
		marker = markers[1 + (i - 1)%length(markers)]
		linealpha = length(row[:other_cars_costs]) > 0 ? 1 : 0
		
		plot!([row[:other_cars_costs]..., row[:learned_cost]];
			label,
			ylims=ylims_local,
			size,
			color,
			marker,
			linealpha,
			linewidth=2,
			markerstrokecolor=:white,
			markersize=4,
			legend=:outerright)
	end
	plot!()
end
  ╠═╡ =#

# ╔═╡ a1cfa77f-b7e7-4cec-9916-cb076517876c
#=╠═╡
@bind runs_shown MultiSelect(all_runs, 
	# These were the numbers I went with.
	default=[r for r in all_runs if r ∈ [100, 500, 1000] || r%6000 == 0 ])
  ╠═╡ =#

# ╔═╡ 7622369d-1363-4032-a910-4e94950d4257
#=╠═╡
function extract_data(raw_data)
	df = raw_data
	fleet_size = max(df.fleet_size...)
	df = filter(:fleet_size => (==)(fleet_size), df)
	df = filter(:runs => r -> r ∈ runs_shown, df)
	df = transform(df, :other_cars_costs => ByRow(to_vector) => :other_cars_costs)
	df = transform(df, [:learned_cost, :other_cars_costs] => ByRow(append) => :costs)
	df = transform(df, :costs => ByRow(sum) => :cost)

	if first_repetition_only
		df = filter(:repetition => (==)(1), df)
	end
	
	grouping =  groupby(df, [:runs])

	df = combine(grouping,
		:cost => minimum => :min_cost,
		:cost => mean => :mean_cost,
		:cost => maximum => :max_cost,
	)

	df = sort(df, :runs)

	return (runs=[r for r  in df.runs], 
		min_cost=[p for p in df.min_cost],
		mean_cost=[p for p in df.mean_cost],
		max_cost=[p for p in df.max_cost],
		)
end
  ╠═╡ =#

# ╔═╡ 0238227a-cf71-4c32-a1d0-5fea6d7ccfad
#=╠═╡
centralized = extract_data(centralized_raw)
  ╠═╡ =#

# ╔═╡ eec06110-31c5-4658-9593-ad3760666019
#=╠═╡
minimum(centralized.min_cost)
  ╠═╡ =#

# ╔═╡ 05247031-a354-4e81-b248-6df204d79dae
#=╠═╡
cascading = extract_data(cascading_raw)
  ╠═╡ =#

# ╔═╡ 00004964-8b4c-4e84-b05e-a3df32135aa9
#=╠═╡
minimum(cascading.min_cost)
  ╠═╡ =#

# ╔═╡ 74674f2d-c384-4c01-957b-ca8d15062db3
#=╠═╡
do_the_plot_of_the_results(;cascading, centralized, random_baseline, mappo)
  ╠═╡ =#

# ╔═╡ 3db1a697-2600-4316-ac35-db5c7fc2b665
#=╠═╡
let
	df = sort(means_fully_trained, :runs)
	df = filter(:runs => r -> r ∈ runs_shown, df)
	df = transform(df, :runs => ByRow(r -> "$r"), renamecols=false)
	@df df plot(:runs, :global_cost;
		size,
		ylims,
		color=colors.NEPHRITIS,
		marker=:circle,
		markerstrokewidth=0,
		label=nothing,
		xlabel="Episodes per car",
		ylabel="Total cost")
end
  ╠═╡ =#

# ╔═╡ f00c8154-36be-495e-b681-fd3c24f97561
#=╠═╡
let
	df = filter((x -> x[:runs] ∈ runs_shown), means)
	
	plot(;ylims=ylims_local, size)

	c = [colors.POMEGRANATE, colors.BELIZE_HOLE, colors.GREEN_SEA, colors.CARROT, colors.WISTERIA, colors.EMERALD, colors.SUNFLOWER, colors.PETER_RIVER]
	
	strokes = [:dashdot, :dash, :dot, :solid, ]
	
	for (i, r) in enumerate(runs_shown)
		learned_performance_plot!(means, r, 
			color=c[1 + (i - 1)%length(c)],
			line=strokes[1 + (i - 1)%length(strokes)],
			markerstrokecolor=:white,
			show_other_measurements=false)
	end
	plot!()
end
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═d0db8070-41a9-11ee-2b97-818668d7efa8
# ╟─2bd47b9e-31e3-4ee1-aa87-60dfc40869a9
# ╟─c9e1bc2c-a6f7-4b88-8038-51cf2ef2a008
# ╟─4362212e-0f0e-4425-bfb1-a6c3808ed808
# ╟─95e38fbd-142d-4926-9291-27e69ddf7c75
# ╠═cd4fb0d2-d1b6-4301-97e4-9ddb3505e061
# ╠═61c15d44-75be-4613-8b60-484d94847b8a
# ╠═15f0808f-8424-4d27-9247-274c7751bf8e
# ╠═26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
# ╠═ce5168ba-17e5-4d70-84b9-e396aaf9f9bf
# ╟─24f1af15-c323-4407-92ca-b55cc14263de
# ╟─9b4d6b4d-d958-480b-af15-d07a4dc4b8ca
# ╠═ec3df7e5-80d3-4bc7-8dda-54551ee1936c
# ╠═10ca302d-f5f3-4e66-877f-1974138235f5
# ╠═f467cbb0-ac89-462a-86b2-55e4d3580ee6
# ╠═0a71b644-8499-46f9-9614-c65baf23957e
# ╠═47f85802-4082-40d6-9854-8ded4441d1e4
# ╠═6698877b-632c-4049-949f-9d7ea0465d23
# ╠═b9adeac6-5a91-4c69-b1b1-4b1931c23840
# ╠═572cade9-c131-4206-b79d-e1ee118f230b
# ╟─abb7365c-1d40-4f92-9664-e005117b5c00
# ╠═a2256c72-3686-4f89-9adf-6684270946b6
# ╠═2655802d-f3b9-4850-8164-81a860ca5716
# ╠═12e5d573-610c-4c9e-a555-237f1fd983b4
# ╠═7622369d-1363-4032-a910-4e94950d4257
# ╟─ef5c1d6e-9046-4da7-bfd1-2a12832d0e7d
# ╠═0238227a-cf71-4c32-a1d0-5fea6d7ccfad
# ╠═05247031-a354-4e81-b248-6df204d79dae
# ╠═ae5337da-bd26-4229-a72c-0602bc68f774
# ╠═712fde99-ce98-48df-a487-f78bd2a7f4fd
# ╠═00004964-8b4c-4e84-b05e-a3df32135aa9
# ╠═eec06110-31c5-4658-9593-ad3760666019
# ╠═3f9a588d-6e0c-4bd4-a123-447c313703cc
# ╠═74674f2d-c384-4c01-957b-ca8d15062db3
# ╠═f5561b0b-f16f-454f-bdc5-cbf3b93ecf91
# ╟─a0159339-14f3-4280-8160-447702f19d2a
# ╠═db1720fb-1134-4d81-b0b0-7da700d38798
# ╠═be64568d-f451-46f4-8336-bd94fff82471
# ╠═5484bf48-11be-4ac7-9557-e6fa36802f1d
# ╠═85871e02-b379-4306-a547-1d6239e61fc2
# ╠═a675d6b9-0f2b-4023-af2a-1bb43303f6a7
# ╠═8a8ad7a8-94cb-4f94-9e78-7684091272c8
# ╠═65b36dde-10b2-448b-8367-027a5b072d50
# ╠═2cc917ff-7098-4c32-a1f8-e75360c37e2c
# ╠═5d35a941-ea93-45ed-b309-98db9ad9fc47
# ╠═1f973cbe-a416-44fa-8e3b-e6392f6ddb16
# ╟─a0a064b3-0abf-4277-aaeb-3f8551436f5e
# ╠═846b023b-5fda-4112-b1d9-64a0477199c1
# ╠═734ffc56-5fac-4ede-b0d4-b2a9ecde09aa
# ╟─64921a92-ce9a-4a79-9349-445c8eb4fe15
# ╟─2b5eb5be-3e34-4eca-84c9-18a32aacdfab
# ╟─b1090c8e-9f46-429a-93a7-42cedba24188
# ╠═8ff26541-30b4-42bb-85a0-1d08e1c8d2aa
# ╠═3db1a697-2600-4316-ac35-db5c7fc2b665
# ╟─9a298f2a-5194-41c9-813d-afbf56ef92eb
# ╠═ef7d9898-c2be-493b-913e-51a854d74c32
# ╠═0c7a6078-b795-4f85-99a8-3c1d47f49500
# ╟─33d2e7c5-f272-4ecd-93cb-c927ceb735ab
# ╠═3f04b408-1027-4c87-b138-35e63ab4697a
# ╠═5a0cac52-ed7d-4177-b8b1-3e6abd2bd8d8
# ╟─7909f497-55cd-4f9d-b34d-515a80241873
# ╠═f00c8154-36be-495e-b681-fd3c24f97561
# ╟─ff362535-2cc2-4784-88b8-1b3ae48d6293
# ╟─f267c827-7e5d-466c-9ad0-bfdb004befe3
# ╠═af2912dc-4fdb-49ad-b22a-df877e2b845a
# ╠═a1cfa77f-b7e7-4cec-9916-cb076517876c
