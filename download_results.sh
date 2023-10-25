scp -rd 'deismcc:/nfs/home/cs.aau.dk/oq82yk/Results/N-player\ CC.zip' "$(pwd)" > /dev/null
scp -rd 'deismcc:/nfs/home/cs.aau.dk/oq82yk/Results/N-player\ CC\ Centralized.zip' "$(pwd)" > /dev/null
unzip -qo "./N-player CC.zip" -d "$HOME/Results/"
unzip -qo "./N-player CC Centralized.zip" -d "$HOME/Results/"
rm "./N-player CC.zip"
rm "./N-player CC Centralized.zip"
tree "$HOME/Results/N-player CC"
tree "$HOME/Results/N-player CC Centralized"
sed -i "s>/nfs/home/cs.aau.dk/.*yk>/home/asger>g" "$HOME/Results/N-player CC*/*Runs/Repetition*/Models/*"