#!/bin/sh

#-- SETTINGS
chownUser=$(awk -F "=" '/chownUser/ {print $2}' freifunkconfig.ini.php)
chownGroup=$(awk -F "=" '/chownGroup/ {print $2}' freifunkconfig.ini.php)
dataDir=$(awk -F "=" '/dataDir/ {print $2}' freifunkconfig.ini.php)
totalDir=$(awk -F "=" '/totalDir/ {print $2}' freifunkconfig.ini.php)
urlRequester=$(awk -F "=" '/urlRequester/ {print $2}' freifunkconfig.ini.php)
netmonUrl=$(awk -F "=" '/netmonUrl/ {print $2}' freifunkconfig.ini.php)

#-- SCRIPT
crawlFreifunk() {
  paramRouterId=$1
  url=$netmonUrl$paramRouterId
  case $urlRequester in
    "curl" )
      command="curl -s"
      grepParam="(?<=client_count>)[^<]+"
      ;;
    "php" )
      command="php $workingFolder/fileGetContents.php"
      grepParam="(?<=Clients:</b> ).*?(?=<br>)"
      ;;
    * )
      echo "setting `netmonUrl` not proper set in config file" 1>&2
      exit 1
      ;;
  esac
  #url="https://netmon.freifunk-franken.de/api/rest/router/$paramRouterId"
  #clients=$(php $workingFolder/fileGetContents.php $xml | grep -oP '(?<=client_count>)[^<]+')
  #url="https://netmon.freifunk-franken.de/router.php?router_id=$paramRouterId"
  #clients=$(php $workingFolder/fileGetContents.php $url | grep -oP '(?<=Clients:</b> ).*?(?=<br>)')
  #url="https://netmon.freifunk-franken.de/router.php?router_id=$paramRouterId"
  #clients=$(curl -s $url | grep -oP '(?<=Clients:</b> ).*?(?=<br>)')
  clients=$($command $url | grep -oP $grepParam)

  if [ -z "$clients" ]; then
    clients=0
  fi

  [[ $clients == ?(-)+([0-9]) ]] && total=$(($total + $clients))
  date=$(date +"%Y-%m-%d")
  time=$(date +"%H:%M")
  separator=";"

  output=$time$separator$clients$separator
  echo $output>>$dataFolder/$paramRouterId/$date

  if [ $chownString ]; then
    chown $chownString $dataFolder/$paramRouterId/$date
  fi
}

#set data-folder
workingFolder=$(pwd)
if [ ! $dataFolder ]; then
  dataFolder=$workingFolder/"freifunkdata"
elif [ $(echo ${dataFolder} | cut -c1-1) -eq "." ]; then
  dataFolder=$workingFolder/$(echo ${dataFolder} | tail -c +3)
elif [ $(echo ${dataFolder} | cut -c1-1) -eq "/" ]; then
  dataFolder=$dataFolder
else
  dataFolder=$workingFolder/"freifunkdata"
fi

#set total-folder
if [ ! $totalFolder ]; then
  totalFolder=$dataFolder/"Total"
fi

#set chown user and group
chownString=$false
if [ $chownUser ]; then
  chownString="$chownUser"
fi
if [ $chownGroup ]; then
  chownString="$chownString:$chownGroup"
fi

#check existence of data-folder and create if it doesn't
if [ ! -d $dataFolder ]; then
  mkdir $dataFolder
  if [ $chownString ]; then
    chown $chownString $dataFolder
  fi
fi

#abort script if data-folder could not be created
if [ ! -d $dataFolder ]; then
  echo "error creating `dataFolder` \"$dataFolder\"" 1>&2
  exit 1
fi

#check existence of total-folder and create if it doesn't
if [ ! -d $totalFolder ]; then
  mkdir $totalFolder
  if [ $chownString ]; then
    chown $chownString $totalFolder
  fi
fi

#init counters
total=0
dirCounter=0

#parse data-folder and
for D in `find $dataFolder -type d`
do
  if [ $D != $dataFolder ]; then
    if [ ! -f $D/disabled ]; then
      routerId=$(basename $D)
      if [ $routerId != $totalDir ]; then
        ((dirCounter++))
        crawlFreifunk $routerId
      fi
    fi
  fi
done

if [ $dirCounter -ge 1 ]; then
  output=$time$separator$total$separator
  echo $output>>$totalFolder/$date

  if [ $chownString ]; then
    chown $chownString $totalFolder/$date
  fi
fi
