### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# ╔═╡ 7d449a33-2530-44a0-9b9c-8c0ffe4ba475
begin
	using Pkg
	Pkg.activate("..", io=devnull)
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
@bind results_dir TextField(80, default="$(homedir())/Results/N-player CC/")
  ╠═╡ =#

# ╔═╡ 7470f46c-e4cb-414e-8f02-21922e401201
#=╠═╡
`tree $results_dir` |> read |> String |> multiline
  ╠═╡ =#

# ╔═╡ 16f320a0-6b75-4760-86d0-bbbd19cab4a6
#=╠═╡
# Random example path
query_result_path = rand(glob("* Runs/Repetition */Query Results/Fleet of * Cars.txt", results_dir));
  ╠═╡ =#

# ╔═╡ 5d68db97-1854-4197-a968-72c249409b7f
#=╠═╡
query_result_path |> multiline
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

# ╔═╡ 1d00dac9-a3c1-4a25-b456-87e53c03bb1a
md"""
---
"""

# ╔═╡ 5c625d7a-a646-4613-b8dd-b2c246ce0c22
# Output error if query results seem to indicate a safety violation. 
# This shit is super brittle because it counts hard on there being only ONE Pr[]
# query in the file, and that query being the safety one.
# Assuming safety query on the form 
#    Pr[<=100;100]([] forall (i : int[0, fleetSize - 2]) (distance[i] > minDistance || distance[i] < maxDistance))
function safety_violation_occured(query_result, path=nothing)
	re_safety_evaluation = r"\((\d+)/(\d+) runs\)"
	m = match(re_safety_evaluation, query_result)
	#return m
	if !isnothing(m) && m[1] == m[2]
		return false
	else
		safety_evaluation = isnothing(m) ? "not found!" : m.match
		@error "Didn't find a query showing no safety violations. This could be because of a failed regex, or it could be because of an actual safety violation. Check query file." safety_evaluation path
		return true
	end
end

# ╔═╡ 69b804f5-24e9-420d-81d5-d3112628c795
# ╠═╡ skip_as_script = true
#=╠═╡
safety_violation_occured("ababa (100/1000 runs) asdasdfasdf")
  ╠═╡ =#

# ╔═╡ bd82c2e0-bf72-43fe-a878-87b77d1b7f31
# ╠═╡ skip_as_script = true
#=╠═╡
safety_violation_occured("ababa (1000/1000 runs) asdasdfasdf")
  ╠═╡ =#

# ╔═╡ d2cb5b73-7d26-40bb-9aa3-53570eb73ebf
# ╠═╡ skip_as_script = true
#=╠═╡
safety_violation_occured("ababa asdasdfasdf")
  ╠═╡ =#

# ╔═╡ 479f1124-24e7-411b-acc5-f19bf908f7d0
# ╠═╡ skip_as_script = true
#=╠═╡
safety_violation_occured(query_result)
  ╠═╡ =#

# ╔═╡ 1b47dcac-5ba2-4b08-a55f-59e1887f9705
md"""
---
"""

# ╔═╡ 1e34748a-20ee-4903-a9b2-a514de81b68a
function to_csv(results_dir)
	isdir(results_dir) || error("Not found: $results_dir")
	header = "runs;repetition;fleet_size;learned_performance;other_cars"
	result = String[header]
	for 🗄️ in glob("* Runs", results_dir)
		runs = firstcapture(r"(\d+) Runs", 🗄️)
		for 📁 in glob("Repetition *", 🗄️)
			repetition = firstcapture(r"Repetition (\d+)", 📁)
			for 🗎 in glob("Query Results/Fleet of * Cars.txt", 📁)
				fleet_size = firstcapture(r"Fleet of (\d+) Cars.txt", 🗎)
				fleet_size = parse(Int64, fleet_size)
				query_result_str = 🗎 |> read |> String
				query_results = extract_results(query_result_str)
				if length(query_results) != fleet_size - 1 
					@warn "Skipping file with unexpected number of query results" file=🗎 expected=fleet_size - 1 actual=length(query_results)
					continue
				end
				safety_violation_occured(query_result_str, 🗎)
				learned_performance = query_results[end]
				other_cars = query_results[1:end - 1]
				if length(other_cars) == 0
					other_cars = "[]"
				end
				push!(result, "$runs;$repetition;$fleet_size;$learned_performance;$other_cars")
			end
		end
	end
	join(result, "\n")
end

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
# ╠═5d68db97-1854-4197-a968-72c249409b7f
# ╠═79b18fd5-ec6a-4082-9fb9-460fd58c6a7b
# ╠═df5d99fe-e22e-42e0-b709-dc1c0f72809d
# ╠═926c21d4-29dc-43c0-8161-72b53692fe94
# ╠═272ca917-5dbd-446e-8bc1-2d044d7631f5
# ╠═e900855f-6c9f-41d4-8f1e-9580190a92f8
# ╠═a665c327-d78f-4fef-90f1-ae1acddf73bf
# ╟─1d00dac9-a3c1-4a25-b456-87e53c03bb1a
# ╠═5c625d7a-a646-4613-b8dd-b2c246ce0c22
# ╠═69b804f5-24e9-420d-81d5-d3112628c795
# ╠═bd82c2e0-bf72-43fe-a878-87b77d1b7f31
# ╠═d2cb5b73-7d26-40bb-9aa3-53570eb73ebf
# ╠═479f1124-24e7-411b-acc5-f19bf908f7d0
# ╟─1b47dcac-5ba2-4b08-a55f-59e1887f9705
# ╠═1e34748a-20ee-4903-a9b2-a514de81b68a
# ╠═b646f1e9-e216-44dc-9566-54fc077a9910
# ╠═030b379f-72c9-426b-aa45-32be0220709b
