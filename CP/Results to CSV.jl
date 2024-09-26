### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# ╔═╡ 7d449a33-2530-44a0-9b9c-8c0ffe4ba475
begin
	using Pkg
	Pkg.activate("..")
	using JSON
	using CSV
	using Glob
	using Plots
end;

# ╔═╡ 30662bc6-251c-4c7d-9386-9ecdbe52967d
# ╠═╡ skip_as_script = true
#=╠═╡
begin
	using PlutoUI
	include("../FlatUI Colors.jl")
end
  ╠═╡ =#

# ╔═╡ b28d2e2a-1dc2-4287-8fc4-1e018628844a
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

# ╔═╡ 4e4caf8c-e5d0-4ba0-bfa6-359d924a3261
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

# ╔═╡ 84904510-6cde-447e-980b-db50b69ebabf
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

# ╔═╡ b33347bc-39e4-47f2-911f-288aaca162f7
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

# ╔═╡ c2b5971e-2257-402e-97a9-edac0e7534ad
← = push!

# ╔═╡ 2257d50d-f93d-4347-855a-6adcc044ad88
⨝ = joinpath

# ╔═╡ ffeb8853-b48c-4244-8e87-cb1f1d84a146
#=╠═╡
@bind results_dir TextField(80, default="$(homedir())/Results/N-player CP/")
  ╠═╡ =#

# ╔═╡ 7470f46c-e4cb-414e-8f02-21922e401201
#=╠═╡
`tree $results_dir` |> read |> String |> multiline
  ╠═╡ =#

# ╔═╡ 16f320a0-6b75-4760-86d0-bbbd19cab4a6
#=╠═╡
# Random example path
@bind query_result_path TextField(80, 
	default=rand(glob("* Runs/Repetition */Query Results/Plant *.txt", results_dir)))
  ╠═╡ =#

# ╔═╡ d3d3fd22-4d79-47da-9373-ff59eca2d5d3
#=╠═╡
isfile(query_result_path)
  ╠═╡ =#

# ╔═╡ 79b18fd5-ec6a-4082-9fb9-460fd58c6a7b
#=╠═╡
# Query file corresponding to query_result_path
replace(query_result_path, "Query Results" => "Models", ".txt" => ".q") |> read |> String |> multiline
  ╠═╡ =#

# ╔═╡ df5d99fe-e22e-42e0-b709-dc1c0f72809d
#=╠═╡
(query_result = query_result_path |> read |> String) |> multiline
  ╠═╡ =#

# ╔═╡ 926c21d4-29dc-43c0-8161-72b53692fe94
function firstcapture(re::Regex, str::AbstractString)
	m = match(re, str)
	if isnothing(m)
		error("regex $re not found in string $str")
	end
	m[1]
end

# ╔═╡ 272ca917-5dbd-446e-8bc1-2d044d7631f5
#=╠═╡
firstcapture(r"mean=([0-9.]+)", query_result)
  ╠═╡ =#

# ╔═╡ e900855f-6c9f-41d4-8f1e-9580190a92f8
function extract_results(query_result)
	re_mean = r"mean=(\d+\.?\d*)"
	result = [m[1] for m in eachmatch(re_mean, query_result)]
	result = [parse(Float64, v) for v in result]
end

# ╔═╡ a665c327-d78f-4fef-90f1-ae1acddf73bf
#=╠═╡
extract_results(query_result)
  ╠═╡ =#

# ╔═╡ 5c625d7a-a646-4613-b8dd-b2c246ce0c22
function safety_violation_occured(query_result)
	# The safety query counts how many times the property was satisfied. 
	# I.e. should be (1000/1000). 
	# This is right opposite how I do it in the cruise-control example.
	re_safe = r"\((\d+)/(\d+) runs\)"
	m = match(re_safe, query_result)
	if m[1] == m[2]
		return false
	else
		re_check = r"\(\d+/\d+ runs\)"
		matches = match(re_check, query_result)
		@error "Didn't find a query showing no safety violations. This could be because of a failed regex, or it could be because of an actual safety violation. Check query file." matches
		return true
	end
end

# ╔═╡ 479f1124-24e7-411b-acc5-f19bf908f7d0
#=╠═╡
safety_violation_occured(query_result)
  ╠═╡ =#

# ╔═╡ 1e34748a-20ee-4903-a9b2-a514de81b68a
#=╠═╡
function to_csv(results_dir)
	isdir(results_dir) || error("Not found: results_dir")
	
	header = 
		"runs;repetition;pre_trained_units;untrained_individual_cost;untrained_global_cost;trained_individual_cost;trained_global_cost"
	
	result = String[header]
	for 🗄️ in glob("* Runs", results_dir)
		runs = firstcapture(r"(\d+) Runs", 🗄️)
		for 📁 in glob("Repetition *", 🗄️)
			repetition = firstcapture(r"Repetition (\d+)", 📁)
			for 🗎 in glob("Query Results/Plant *.txt", 📁)
				pre_trained_units = firstcapture(r"Plant (\d+).txt", 🗎)
				pre_trained_units = parse(Int64, pre_trained_units)
				query_results = extract_results(🗎 |> read |> String)
				if length(query_results) != 4
					@warn "Skipping file with unexpected number of query results" file=🗎 expected=4 actual=length(query_results)
					continue
				end
				# Function outputs its own error.
				safety_violation_occured(query_result)
				untrained_individual_cost, untrained_global_cost, trained_individual_cost, trained_global_cost = query_results
				
				push!(result, join(
					[runs, repetition, pre_trained_units,
						untrained_individual_cost, 
						untrained_global_cost, 
						trained_individual_cost, 
						trained_global_cost], ";"))
			end
		end
	end
	join(result, "\n")
end
  ╠═╡ =#

# ╔═╡ b646f1e9-e216-44dc-9566-54fc077a9910
#=╠═╡
(csv = to_csv(results_dir)) |> multiline
  ╠═╡ =#

# ╔═╡ 030b379f-72c9-426b-aa45-32be0220709b
#=╠═╡
let
	buf = IOBuffer()
	print(buf, csv)
	DownloadButton(take!(buf), "Results.csv")
end
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═7d449a33-2530-44a0-9b9c-8c0ffe4ba475
# ╟─b28d2e2a-1dc2-4287-8fc4-1e018628844a
# ╟─4e4caf8c-e5d0-4ba0-bfa6-359d924a3261
# ╟─84904510-6cde-447e-980b-db50b69ebabf
# ╟─b33347bc-39e4-47f2-911f-288aaca162f7
# ╠═30662bc6-251c-4c7d-9386-9ecdbe52967d
# ╠═c2b5971e-2257-402e-97a9-edac0e7534ad
# ╠═2257d50d-f93d-4347-855a-6adcc044ad88
# ╠═ffeb8853-b48c-4244-8e87-cb1f1d84a146
# ╠═7470f46c-e4cb-414e-8f02-21922e401201
# ╠═16f320a0-6b75-4760-86d0-bbbd19cab4a6
# ╠═d3d3fd22-4d79-47da-9373-ff59eca2d5d3
# ╠═79b18fd5-ec6a-4082-9fb9-460fd58c6a7b
# ╠═df5d99fe-e22e-42e0-b709-dc1c0f72809d
# ╠═926c21d4-29dc-43c0-8161-72b53692fe94
# ╠═272ca917-5dbd-446e-8bc1-2d044d7631f5
# ╠═e900855f-6c9f-41d4-8f1e-9580190a92f8
# ╠═a665c327-d78f-4fef-90f1-ae1acddf73bf
# ╠═5c625d7a-a646-4613-b8dd-b2c246ce0c22
# ╠═479f1124-24e7-411b-acc5-f19bf908f7d0
# ╠═1e34748a-20ee-4903-a9b2-a514de81b68a
# ╠═b646f1e9-e216-44dc-9566-54fc077a9910
# ╠═030b379f-72c9-426b-aa45-32be0220709b
