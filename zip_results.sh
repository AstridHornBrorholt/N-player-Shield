$previous_working_dir=$(pwd)
cd ~/Results
rm "N-player CC.zip"
rm "N-player CP.zip"
rm "N-player CC Centralized Shield.zip"
rm "N-player CC Centralized Controller.zip"
zip -r "N-player CC.zip" "N-player CC"/*
zip -r "N-player CP.zip" "N-player CP"/*
zip -r "N-player CC Centralized Shield.zip" "N-player CC Centralized Shield"/*
zip -r "N-player CC Centralized Controller.zip" "N-player CC Centralized Controller"/*
cd $previous_working_dir