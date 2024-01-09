### A Pluto.jl notebook ###
# v0.19.36

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
@bind results_dir TextField(80, default=homedir() ⨝ "Results/N-player CP Centralized Controller")
  ╠═╡ =#

# ╔═╡ a01b30e8-8390-4b00-98ce-7895c144f019
#=╠═╡
isdir(results_dir)
  ╠═╡ =#

# ╔═╡ 2cc917ff-7098-4c32-a1f8-e75360c37e2c
begin
	function learned_performance_plot!(means::DataFrame, selected_runs;
			color=colors.WET_ASPHALT,
			label=nothing,
			plotargs...)

		df = filter(:runs => (x -> x ∈ selected_runs), means)
		df = sort(df, :runs)
		df = transform(df, :runs => ByRow(string) => :runs)
				
		@df df plot!(:runs, :reward;
			color=color,
			linewidth=2,
			xlabel="Training episodes",
			ylabel="Reward",
			label=something(label, "Centralized controller"),
			legend=:outertop,
			#marker...,
			plotargs...)
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
		:trained_performance => ByRow(p -> -p) => :reward,
	)
	
	cleandata
end
  ╠═╡ =#

# ╔═╡ a675d6b9-0f2b-4023-af2a-1bb43303f6a7
#=╠═╡
means = let
	grouping =  groupby(cleandata, [:runs])
	
	means = combine(grouping, 
		:trained_performance => mean, 
		:untrained_performance => mean,
		:reward => mean,
		renamecols=false)
end
  ╠═╡ =#

# ╔═╡ 7909f497-55cd-4f9d-b34d-515a80241873
md"""
## Performance for different numbers of runs
"""

# ╔═╡ 9f5ae20f-fcd9-4327-afbd-bbe9378c00de
#=╠═╡
unique_runs = means[!, :runs] |> unique |> sort
  ╠═╡ =#

# ╔═╡ 602415bc-687e-45d9-a96f-afaf1f214eb7
#=╠═╡
@bind selected_runs MultiSelect(unique_runs, 
		default=[r for r in unique_runs if (r > 1000 && r%100==0)])
  ╠═╡ =#

# ╔═╡ 40e793f8-e34a-466f-80fa-901c4b728a08
#=╠═╡
selected_runs
  ╠═╡ =#

# ╔═╡ 734ffc56-5fac-4ede-b0d4-b2a9ecde09aa
#=╠═╡
begin
	default_y_min = min(means[!, :reward]...) - 100
	
	default_y_max = max(means[!, :reward]...) + 100
	
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
`width` = $(@bind width NumberField(0:10:typemax(Int64), default=350))

`height` = $(@bind height NumberField(0:10:typemax(Int64), default=250))
"""
  ╠═╡ =#

# ╔═╡ 8ff26541-30b4-42bb-85a0-1d08e1c8d2aa
#=╠═╡
size = (width, height)
  ╠═╡ =#

# ╔═╡ 3f04b408-1027-4c87-b138-35e63ab4697a
#=╠═╡
learned_performance_plot(means, selected_runs; ylims, size)
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
# ╠═a01b30e8-8390-4b00-98ce-7895c144f019
# ╠═62086f17-badc-4ec9-a5e8-25ebb0f6cdc8
# ╠═e1ddadeb-e9fd-4c37-a206-dff03363724e
# ╠═7cd7f277-8388-413a-b993-9b81fdb495b8
# ╠═5484bf48-11be-4ac7-9557-e6fa36802f1d
# ╠═a675d6b9-0f2b-4023-af2a-1bb43303f6a7
# ╠═2cc917ff-7098-4c32-a1f8-e75360c37e2c
# ╠═5d35a941-ea93-45ed-b309-98db9ad9fc47
# ╠═1f973cbe-a416-44fa-8e3b-e6392f6ddb16
# ╟─7909f497-55cd-4f9d-b34d-515a80241873
# ╠═9f5ae20f-fcd9-4327-afbd-bbe9378c00de
# ╠═602415bc-687e-45d9-a96f-afaf1f214eb7
# ╠═40e793f8-e34a-466f-80fa-901c4b728a08
# ╠═3f04b408-1027-4c87-b138-35e63ab4697a
# ╠═734ffc56-5fac-4ede-b0d4-b2a9ecde09aa
# ╟─64921a92-ce9a-4a79-9349-445c8eb4fe15
# ╟─2b5eb5be-3e34-4eca-84c9-18a32aacdfab
# ╟─b1090c8e-9f46-429a-93a7-42cedba24188
# ╠═8ff26541-30b4-42bb-85a0-1d08e1c8d2aa
