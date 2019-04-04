#!/usr/bin/env bash

lines () {
pid1=0
serv=$1

if [[ -z $serv ]]
then
  echo -e "\e[31m No one parameters got the script. Service name empty.\e[0m"
  return 0
fi

pid1=$(pgrep $serv)        # $1=nginx PID1 PID2

if [[ -z $pid1 ]]
then
   echo -e "\e[31mService $serv is down\e[32m and now will be started.\e[0m"
   systemctl start nginx
else
   echo -e "Service $serv: \e[32mis Active.\e[0m"
fi
}

lines $1
