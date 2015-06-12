#!/bin/sh

parameter="${1:-$FALSE}"

if [ $parameter ]; then
  if [ ! $parameter == "init" ]; then
    echo "ERROR: parameter given is not \"init\" .. execution aborted"
    exit 1
  fi
fi

configFile="freifunkconfig.ini.php"

if [ ! -f $configFile ]; then
  echo "ERROR: config file not present/found .. execution aborted"
  exit 1
fi

#-- SETTINGS
chownUser=$(awk -F "=" '/chownUser/ {print $2}' $configFile)
chownGroup=$(awk -F "=" '/chownGroup/ {print $2}' $configFile)
dataDir=$(awk -F "=" '/dataDir/ {print $2}' $configFile)
totalDir=$(awk -F "=" '/totalDir/ {print $2}' $configFile)
urlRequester=$(awk -F "=" '/urlRequester/ {print $2}' $configFile)
netmonUrl=$(awk -F "=" '/netmonUrl/ {print $2}' $configFile)

#-- SCRIPT
crawlFreifunk() {
  paramRouterId=$1
  date=$2
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
      echo "ERROR: setting \"netmonUrl\" not proper set in config file" 1>&2
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

  time=$(date +"%H:%M")
  separator=";"

  output=$time$separator$clients$separator
  echo $output>>$dataFolder/$paramRouterId/$date

  if [ $chownString ]; then
    chown $chownString $dataFolder/$paramRouterId/$date
  fi
}

initFunction() {
  newRouterCounter=0
  newRouterDone=0
  error=""

  while [ $newRouterDone -eq 0 ]; do
    clear
    if [ $newRouterCounter -gt 0 ]; then
      echo -e "Hast du einen weiteren Router den du angeben möchtest?\n(Falls nein, einfach \"ENTER\" drücken)"
    fi
    echo -e "Bitte die Id des zu beobachtenden Freifunk Router angeben$error:"
    read newRouterId
    error=""

    if [ "$newRouterId" -eq "$newRouterId" ] 2>/dev/null; then
      mkdir $dataFolder/$newRouterId
      if [ $chownString ]; then
        chown $chownString $totalFolder
      fi
      ((newRouterCounter++))
    else
      if [ -z $newRouterId ]; then
        if [ $newRouterCounter -gt 0 ]; then
          newRouterDone=1
        fi
      fi
      error="\n[[ERROR: NOT A NUMBER - YOU MUST ENTER A NUMBER]]"
    fi
  done
}

getMaximumValue() {
  paramYesterday=$2
  paramRouterId=$1
  maximumFile="maximum"
  separator=";"

  maximum=$(awk -F";" '($2>=v){v=$2}END{print v}' $dataFolder/$paramRouterId/$paramYesterday)
  output=$paramYesterday$separator$paramRouterId$separator$maximum$separator
  echo $output>>$dataFolder/$maximumFile
  if [ $chownString ]; then
    chown $chownString $dataFolder/$maximumFile
  fi
}

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

#abort script if data-folder could not be created
if [ ! -d $dataFolder ]; then
  echo "ERROR: data folder \"$dataFolder\" does not exist"
  echo "run the script with the parameter \"init\" to create data folder structure"
  exit 1
fi

if [ $parameter ]; then
  #check existence of data-folder and create it if it doesn't
  if [ ! -d $dataFolder ]; then
    mkdir $dataFolder
    if [ $chownString ]; then
      chown $chownString $dataFolder
    fi
  fi

  #abort script if data-folder could not be created
  if [ ! -d $dataFolder ]; then
    echo "ERROR: creating data folder \"$dataFolder\""
    echo "check permissions"
    exit 1
  fi

  #check existence of total-folder and create it if it doesn't
  if [ ! -d $totalFolder ]; then
    mkdir $totalFolder
    if [ $chownString ]; then
      chown $chownString $totalFolder
    fi

    initFunction
  fi
fi

#init counters
total=0
dirCounter=0
date=$(date +"%Y-%m-%d")

#parse data-folder and crawl each router
for D in `find $dataFolder -type d`; do
  if [ $D != $dataFolder ]; then
    if [ ! -f $D/disabled ]; then
      routerId=$(basename $D)
      if [ $routerId != $totalDir ]; then
        ((dirCounter++))
        crawlFreifunk $routerId $date
      fi
    fi
  fi
done

if [ $dirCounter -ge 1 ]; then
  if [ ! -f $totalFolder/$date ]; then
    yesterday=$(date +"%Y-%m-%d" -d "yesterday")
    if [ -f $totalFolder/$yesterday ]; then
      for D in `find $dataFolder -type d`; do
        if [ $D != $dataFolder ]; then
          if [ -f $D/$yesterday ]; then
            routerId=$(basename $D)
            getMaximumValue $routerId $yesterday
          fi
        fi
      done
    fi
  fi

  output=$time$separator$total$separator
  echo $output>>$totalFolder/$date

  if [ $chownString ]; then
    chown $chownString $totalFolder/$date
  fi
fi
