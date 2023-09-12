$previous_working_dir=$(pwd)
cd ~/Results
rm "N-player CC.zip"
rm "N-player CC Centralized.zip"
zip -r "N-player CC.zip" "N-player CC"/*
zip -r "N-player CC Centralized.zip" "N-player CC Centralized"/*
cd $previous_working_dir