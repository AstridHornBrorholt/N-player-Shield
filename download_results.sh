scp -rd 'deismcc:/nfs/home/cs.aau.dk/oq82yk/Results/N-player.zip' "$(pwd)" > /dev/null
unzip -qo "./N-player.zip" -d "$HOME/Results/"
rm "./N-player.zip"

scp -rd 'mcc3:/nfs/home/cs.aau.dk/oq82yk/Results/N-player.zip' "$(pwd)" > /dev/null
unzip -qo "./N-player.zip" -d "$HOME/Results/"
rm "./N-player.zip"

./update_filepaths.sh