$previous_working_dir=$(pwd)
cd ~/Results
rm "N-player CC.zip"
rm "N-player CC Centralized.zip"
rm "N-player CC Centralized Controller.zip"
zip -r "N-player CC.zip" "N-player CC"/*
zip -r "N-player CC Centralized.zip" "N-player CC Centralized"/*
zip -r "N-player CC Centralized Controller.zip" "N-player CC Centralized Controller"/*
cd $previous_working_dir