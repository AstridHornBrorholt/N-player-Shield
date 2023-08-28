scp -rd 'deismcc:/nfs/home/cs.aau.dk/oq82yk/Results/N-player\ CC.zip' "$(pwd)" > /dev/null
unzip -qo "./N-player CC.zip" -d "$HOME/Results/"
rm "./N-player CC.zip"
tree "$HOME/Results/N-player CC"