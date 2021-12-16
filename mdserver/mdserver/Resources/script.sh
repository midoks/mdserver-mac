#! /bin/sh
DIR=$(cd "$(dirname "$0")"; pwd)

doCMD=$1

if [ "$doCMD" == "stop" ];then
    cd /Applications/mdserver/bin && ./stop.sh nginx
elif [[ "$doCMD" == "start" ]]; then
    cd /Applications/mdserver/bin && ./start.sh nginx
elif [[ "$doCMD" == "reload" ]]; then
    cd /Applications/mdserver/bin && ./reloadSVC.sh
fi
