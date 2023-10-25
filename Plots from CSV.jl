### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ d0db8070-41a9-11ee-2b97-818668d7efa8
begin
	using Pkg
	Pkg.activate(".")
	using CSV
	using DataFrames
	using Plots
	using Statistics
	using StatsPlots
end;

# ╔═╡ 61c15d44-75be-4613-8b60-484d94847b8a
# ╠═╡ skip_as_script = true
#=╠═╡
begin
	using PlutoUI
	include("Results to CSV.jl")
	include("FlatUI Colors.jl")
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
	background-image: url("https://i.imgur.com/VqU9gsd.png");
}
pluto-notebook {
	background: none;
}

pluto-output  {
	border-radius: 4pt 4pt 0 0;
	padding: 4pt;
	background: none;
	backdrop-filter: blur(5px)brightness(104%);
}

pluto-input .cm-editor {
	background: none;
	backdrop-filter: blur(5px)brightness(98%);
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

# ╔═╡ 4b3789f9-759d-405b-a369-fb50a4a5a42a
#=╠═╡
TableOfContents()
  ╠═╡ =#

# ╔═╡ 15f0808f-8424-4d27-9247-274c7751bf8e
Plots.default(fontfamily="serif-roman") 

# ╔═╡ 26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
← = push!

# ╔═╡ ce5168ba-17e5-4d70-84b9-e396aaf9f9bf
⨝ = joinpath

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
		
		@df df plot!(:fleet_size, :reward;
			color=color,
			linewidth=2,
			xflip=true,
			xticks,
			xlims,
			xlabel="Car number",
			ylabel="Reward",
			label=something(label, "Trained for $runs runs each"),
			legend=:outertop,
			#marker...,
			plotargs...)

		if show_other_measurements
			for f in fleet_min:fleet_max
				df′ = filter(:fleet_size => (x -> x == f), df)
				other_cars = df′[!, :other_cars_reward]
				other_cars = get(other_cars, 1, [])
				scatter!(2:length(other_cars), other_cars, plotargs...; marker..., label=nothing)
			end
		end
		plot!(;plotargs...)
	end
	function learned_performance_plot(x...; plotargs...)
		plot(;plotargs...)
		learned_performance_plot!(x...)
	end
end

# ╔═╡ 24408d9e-de30-4e1e-805b-07ee138371e0
md"""
### NB

I have been using x001 as a shorthand for "non-specialized variant of the experiment that was trained for x000 runs." 

If there is a readme in the root of the folder, it will be displayed in the below cell.

This is because I don't support labels for the experiments beyond the number of runs used. This is a bit of a mess. Other values like x003 and x004 have no set definitions. I don't remember what those are.
"""

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

# ╔═╡ 1f3a2bee-2817-4314-901e-7dd3743fbab9
#=╠═╡
@bind results_dir TextField(80, default=homedir() ⨝ "Results/N-player CC")
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

# ╔═╡ 5484bf48-11be-4ac7-9557-e6fa36802f1d
#=╠═╡
cleandata = let
	cleandata = raw_results
	
	cleandata = transform(cleandata, 
		:other_cars => ByRow(to_vector) => :other_cars_performance)
	
	if only_first_repetition
		cleandata = filter(:repetition => (x -> x == 1), cleandata)
	end
	
	episode_length = 100
	
	cleandata = transform(cleandata, 
		:learned_performance => ByRow(p -> -p/episode_length) => :reward)
	
	cleandata = transform(cleandata, 
		:other_cars_performance => ByRow(v -> [-p/episode_length for p in v]) => :other_cars_reward)
	
	cleandata
end
  ╠═╡ =#

# ╔═╡ a675d6b9-0f2b-4023-af2a-1bb43303f6a7
#=╠═╡
means = let
	grouping =  groupby(cleandata, [:runs, :fleet_size])
	
	means = combine(grouping, 
		:learned_performance => mean, 
		:other_cars_performance => (elementwise_mean), 
		:other_cars_reward => (elementwise_mean), 
		:reward => mean,
		renamecols=false)

	# elementwise_mean returns a string because otherwise it creates a row for each element in returned vector
	means = transform(means, 
		:other_cars_reward => ByRow(to_vector), 
		:other_cars_performance => ByRow(to_vector), 
		renamecols=false)
end
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

# ╔═╡ 33d2e7c5-f272-4ecd-93cb-c927ceb735ab
#=╠═╡
let 
	readme = results_dir ⨝ "$runs Runs" ⨝ "readme.txt"
	if isfile(readme)
		md"""
		!!! info "`Readme` found"
		
		at $(readme)
		
		$(readme |> read |> String |> multiline)
		"""
	end
end
  ╠═╡ =#

# ╔═╡ 5a0cac52-ed7d-4177-b8b1-3e6abd2bd8d8
#=╠═╡
unique_runs = means[!, :runs] |> unique |> sort
  ╠═╡ =#

# ╔═╡ 977e914e-3995-463c-ab74-d8f256adec27
#=╠═╡
@bind selected_runs MultiSelect(unique_runs, 
		default=[r for r in unique_runs if (r > 1000 && r%100==0)])
  ╠═╡ =#

# ╔═╡ 7909f497-55cd-4f9d-b34d-515a80241873
md"""
## Performance for different numbers of runs
"""

# ╔═╡ 734ffc56-5fac-4ede-b0d4-b2a9ecde09aa
#=╠═╡
begin
	default_y_min = min(means[!, :reward]..., 
		Iterators.flatten(means[!, :other_cars_reward])...) - 2
	
	default_y_max = max(means[!, :reward]..., 
		Iterators.flatten(means[!, :other_cars_reward])...) + 2
	
	(;default_y_min, default_y_max)
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
`width` = $(@bind width NumberField(0:10:typemax(Int64), default=600))

`height` = $(@bind height NumberField(0:10:typemax(Int64), default=400))
"""
  ╠═╡ =#

# ╔═╡ 8ff26541-30b4-42bb-85a0-1d08e1c8d2aa
#=╠═╡
size = (width, height)
  ╠═╡ =#

# ╔═╡ 3f04b408-1027-4c87-b138-35e63ab4697a
#=╠═╡
let
	df = filter((x -> x[:runs] == runs), means)
	
	learned_performance_plot(means, runs; ylims, size)
end
  ╠═╡ =#

# ╔═╡ f00c8154-36be-495e-b681-fd3c24f97561
#=╠═╡
let
	df = filter((x -> x[:runs] ∈ selected_runs), means)
	
	plot(;ylims, size)

	c = [colors.POMEGRANATE, colors.BELIZE_HOLE, colors.GREEN_SEA, colors.CARROT, colors.WISTERIA, colors.EMERALD, colors.SUNFLOWER, colors.PETER_RIVER]
	
	strokes = [:dashdot, :dash, :dot, :solid, ]
	
	for (i, r) in enumerate(selected_runs)
		learned_performance_plot!(means, r, 
			color=c[1 + (i - 1)%length(c)],
			line=strokes[1 + (i - 1)%length(strokes)],
			markerstrokecolor=:white,
			show_other_measurements=false)
	end
	plot!()
end
  ╠═╡ =#

# ╔═╡ ff362535-2cc2-4784-88b8-1b3ae48d6293
md"""
## Compared to non-specialized run

The specialized and non-specialized have been hard-coded to 20k and 20k+1 respectively.
"""

# ╔═╡ 7e493642-9343-4c21-9100-093c9e8e11f2
#=╠═╡
let
	specialized = 20000
	non_specialized = 20001
	plot(;ylims, size)
	learned_performance_plot!(means, non_specialized,
		color=colors.SUNFLOWER, 
		linestyle=:dashdotdot,
		label="Trained for $specialized runs once and re-used",
		show_other_measurements=false)
	
	learned_performance_plot!(means, specialized,
		color=colors.CARROT, 
		label="Trained for $specialized runs each",
		show_other_measurements=false)
end
  ╠═╡ =#

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
		ylabel="Reward")

	c = [colors.POMEGRANATE, colors.BELIZE_HOLE, colors.GREEN_SEA, colors.CARROT, colors.WISTERIA, colors.EMERALD, colors.SUNFLOWER, colors.PETER_RIVER]
	markers = [(4, :pentagon), (4, :square), (4, :utriangle), (5, :star4), (5, :star), (4, :circle),]
	
	for (i, row) in enumerate(eachrow(df))
		label = "Fleet size $(row[:fleet_size])"
		color = c[1 + (i - 1)%length(c)]
		marker = markers[1 + (i - 1)%length(markers)]
		linealpha = length(row[:other_cars_reward]) > 0 ? 1 : 0
		
		plot!([row[:other_cars_reward]..., row[:reward]];
			label,
			ylims,
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

# ╔═╡ efabb8a3-ef0b-412a-aa6d-ea9d6a3c36cf
md"""
## Plot for centralized learner experiment (mean performance)
"""

# ╔═╡ 8ad6aacf-2e18-4e20-ab90-a1f36a2256cf
#=╠═╡
let	
	df = filter(:runs => (x -> x == runs), means)
	
	fleet_sizes = df[!, :fleet_size]
	fleet_min = min(fleet_sizes...)
	fleet_max = max(fleet_sizes...)
	xticks = (fleet_min:fleet_max |> collect)
	xlims = (1, fleet_max + 1)
	
	plot(;
		ylims,
		size,
		xticks,
		xlims,
		xflip=false,
		xlabel="Fleet size",
		ylabel="Mean reward")

	
	fleet_size = []
	mean_performance = []

	for row in eachrow(df)
		fleet_size ← row[:fleet_size]
		mean_performance ← [row[:reward], row[:other_cars_reward]...] |> mean
	end
	bar!(fleet_size, mean_performance, 
		label=nothing,
		linecolor=:white,
		bar=3,
		color=colors.WET_ASPHALT)
end
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═d0db8070-41a9-11ee-2b97-818668d7efa8
# ╟─2bd47b9e-31e3-4ee1-aa87-60dfc40869a9
# ╟─c9e1bc2c-a6f7-4b88-8038-51cf2ef2a008
# ╟─4362212e-0f0e-4425-bfb1-a6c3808ed808
# ╟─95e38fbd-142d-4926-9291-27e69ddf7c75
# ╠═61c15d44-75be-4613-8b60-484d94847b8a
# ╠═4b3789f9-759d-405b-a369-fb50a4a5a42a
# ╠═15f0808f-8424-4d27-9247-274c7751bf8e
# ╠═26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
# ╠═ce5168ba-17e5-4d70-84b9-e396aaf9f9bf
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
# ╠═2cc917ff-7098-4c32-a1f8-e75360c37e2c
# ╟─24408d9e-de30-4e1e-805b-07ee138371e0
# ╠═5d35a941-ea93-45ed-b309-98db9ad9fc47
# ╠═1f973cbe-a416-44fa-8e3b-e6392f6ddb16
# ╠═1f3a2bee-2817-4314-901e-7dd3743fbab9
# ╟─9a298f2a-5194-41c9-813d-afbf56ef92eb
# ╠═ef7d9898-c2be-493b-913e-51a854d74c32
# ╟─33d2e7c5-f272-4ecd-93cb-c927ceb735ab
# ╠═3f04b408-1027-4c87-b138-35e63ab4697a
# ╠═5a0cac52-ed7d-4177-b8b1-3e6abd2bd8d8
# ╠═977e914e-3995-463c-ab74-d8f256adec27
# ╟─7909f497-55cd-4f9d-b34d-515a80241873
# ╟─734ffc56-5fac-4ede-b0d4-b2a9ecde09aa
# ╟─64921a92-ce9a-4a79-9349-445c8eb4fe15
# ╟─2b5eb5be-3e34-4eca-84c9-18a32aacdfab
# ╟─b1090c8e-9f46-429a-93a7-42cedba24188
# ╠═8ff26541-30b4-42bb-85a0-1d08e1c8d2aa
# ╠═f00c8154-36be-495e-b681-fd3c24f97561
# ╟─ff362535-2cc2-4784-88b8-1b3ae48d6293
# ╠═7e493642-9343-4c21-9100-093c9e8e11f2
# ╟─f267c827-7e5d-466c-9ad0-bfdb004befe3
# ╠═af2912dc-4fdb-49ad-b22a-df877e2b845a
# ╟─efabb8a3-ef0b-412a-aa6d-ea9d6a3c36cf
# ╠═8ad6aacf-2e18-4e20-ab90-a1f36a2256cf
