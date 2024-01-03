scp -rd 'deismcc:/nfs/home/cs.aau.dk/oq82yk/Results/N-player\ CC.zip' "$(pwd)" > /dev/null
scp -rd 'deismcc:/nfs/home/cs.aau.dk/oq82yk/Results/N-player\ CP.zip' "$(pwd)" > /dev/null
scp -rd 'deismcc:/nfs/home/cs.aau.dk/oq82yk/Results/N-player\ CC\ Centralized\ Controller.zip' "$(pwd)" > /dev/null
scp -rd 'deismcc:/nfs/home/cs.aau.dk/oq82yk/Results/N-player\ CP\ Centralized\ Controller.zip' "$(pwd)" > /dev/null
scp -rd 'deismcc:/nfs/home/cs.aau.dk/oq82yk/Results/N-player\ CC\ Centralized\ Shield.zip' "$(pwd)" > /dev/null
unzip -qo "./N-player CC.zip" -d "$HOME/Results/"
unzip -qo "./N-player CP.zip" -d "$HOME/Results/"
unzip -qo "./N-player CC Centralized Controller.zip" -d "$HOME/Results/"
unzip -qo "./N-player CP Centralized Controller.zip" -d "$HOME/Results/"
unzip -qo "./N-player CC Centralized Shield.zip" -d "$HOME/Results/"
rm "./N-player CC.zip"
rm "./N-player CP.zip"
rm "./N-player CC Centralized Controller.zip"
rm "./N-player CP Centralized Controller.zip"
rm "./N-player CC Centralized Shield.zip"
sed -i "s>/nfs/home/cs.aau.dk/.*yk>/home/asger>g" $HOME/Results/N-player*/*Runs/Repetition*/Models/*