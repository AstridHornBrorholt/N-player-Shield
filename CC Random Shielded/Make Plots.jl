### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ d0db8070-41a9-11ee-2b97-818668d7efa8
begin
	using Pkg
	Pkg.activate("..")
	using CSV
	using Glob
	using NaturalSort
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

# ╔═╡ 1f3a2bee-2817-4314-901e-7dd3743fbab9
#=╠═╡
@bind results_dir TextField(80, default=homedir() ⨝ "Results/N-player CC Random Shielded")
  ╠═╡ =#

# ╔═╡ 7f72aebe-fbb6-40fa-a5df-055d40686830
#=╠═╡
let
	safety_query = read(results_dir ⨝ "Safety.txt", String)
	safe = occursin(r"Result: \(0/\d+ runs\)", safety_query)

	if !safe
		Markdown.parse("""
		!!! danger "Not safe"
			Doesn't seem like the query made to test safety gave the right result:
		
				$(join(split(safety_query, "\n"), "\n		"))
		""")
	else
		Markdown.parse("""
		!!! success "Safe 👍"
			The query results at `Safety.txt` indicate 0 safety violations.
		""")
	end
end
  ╠═╡ =#

# ╔═╡ fa39787e-ba6a-47af-b34a-6c2c5e898246
function extract_results(query_result)
	re_mean = r"mean=(\d+\.?\d*)"
	result = [m[1] for m in eachmatch(re_mean, query_result)]
	result = [parse(Float64, v) for v in result]
end

# ╔═╡ 9861f624-61eb-428a-9155-5ad95f260ef7
# "foo.bar.baz" -> "foo.bar"
function trim_extension(file_name)
	join(split(file_name, ".")[1:end-1], ".") # Trust me on this one
end

# ╔═╡ b38bd77e-ba8f-408c-9905-f8af5f521e25
function read_that_data(results_dir)
	isdir(results_dir) || error("Nope. Not found.")
	result = []
	for 📄 in glob("D*.txt", results_dir)
		mean = extract_results(read(📄, String))
		if length(mean) != 1
			error("Error for $📄.\nLength was $(length(mean)) should be 1.")
		end
		
		name = 📄 |> basename |> trim_extension
		push!(result, (name, mean[1]))
	end
	result = sort(result, by=(x -> x[1]), lt=natural)
	result = [x[2] for x in result]
end

# ╔═╡ 3d251c90-c490-473a-8055-bae322175a4c
episode_length = 100

# ╔═╡ 1ea2bb05-23c0-4523-9893-377073d08784
#=╠═╡
@bind just_first_10 CheckBox(default=true)
  ╠═╡ =#

# ╔═╡ 2cc917ff-7098-4c32-a1f8-e75360c37e2c
begin
	function performance_plot!(data;
			color=colors.SUNFLOWER,
			label=nothing,
			plotargs...)
		
		fleet_min = 2
		fleet_max = length(data) + 1
		fleet_sizes = collect(fleet_min:fleet_max)
		
		xticks = (collect(2:(fleet_max)), ["$x" for x in 1:(fleet_max)])
		xlims = (1, fleet_max + 1)
		
		marker = (markercolor=color, markershape=:circle, markersize=3, markerstrokecolor=:white)
		
		plot!(fleet_sizes, data;
			color=color,
			linewidth=2,
			xflip=true,
			xticks,
			xlims,
			xlabel="Car number",
			ylabel="Reward",
			label=something(label, "Performance"),
			legend=:outertop,
			#marker...,
			plotargs...)
	end
	function performance_plot(data; plotargs...)
		plot(;plotargs...)
		performance_plot!(data)
	end
end

# ╔═╡ 5d35a941-ea93-45ed-b309-98db9ad9fc47
#=╠═╡
@bind refresh_button CounterButton("Refresh")
  ╠═╡ =#

# ╔═╡ 7d154396-2531-42c8-b5fa-69d28eada5fd
#=╠═╡
refresh_button; data = read_that_data(results_dir)
  ╠═╡ =#

# ╔═╡ d1695f9c-ac7d-49ae-a2eb-b14003e691a9
#=╠═╡
begin
	cleandata = [-p/episode_length for p in data]

	if just_first_10
		cleandata = cleandata[1:9]
	end
end
  ╠═╡ =#

# ╔═╡ 9a298f2a-5194-41c9-813d-afbf56ef92eb
md"""
## The thing.
"""

# ╔═╡ c90e208d-bb16-4380-a449-61eea4fad65f
#=╠═╡
md"""
`y_min` = $(@bind y_min NumberField(-100000.:1.:100000., default=-93.0))

`y_max` = $(@bind y_max NumberField(-100000.:1.:100000., default=-24.0))
"""
  ╠═╡ =#

# ╔═╡ 4d205879-d6bb-4035-bea7-61a8a16fa5e0
#=╠═╡
ylims = (y_min, y_max)
  ╠═╡ =#

# ╔═╡ 47b4278f-543f-4894-9da4-a9d8d0aa8053
#=╠═╡
md"""
`width` = $(@bind width NumberField(0:10:typemax(Int64), default=350))

`height` = $(@bind height NumberField(0:10:typemax(Int64), default=250))
"""
  ╠═╡ =#

# ╔═╡ 7edcc1a4-1610-47fb-be47-dafbb4ada567
#=╠═╡
size = (width, height)
  ╠═╡ =#

# ╔═╡ 0d946f3d-d7d6-40d1-9c29-f64df6f34221
#=╠═╡
performance_plot(cleandata; ylims, size)
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
# ╠═1f3a2bee-2817-4314-901e-7dd3743fbab9
# ╟─7f72aebe-fbb6-40fa-a5df-055d40686830
# ╠═fa39787e-ba6a-47af-b34a-6c2c5e898246
# ╠═9861f624-61eb-428a-9155-5ad95f260ef7
# ╠═b38bd77e-ba8f-408c-9905-f8af5f521e25
# ╠═7d154396-2531-42c8-b5fa-69d28eada5fd
# ╠═3d251c90-c490-473a-8055-bae322175a4c
# ╠═1ea2bb05-23c0-4523-9893-377073d08784
# ╠═d1695f9c-ac7d-49ae-a2eb-b14003e691a9
# ╠═2cc917ff-7098-4c32-a1f8-e75360c37e2c
# ╠═5d35a941-ea93-45ed-b309-98db9ad9fc47
# ╟─9a298f2a-5194-41c9-813d-afbf56ef92eb
# ╟─c90e208d-bb16-4380-a449-61eea4fad65f
# ╠═4d205879-d6bb-4035-bea7-61a8a16fa5e0
# ╟─47b4278f-543f-4894-9da4-a9d8d0aa8053
# ╠═7edcc1a4-1610-47fb-be47-dafbb4ada567
# ╠═0d946f3d-d7d6-40d1-9c29-f64df6f34221
