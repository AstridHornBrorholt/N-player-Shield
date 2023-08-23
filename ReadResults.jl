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

# ╔═╡ 26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
← = push!

# ╔═╡ 8f12c790-0269-4626-a206-ba6066697d05
#=╠═╡
@bind folder TextField(80, default="$(homedir())/Results/N-player CC/Query Results")
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

# ╔═╡ 95e5cfb9-5de8-4bd6-b1e7-7315b8c619fa
function extract_results(file)
	re_mean = r"mean=(\d+\.\d+)"
	result = [m[1] for m in eachmatch(re_mean, file)]
	result = [parse(Float64, v) for v in result]
end

# ╔═╡ dbe10e8e-ab43-403e-ac7d-687326ea6a0a
#=╠═╡
extract_results(files[1])
  ╠═╡ =#

# ╔═╡ 4680dcec-ae67-4a26-b61a-68ec18bee9c6
#=╠═╡
results = [extract_results(f) for f in files]
  ╠═╡ =#

# ╔═╡ 171cb481-28e5-4c37-aeac-8cded87535d9
#=╠═╡
begin
	plot(legend=:outerright)
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
	plot([r[end] for r in results], 
		label="Learned performance",
		marker=:circle,
		markersize=8,
		markerstrokecolor=:white,
		line=2)
end
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═d0db8070-41a9-11ee-2b97-818668d7efa8
# ╟─2bd47b9e-31e3-4ee1-aa87-60dfc40869a9
# ╠═61c15d44-75be-4613-8b60-484d94847b8a
# ╠═26f87b02-c633-4f45-bdb8-3ecf87ebf7a5
# ╠═8f12c790-0269-4626-a206-ba6066697d05
# ╠═5ac717ee-a3a9-4d03-9506-050173fc996b
# ╠═531b8bda-8ecc-48f4-88de-9d148b4df5ef
# ╠═67e8b215-836e-41b5-a6e0-8a535f5ed585
# ╠═95e5cfb9-5de8-4bd6-b1e7-7315b8c619fa
# ╠═dbe10e8e-ab43-403e-ac7d-687326ea6a0a
# ╠═4680dcec-ae67-4a26-b61a-68ec18bee9c6
# ╠═171cb481-28e5-4c37-aeac-8cded87535d9
# ╠═a1d0165d-112b-4aee-a17a-3ce3a626b0a6
