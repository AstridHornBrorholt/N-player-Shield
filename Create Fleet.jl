### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ 488ee430-40cf-11ee-3160-1f10b20c5be6
begin
	using Pkg
	Pkg.activate(".")
	using JSON
	using Glob
	using ArgParse
	include("Strategy to C.jl")
end;

# ╔═╡ d2d9ca40-af15-4a65-910e-0319065cd6bf
# ╠═╡ skip_as_script = true
#=╠═╡
using PlutoUI
  ╠═╡ =#

# ╔═╡ 5476773a-3daa-4c81-be1a-b29c2b2033b0
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

# ╔═╡ 627b26ba-0479-41fd-9b0d-94df3c1d3ae0
#=╠═╡
@bind number_of_strategies NumberField(0:10)
  ╠═╡ =#

# ╔═╡ 18664fb8-d399-4fc0-ba01-96ffe552a8ce
md"""
## Compiling the Strategies
"""

# ╔═╡ 303b180c-274c-4a29-b786-660fae7209b8
#=╠═╡
function strategy_paths_input(number_of_strategies)
	
	return PlutoUI.combine() do Child
		names = ["$i" for i in 1:number_of_strategies]
		inputs = [
			md""" $(name): $(
				Child(name, TextField(70, default = "/home/asger/Results/N-player CC/Models/car" * name * ".json"))
			)"""
			
			for name in names
		]
		
		md"""
		#### Strategy paths
		$(inputs)
		"""
	end
end
  ╠═╡ =#

# ╔═╡ 5daa0ac6-d6c5-4ca7-8f7c-d3efdf89d66b
#=╠═╡
@bind strategy_paths strategy_paths_input(number_of_strategies)
  ╠═╡ =#

# ╔═╡ 9c5f6402-1cc5-4922-a3b3-02676c15b36d
#=╠═╡
[isfile(s) for s in strategy_paths]
  ╠═╡ =#

# ╔═╡ 5da6f4cd-96fa-4d58-9381-ca32b917efe5
#=╠═╡
@bind output_dir TextField(70, default=mktempdir())
  ╠═╡ =#

# ╔═╡ 6faf4945-da06-4ce8-8f79-2db5fb321ce1
vars = [
	"velocity",
	"velocity_front",
	"distance"
]

# ╔═╡ 9228d33d-bfe8-4c96-9e11-815fa674a5b6
actions = Dict(
	"0" => "NegativeAcceleration",
	"1" => "PositiveAcceleration",
	"2" => "NoAcceleration"
)

# ╔═╡ 7c2cdf08-7180-423a-9c36-55f4fc2ecc02
← = push!

# ╔═╡ 883e028a-7651-4dc1-a55d-708eb9fff889


# ╔═╡ 265701e4-9cd6-4834-af7d-df02bbd976ec
function strategies_to_c(strategy_paths, output_dir)
	result = Tuple{String, String}[]
	for strategy_path in strategy_paths
		!isfile(strategy_path) && error("No such file: $strategy_path")
		result ← strategy_to_c(strategy_path, vars, actions, output_dir)
		strategy_path == output_dir ⨝ basename(strategy_path) || 		cp(strategy_path, output_dir ⨝ basename(strategy_path), force=true)
	end
	result
end

# ╔═╡ 91f00f7e-43b7-47c5-970b-ee4f0c6100b4
#=╠═╡
if all(isfile(strategy_path) for strategy_path in strategy_paths) && isdir(output_dir)
	strategies = strategies_to_c(strategy_paths, output_dir)
else
	strategies = [
		("int get_action_somestrategy1(double velocity, etc etc)", "path/to/lib1.so")
		("int get_action_somestrategy2(double velocity, etc etc)", "path/to/lib2.so")
		("int get_action_somestrategy3(double velocity, etc etc)", "path/to/lib3.so")
		("int get_action_somestrategy4(double velocity, etc etc)", "path/to/lib4.so")
	]
	"One or more strat paths invalid, or output dir invalid."
end
  ╠═╡ =#

# ╔═╡ 695ffd13-dc54-48e0-a8a4-364cd938e640
#=╠═╡
readdir(output_dir)
  ╠═╡ =#

# ╔═╡ c5f3e21f-b929-41e1-81e2-7b0ec2dd0f28
md"""
## Filling out the Template Fields

Fields in the blueprint surrouned with `%`. Functions or variable names here are meant to correspond to field names.
"""

# ╔═╡ 6ba15d9e-1490-47a3-ac77-288eae1dc281
#=╠═╡
@bind shield_path TextField(80, default = "/home/asger/Documents/Files/Arbejde/AAU/N-player Shield/Shield/libshield.so")
  ╠═╡ =#

# ╔═╡ b8e7846b-e9aa-4d8f-a175-0c596f1ea4fb
#=╠═╡
isfile(shield_path)
  ╠═╡ =#

# ╔═╡ 73225f3b-eed4-403b-a564-dad605862566
function multiline(str)
	HTML("""
	<pre style='max-height:30em; margin:8pt 0 8pt 0; overflow-y:scroll'>
	$str
	</pre>
	""")
end

# ╔═╡ e5e56986-4728-480e-8c07-cb78c61e9579
function imports(strategies::T) where T <: AbstractVector{Tuple{String, String}}
	result = String[]
	for (signature, path) in strategies
		result ← "import \"$path\""
		result ← "{"
		result ← "\t" * signature * ";"
		result ← "};\n"
	end
	join(result, "\n")
end

# ╔═╡ d642235d-8da6-4a9c-b346-1c01ba5ef885
#=╠═╡
imports(strategies) |> multiline
  ╠═╡ =#

# ╔═╡ 468c1f4a-a306-4a16-aa42-dc7e7728d959
function name_from_signature(signature)
	# Trust me on this one.
	without_type = signature[findfirst((==)(' '), signature) + 1:end]
	without_type[1:findfirst((==)('('), without_type) - 1]
end

# ╔═╡ 90043fd6-5214-4d4b-8e3f-cd2427a90b28
#=╠═╡
name_from_signature(strategies[1][1])
  ╠═╡ =#

# ╔═╡ 654632ba-3f6a-4453-81fb-24d7bc566a69
function agent_selector(strategies)
	result = String[]
	for (i, (signature, path)) in enumerate(strategies)
		fname = name_from_signature(signature)
		if i == 1
			result ← "    if (i == 1)"
		else
			result ← "    else if (i == $i)"
		end
		result ←     "        return $fname(velocity[$i], velocity[$(i - 1)], distance[$(i - 1)]);"
	end
	join(result, "\n")
end

# ╔═╡ 81a2de17-4954-4110-a39b-b775c85c9dfb
#=╠═╡
agent_selector(strategies) |> multiline
  ╠═╡ =#

# ╔═╡ 41bd6a0e-d6ff-4e40-8eb7-313eb069c74a
function system_declaration(number_of_strategies)
	result = String[]
	result ← "Random0 = Random(0);"
	for i in 1:number_of_strategies
		result ← "Shield$i = Shield($i);"
		result ← "PreTrained$i = PreTrained($i);"
	end
	l = number_of_strategies + 1 # Learner index
	result ← "Shield$l = Shield($l);"
	result ← "Learner$l = Learner($l);"
	
	system = String[]
	system ← "system Dynamics"
	system ← "Decisions"
	system ← "Random0"
	for i in 1:number_of_strategies
		system ← "PreTrained$i"
		system ← "Shield$i"
	end
	system ← "Learner$l"
	system ← "Shield$l"
	
	result ← join(system, ", ") * ";"
	
	join(result, "\n")
end

# ╔═╡ c9c5938f-13ec-496f-afbf-a05f85f32376
system_declaration(0) |> multiline

# ╔═╡ 09bf3c4b-acc9-4bcc-a730-b98bd3c27e36
system_declaration(1) |> multiline

# ╔═╡ ca86cb1d-4fab-4fe7-b89e-7c8e785a9de2
system_declaration(4) |> multiline

# ╔═╡ 87e6dab6-d7b4-4cfa-a2ca-64bb68fd86c8
function distances(number_of_strategies)
	join(["50" for i in 1:number_of_strategies+1], ", ")
end

# ╔═╡ 508e4bba-a3c1-4cfa-9e7f-ecff3abdf047
distances(0)

# ╔═╡ e2b8060b-b9cd-4123-a0dc-7317d5177fe3
distances(1)

# ╔═╡ 37ebb59c-2fe6-4a2e-8e41-fedf162c57c9
distances(4)

# ╔═╡ 02e79c81-018d-4362-996a-17ad7da9ce5d
md"""
## The query files

These will be easiest to generate in the same swoop.
"""

# ╔═╡ c7baa1ea-5252-4319-adfd-d003aa8ee0df
function queries(number_of_strategies, output_path; checks=1000)
	result = String[]
	for i in 0:number_of_strategies-1
		result ← "E[<=100;$checks](max:D[$(i)])"
	end
	i = number_of_strategies + 1
	result ← "strategy car$i = minE(D[$(i - 1)]) [<=100] {}->{velocity[$i], velocity[$(i - 1)], distance[$(i - 1)]}: <> time >= 100"
	result ← "saveStrategy(\"$output_path/car$i.json\", car$i)"
	result ← "E[<=100;$checks](max:D[$(i - 1)]) under car$i"
	# Probability of safety violation
	result ← "Pr[<=100;1000](<> forall (i : int[0, fleetSize - 2]) (distance[i] < minDistance || distance[i] > maxDistance)) under car$i"

	join(result, "\n")
end

# ╔═╡ b4a1cd41-d5ea-4256-9639-6eba84c6d356
queries(0, "/some/path") |> multiline

# ╔═╡ c5a94d34-c472-49ed-aeda-6b902ec2d173
queries(1, "/some/path") |> multiline

# ╔═╡ 2c37d3cb-4829-4e05-8ab7-15cf908b09ad
queries(4, "/some/path") |> multiline

# ╔═╡ a87b61c0-fbf3-464c-ae7c-6aced2b0674d
md"""
## Applying it to the Blueprint
"""

# ╔═╡ fade61a9-8136-4a4c-99a2-dee9bf79fd32
#=╠═╡
@bind blueprint_path TextField(80, default="/home/asger/Documents/Files/Arbejde/AAU/N-player Shield/Fleet_blueprint.xml")
  ╠═╡ =#

# ╔═╡ a0e02d1a-0355-4496-9b18-70f53c67a389
#=╠═╡
isfile(blueprint_path)
  ╠═╡ =#

# ╔═╡ dc00019b-ca42-49e8-a9e7-7c326b3082db
#=╠═╡
@bind destination TextField(80, default="/home/asger/Results/N-player CC")
  ╠═╡ =#

# ╔═╡ 4a634cea-cbe4-4454-aee0-1525b526b48a
#=╠═╡
isdir(destination)
  ╠═╡ =#

# ╔═╡ 9baf5bef-2632-4d4d-8ee6-17a58db86c1a
function search_and_replace(input_path, output_path, replacements)
	file = input_path |> read |> String
	outfile = output_path
	
	open(outfile, "w") do io
		for line in split(file, "\n")
			line′ = replace(line, replacements...)
			println(io, line′)
		end
	end
end

# ╔═╡ a05921d4-4765-44bf-9592-b9d54de3ac65
# Use to check that everything's been serach-and-replace'd.
# r"%[a-zA-Z_ ]+%" to match %template_variables%
function error_on_regex_in(dir, expression, glob_pattern="*")
	pattern_found = false
	if isdir(dir)
		for filename in glob(glob_pattern, dir)
			
			file = filename |> read |> String
			line_number = 1
			for line in split(file, "\n")
				m = match(expression, line)
				if m != nothing
					@error("Pattern found", line, filename, line_number)
				end
				line_number += 1
			end
		end
	elseif isfile(dir)
		file = dir |> read |> String
		line_number = 1
		for line in split(file, "\n")
			m = match(expression, line)
			if m != nothing
				@error("Pattern found", line, dir, line_number)
			end
			line_number += 1
		end
	else
		error("Invalid path"; dir)
	end
	if pattern_found
		error("A pattern was found wich indicates an error. See previous error logs.")
	end
end

# ╔═╡ 96aaff55-db70-4e32-b405-decad1a887c0
"""
	create_fleet(blueprint_path, strategy_paths, destination; [checks])

**Arguments:**
- `blueprint_path`: Path to the blueprint for the Cruise Control "Fleet" UPPAAL model. It contains a number of `%template fields%` to be filled in by this function.
- `strategy_paths`: Vector of zero or more paths to exported UPPAAL strategies in json format. The number of strategies provided determines the number of cars in the fleet.
- `shield_path`: Path to the compiled safety strategy, `libshield.so`.
- `destination`: Output folder.
- `checks`: Number of traces to check in query files. (`E[<=100;\$checks] ...`).

Create model and query files `Fleet of n Cars.xml` and `Fleet of n Cars.q` at `destination`. `n` is given by the number of strategies provided. 

!!! example
		create_fleet("path/to/Fleet_blueprint.xml", ["strat1.json", "strat2.json", "strat3.json"], "libshield.so", "Output Folder")
		-> ("Output Folder/Fleet of 5 Cars.xml", "Output folder/Fleet of 5 Cars.q")
	If 3 previous strategies are provided, a fleet of 5 cars will be created: 1 random car in front, 3 pre-trained cars loaded as compiled stategies, and 1 new learner car. 
"""
function create_fleet(blueprint_path, 
		strategy_paths, 
		shield_path, 
		destination; 
		checks=100)
	
	# UPPAAL wants absolute paths
	strategy_paths = [abspath(p) for p in strategy_paths if p != ""]
	shield_path = abspath(shield_path)
	
	# Create output dir
	if destination |> isdir
	elseif destination |> dirname |> isdir
		mkdir(destination)
	else
		error("Invalid destination"; destination)
	end
	model_dir = destination ⨝ "Models"
	isdir(model_dir) || mkdir(model_dir)
	

	# Compile strategies
	strategies = strategies_to_c(strategy_paths, model_dir)

	# Compute replacements
	replacements = Dict{String, String}()
	replacements["%shield path%"] = "\"$shield_path\""
	fleet_size = length(strategy_paths) + 2 
	replacements["%fleet size%"] = fleet_size |> string
	number_of_strategies = length(strategy_paths)
	replacements["%distances%"] = distances(number_of_strategies)
	replacements["%imports%"] = imports(strategies)
	replacements["%agent selector%"] = agent_selector(strategies)
	replacements["%system declaration%"] = system_declaration(number_of_strategies)
	

	# Apply replacements to blueprint
	model_path = model_dir ⨝ "Fleet of $fleet_size Cars.xml"
	search_and_replace(blueprint_path, model_path, replacements)
	
	error_on_regex_in(model_path, r"%")

	# Save queries, too
	queries_path = model_dir ⨝ "Fleet of $fleet_size Cars.q"
	open(queries_path, "w") do query_file
		print(query_file, queries(number_of_strategies, model_dir; checks))
	end

	model_path, queries_path
end;

# ╔═╡ 86082ab2-b9c3-4575-b878-b2734044e7d6
#=╠═╡
create_fleet(blueprint_path, strategy_paths, shield_path, destination)
  ╠═╡ =#

# ╔═╡ a99d74ed-cc83-41f7-910b-5df140129d3f
md"""
## ArgParse

Support for running this script from the command line.
"""

# ╔═╡ a3e1e009-7d3d-4be8-9f76-ae64bace2514
# ╠═╡ disabled = true
#=╠═╡
begin
	s = ArgParseSettings()
	@add_arg_table s begin
	     "--blueprint-path"
			arg_type=String
			required=true
		"--strategy-paths"
			arg_type=String
			nargs='*'
			required=true
		"--shield-path"
			arg_type=String
			required=true
		"--destination"
			arg_type=String
			required=true
		"--checks"
			arg_type=Int
			default=100
			required=false
	end
end;
  ╠═╡ =#

# ╔═╡ 8eb7b2c0-6c8e-4b4e-adf2-a0b67f819caf
#=╠═╡
if !occursin("#==#", @__FILE__) let
	args = parse_args(s)

	model, queries = create_fleet(
		args["blueprint-path"], 
		args["strategy-paths"], 
		args["shield-path"], 
		args["destination"],
		checks=args["checks"])
	println("'$model' '$queries'")
end end
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═488ee430-40cf-11ee-3160-1f10b20c5be6
# ╟─5476773a-3daa-4c81-be1a-b29c2b2033b0
# ╠═d2d9ca40-af15-4a65-910e-0319065cd6bf
# ╠═627b26ba-0479-41fd-9b0d-94df3c1d3ae0
# ╟─18664fb8-d399-4fc0-ba01-96ffe552a8ce
# ╠═5daa0ac6-d6c5-4ca7-8f7c-d3efdf89d66b
# ╠═9c5f6402-1cc5-4922-a3b3-02676c15b36d
# ╟─303b180c-274c-4a29-b786-660fae7209b8
# ╠═5da6f4cd-96fa-4d58-9381-ca32b917efe5
# ╠═6faf4945-da06-4ce8-8f79-2db5fb321ce1
# ╠═9228d33d-bfe8-4c96-9e11-815fa674a5b6
# ╠═7c2cdf08-7180-423a-9c36-55f4fc2ecc02
# ╠═883e028a-7651-4dc1-a55d-708eb9fff889
# ╠═265701e4-9cd6-4834-af7d-df02bbd976ec
# ╠═91f00f7e-43b7-47c5-970b-ee4f0c6100b4
# ╠═695ffd13-dc54-48e0-a8a4-364cd938e640
# ╟─c5f3e21f-b929-41e1-81e2-7b0ec2dd0f28
# ╠═6ba15d9e-1490-47a3-ac77-288eae1dc281
# ╠═b8e7846b-e9aa-4d8f-a175-0c596f1ea4fb
# ╠═73225f3b-eed4-403b-a564-dad605862566
# ╠═e5e56986-4728-480e-8c07-cb78c61e9579
# ╠═d642235d-8da6-4a9c-b346-1c01ba5ef885
# ╠═468c1f4a-a306-4a16-aa42-dc7e7728d959
# ╠═90043fd6-5214-4d4b-8e3f-cd2427a90b28
# ╠═654632ba-3f6a-4453-81fb-24d7bc566a69
# ╠═81a2de17-4954-4110-a39b-b775c85c9dfb
# ╠═41bd6a0e-d6ff-4e40-8eb7-313eb069c74a
# ╠═c9c5938f-13ec-496f-afbf-a05f85f32376
# ╠═09bf3c4b-acc9-4bcc-a730-b98bd3c27e36
# ╠═ca86cb1d-4fab-4fe7-b89e-7c8e785a9de2
# ╠═87e6dab6-d7b4-4cfa-a2ca-64bb68fd86c8
# ╠═508e4bba-a3c1-4cfa-9e7f-ecff3abdf047
# ╠═e2b8060b-b9cd-4123-a0dc-7317d5177fe3
# ╠═37ebb59c-2fe6-4a2e-8e41-fedf162c57c9
# ╟─02e79c81-018d-4362-996a-17ad7da9ce5d
# ╠═c7baa1ea-5252-4319-adfd-d003aa8ee0df
# ╠═b4a1cd41-d5ea-4256-9639-6eba84c6d356
# ╠═c5a94d34-c472-49ed-aeda-6b902ec2d173
# ╠═2c37d3cb-4829-4e05-8ab7-15cf908b09ad
# ╟─a87b61c0-fbf3-464c-ae7c-6aced2b0674d
# ╠═fade61a9-8136-4a4c-99a2-dee9bf79fd32
# ╠═a0e02d1a-0355-4496-9b18-70f53c67a389
# ╠═dc00019b-ca42-49e8-a9e7-7c326b3082db
# ╠═4a634cea-cbe4-4454-aee0-1525b526b48a
# ╠═9baf5bef-2632-4d4d-8ee6-17a58db86c1a
# ╠═a05921d4-4765-44bf-9592-b9d54de3ac65
# ╠═96aaff55-db70-4e32-b405-decad1a887c0
# ╠═86082ab2-b9c3-4575-b878-b2734044e7d6
# ╟─a99d74ed-cc83-41f7-910b-5df140129d3f
# ╠═a3e1e009-7d3d-4be8-9f76-ae64bace2514
# ╠═8eb7b2c0-6c8e-4b4e-adf2-a0b67f819caf
