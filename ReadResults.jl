### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ d0db8070-41a9-11ee-2b97-818668d7efa8
begin
	using Pkg
	Pkg.activate(".")
	using JSON
	using Glob
	using Plots
	include("Strategy to C.jl")
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

# ╔═╡ 82da6cf2-7872-4021-8bfc-37b74000cd8f
#=╠═╡
@bind subfolder Select(readdir("$(homedir())/Results/N-player CC/"))
  ╠═╡ =#

# ╔═╡ 8f12c790-0269-4626-a206-ba6066697d05
#=╠═╡
@bind folder TextField(80, default="$(homedir())/Results/N-player CC/$subfolder/Query Results")
  ╠═╡ =#

# ╔═╡ 5ac717ee-a3a9-4d03-9506-050173fc996b
#=╠═╡
isdir(folder)
  ╠═╡ =#

# ╔═╡ 531b8bda-8ecc-48f4-88de-9d148b4df5ef
function read_files(folder::T) where T<:AbstractString
	files = String[]
	for file_path in glob("*", folder)
		file = file_path |> read |> String
		files ← file
	end
	files
end

# ╔═╡ 67e8b215-836e-41b5-a6e0-8a535f5ed585
#=╠═╡
files = read_files(folder)
  ╠═╡ =#

# ╔═╡ bb7d14c1-c609-4642-aa74-61ee233a7264
#=╠═╡
@bind 🐟 NumberField(1:length(files))
  ╠═╡ =#

# ╔═╡ 62aca942-8315-4212-b65f-4b2eeff54a91
#=╠═╡
multiline(files[🐟])
  ╠═╡ =#

# ╔═╡ 95e5cfb9-5de8-4bd6-b1e7-7315b8c619fa
function extract_results(file)
	re_mean = r"mean=(\d+\.\d+)"
	result = [m[1] for m in eachmatch(re_mean, file)]
	result = [parse(Float64, v) for v in result]
end

# ╔═╡ 4eba4ebc-e0eb-48a3-a835-3acb21747d64
multiline

# ╔═╡ f8b89f55-4667-45ab-aefc-30d1e41de4d5
function safety_violation_occured(file)
	re_safe = r"\(0/\d+ runs\)"
	if occursin(re_safe, file)
		return false
	else
		re_check = r"\(\d+/\d+ runs\)"
		matches = match(re_check, file)
		@warn "Didn't find a run showing no safety violations. This could be because of a failed regex, or it could be because of an actual safety violation. Check query file." matches
		return true
	end
end

# ╔═╡ 2194dd37-0bd1-4273-b9da-323401d8285e
#=╠═╡
safety_violation_occured(files[🐟])
  ╠═╡ =#

# ╔═╡ 2ed0bf96-9c36-49f9-aff0-ab6533b66f6d
#=╠═╡
if any(safety_violation_occured(file) for file in files)
	md"""
	!!! danger "Possible Safety violation."
		One of the files did not have a query showing 0 unsafe traces. Either this query didn't run, wasn't properly matched with regex, or it contains a safety violation. Check warnings in this file for the same message and a list of matches in that file.
	"""
else
	md"""
	!!! success "All safe"
		Every file has a `(0/xxx runs)` entry, implying that the statistical query estimating the probablility of safety violation encountered no unsafe traces.
	"""
end
  ╠═╡ =#

# ╔═╡ dbe10e8e-ab43-403e-ac7d-687326ea6a0a
#=╠═╡
extract_results(files[🐟])
  ╠═╡ =#

# ╔═╡ 4680dcec-ae67-4a26-b61a-68ec18bee9c6
#=╠═╡
results = [extract_results(f) for f in files]
  ╠═╡ =#

# ╔═╡ dbae0f8e-e1cc-4299-90ff-e6a486e930f7
#=╠═╡
ylims = (min(2000, (results |> Iterators.flatten)...), max(3100, (results |> Iterators.flatten)...))
  ╠═╡ =#

# ╔═╡ 171cb481-28e5-4c37-aeac-8cded87535d9
#=╠═╡
begin
	plot(legend=:outerright,
		ylims=ylims)
	
	markers = [:circle, :utriangle, :square, :star]
	for (i, vs) in enumerate(results)
		plot!(vs, 
			line=2,
			label="Fleet of $(i+2) Cars",
			marker=markers[1 + i%length(markers)],
			markersize=8,
			markerstrokecolor=:white)
	end
	plot!()
end
  ╠═╡ =#

# ╔═╡ a1d0165d-112b-4aee-a17a-3ce3a626b0a6
#=╠═╡
begin
	plot([r[end] for r in results if length(r) > 0], 
		label="Learned performance",
		marker=:circle,
		markersize=8,
		markerstrokecolor=:white,
		line=2,
		ylims=ylims)
end
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═d0db8070-41a9-11ee-2b97-818668d7efa8
# ╟─2bd47b9e-31e3-4ee1-aa87-60dfc40869a9
# ╠═95e38fbd-142d-4926-9291-27e69ddf7c75
# ╠═61c15d44-75be-4613-8b60-484d94847b8a
# ╠═26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
# ╠═82da6cf2-7872-4021-8bfc-37b74000cd8f
# ╠═8f12c790-0269-4626-a206-ba6066697d05
# ╠═5ac717ee-a3a9-4d03-9506-050173fc996b
# ╠═531b8bda-8ecc-48f4-88de-9d148b4df5ef
# ╠═67e8b215-836e-41b5-a6e0-8a535f5ed585
# ╠═bb7d14c1-c609-4642-aa74-61ee233a7264
# ╠═62aca942-8315-4212-b65f-4b2eeff54a91
# ╠═95e5cfb9-5de8-4bd6-b1e7-7315b8c619fa
# ╠═4eba4ebc-e0eb-48a3-a835-3acb21747d64
# ╠═f8b89f55-4667-45ab-aefc-30d1e41de4d5
# ╠═2194dd37-0bd1-4273-b9da-323401d8285e
# ╟─2ed0bf96-9c36-49f9-aff0-ab6533b66f6d
# ╠═dbe10e8e-ab43-403e-ac7d-687326ea6a0a
# ╠═4680dcec-ae67-4a26-b61a-68ec18bee9c6
# ╠═dbae0f8e-e1cc-4299-90ff-e6a486e930f7
# ╠═171cb481-28e5-4c37-aeac-8cded87535d9
# ╠═a1d0165d-112b-4aee-a17a-3ce3a626b0a6
