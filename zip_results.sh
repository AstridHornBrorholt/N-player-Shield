previous_working_dir="$(pwd)"
cd ~/Results
if [[ -f "N-player.zip" ]]; then
	zip -rf1 "N-player.zip" *
else
	zip -r1 "N-player.zip" *
fi
cd $previous_working_dir