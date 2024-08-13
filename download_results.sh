#!/bin/bash

arg1=${1:-"mcc3"}

if [[ "$arg1" == "mcc2" ]]; then
    echo "Downlaoding results from mcc2..."
    scp -rd 'deismcc:/nfs/home/cs.aau.dk/oq82yk/Results/N-player.zip' "$(pwd)" > /dev/null
    unzip -qo "./N-player.zip" -d "$HOME/Results/"
    rm "./N-player.zip"
else 
    echo "Downlaoding results from mcc3..."
    scp -rd 'mcc3:/nfs/home/cs.aau.dk/oq82yk/Results/N-player.zip' "$(pwd)" > /dev/null
    unzip -qo "./N-player.zip" -d "$HOME/Results/"
    rm "./N-player.zip"
fi

./update_filepaths.sh