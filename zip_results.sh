$previous_working_dir=$(pwd)
cd ~/Results
rm "N-player.zip"
zip -rf1 "N-player.zip" "N-player *"/*
cd $previous_working_dir