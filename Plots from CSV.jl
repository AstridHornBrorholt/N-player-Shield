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
	include("FlatUI Colors.jl")
end;

# ╔═╡ 61c15d44-75be-4613-8b60-484d94847b8a
# ╠═╡ skip_as_script = true
#=╠═╡
using PlutoUI
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
"""

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
	background: #ffa18a;
}

body:not(.___) pluto-cell:focus-within > pluto-trafficlight {
	background: #b4caed;
}
</style>

<p>🎨 Custom style sheet loaded.</p>
"""

# ╔═╡ 95e38fbd-142d-4926-9291-27e69ddf7c75
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

# ╔═╡ 26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
← = push!

# ╔═╡ 1f3a2bee-2817-4314-901e-7dd3743fbab9
#=╠═╡
@bind results_csv FilePicker()
  ╠═╡ =#

# ╔═╡ 62086f17-badc-4ec9-a5e8-25ebb0f6cdc8
#=╠═╡
csv_string = results_csv["data"] |> String 
  ╠═╡ =#

# ╔═╡ e1ddadeb-e9fd-4c37-a206-dff03363724e
#=╠═╡
csv_string |> multiline
  ╠═╡ =#

# ╔═╡ 7cd7f277-8388-413a-b993-9b81fdb495b8
#=╠═╡
raw_results = CSV.read(IOBuffer(csv_string), DataFrame)
  ╠═╡ =#

# ╔═╡ db1720fb-1134-4d81-b0b0-7da700d38798
# Avoid eval call
function to_vector(str::T) where T<:AbstractString
	🐟 = match(r"\[(.*)\]", str)[1]
	if 🐟 == ""
		return []
	else
		🎣 = split(🐟, ", ")
	 	return [parse(Float64, 🍣) for 🍣 in 🎣]
	end
end

# ╔═╡ be64568d-f451-46f4-8336-bd94fff82471
to_vector("[3377.35, 2655.58, 2868.0, 2781.98]")

# ╔═╡ 5484bf48-11be-4ac7-9557-e6fa36802f1d
#=╠═╡
cleandata = let
	cleandata = raw_results
	cleandata = transform(cleandata, :other_cars => ByRow(to_vector) => :other_cars)
end
  ╠═╡ =#

# ╔═╡ 85871e02-b379-4306-a547-1d6239e61fc2
function elementwise_mean(vec)
	result = []
	length(vec) > 0 || return result |> string
	for (i, _) in enumerate(vec[1])
		result ← mean([v[i] for v in vec])
	end
	result |> string
end

# ╔═╡ a675d6b9-0f2b-4023-af2a-1bb43303f6a7
#=╠═╡
means = let
	grouping =  groupby(cleandata, [:runs, :fleet_size])
	
	means = combine(grouping, 
		:learned_performance => mean, :other_cars => (elementwise_mean), 
		renamecols=false)
	
	means = transform(means, :other_cars => ByRow(to_vector), 
		renamecols=false)
end
  ╠═╡ =#

# ╔═╡ ef7d9898-c2be-493b-913e-51a854d74c32
#=╠═╡
@bind runs Select(means[!, :runs] |> unique)
  ╠═╡ =#

# ╔═╡ 8a8ad7a8-94cb-4f94-9e78-7684091272c8
#=╠═╡
@info "Repetitions found: $(nrow(filter(:fleet_size => (x -> x == 2), filter(:runs => (x -> x == runs), cleandata))))"
  ╠═╡ =#

# ╔═╡ 2cc917ff-7098-4c32-a1f8-e75360c37e2c
begin
	function learned_performance_plot!(means::DataFrame, 
			runs;
			color=colors.POMEGRANATE,
			show_other_measurements=true)
		
		df = filter(:runs => (x -> x == runs), 
			means)
		fleet_sizes = df[!, :fleet_size]
		fleet_min = min(fleet_sizes...)
		fleet_max = max(fleet_sizes...)
		
		xticks = (collect(1:(fleet_max - 1)), ["car$x" for x in 1:(fleet_max - 1)])
		
		@df df plot!(:learned_performance, 
			color=color,
			linewidth=2,
			xticks=xticks,
			xlabel="learner",
			ylabel="performance",
			label="trained for $runs runs",
			legend=:outertop)

		if show_other_measurements
			marker = (markercolor=color, markershape=:circle, markersize=6, markerstrokecolor=:white)
			for f in fleet_min:fleet_max
				df′ = filter(:fleet_size => (x -> x == f), df)
				other_cars = df′[!, :other_cars]
				scatter!(other_cars; marker..., label=nothing)
			end
		end
		plot!()
	end
	function learned_performance_plot(x...)
		plot()
		learned_performance_plot!(x...)
	end
end

# ╔═╡ 3f04b408-1027-4c87-b138-35e63ab4697a
#=╠═╡
learned_performance_plot(means, runs)
  ╠═╡ =#

# ╔═╡ 121a1235-4dd8-4282-8f01-b2d6b743286e
#=╠═╡
ylims=(
	min(means[!, :learned_performance]...) - 200, 
	max(means[!, :learned_performance]...) + 200)
  ╠═╡ =#

# ╔═╡ f00c8154-36be-495e-b681-fd3c24f97561
#=╠═╡
let
	plot(;ylims)
	c = [colors.POMEGRANATE, colors.BELIZE_HOLE, colors.GREEN_SEA, colors.WISTERIA, colors.CARROT]
	for (i, r) in enumerate(means[!, :runs] |> unique)
		learned_performance_plot!(means, r, 
			color=c[i%length(c) + 1], 
			show_other_measurements=false)
	end
	plot!()
end
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═d0db8070-41a9-11ee-2b97-818668d7efa8
# ╟─2bd47b9e-31e3-4ee1-aa87-60dfc40869a9
# ╟─c9e1bc2c-a6f7-4b88-8038-51cf2ef2a008
# ╟─95e38fbd-142d-4926-9291-27e69ddf7c75
# ╠═61c15d44-75be-4613-8b60-484d94847b8a
# ╠═26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
# ╠═1f3a2bee-2817-4314-901e-7dd3743fbab9
# ╠═62086f17-badc-4ec9-a5e8-25ebb0f6cdc8
# ╠═e1ddadeb-e9fd-4c37-a206-dff03363724e
# ╠═7cd7f277-8388-413a-b993-9b81fdb495b8
# ╠═db1720fb-1134-4d81-b0b0-7da700d38798
# ╠═be64568d-f451-46f4-8336-bd94fff82471
# ╠═5484bf48-11be-4ac7-9557-e6fa36802f1d
# ╠═85871e02-b379-4306-a547-1d6239e61fc2
# ╠═a675d6b9-0f2b-4023-af2a-1bb43303f6a7
# ╠═ef7d9898-c2be-493b-913e-51a854d74c32
# ╠═8a8ad7a8-94cb-4f94-9e78-7684091272c8
# ╠═2cc917ff-7098-4c32-a1f8-e75360c37e2c
# ╠═3f04b408-1027-4c87-b138-35e63ab4697a
# ╠═121a1235-4dd8-4282-8f01-b2d6b743286e
# ╠═f00c8154-36be-495e-b681-fd3c24f97561
