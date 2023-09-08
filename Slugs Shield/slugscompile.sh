previous_working_dir=$(pwd)
file_to_compile=$(realpath "$1")
output_name=$(basename "$1" .structuredslugs)
cd /home/asger/Code/slugs/tools/StructuredSlugsParser/
./compiler.py "$file_to_compile" > "$previous_working_dir/$output_name.slugsin"
cd "$previous_working_dir"
slugs --explicitStrategy "$output_name.slugsin" > "$output_name.explicitstrategy"