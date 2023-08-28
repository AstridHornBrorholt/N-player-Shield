$previous_working_dir=$(pwd)
cd ~/Results
rm "N-player CC.zip"
zip -r "N-player CC.zip" "N-player CC"/*
cd $previous_working_dir