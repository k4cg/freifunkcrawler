#!/bin/sh
parameter="${1:-$FALSE}"
RED='\033[0;31m'
NC='\033[0m' # No Color

echoError() {
  errorMessage=$1
  echo -e "${RED}$errorMessage${NC}"
  exit 1
}

if [ $parameter ]; then
  if [ ! $parameter == "init" ]; then
    echoError "FEHLER: Der angehängt Parameter ist nicht \"init\" .. Ausführung abgebrochen."
  else
    initParameter=true
  fi
fi

#get working directory (http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
workingDir=$DIR

configFile="$workingDir/freifunkconfig.ini.php"

if [ ! -f $configFile ]; then
  echoError "FEHLER: Die Konfigurationsdatei wurde nicht gefunden oder existiert nicht .. Ausführung abgebrochen."
fi

chownUser=$(awk -F "=" '/chownUser/ {print $2}' $configFile)
chownGroup=$(awk -F "=" '/chownGroup/ {print $2}' $configFile)
dataDir=$(awk -F "=" '/dataDir/ {print $2}' $configFile)
totalDir=$(awk -F "=" '/totalDir/ {print $2}' $configFile)
urlRequester=$(awk -F "=" '/urlRequester/ {print $2}' $configFile)
netmonUrl=$(awk -F "=" '/netmonUrl/ {print $2}' $configFile)

crawlFreifunk() {
  paramRouterId=$1
  date=$2
  url=$netmonUrl$paramRouterId
  case $urlRequester in
    "curl" )
      command="curl -s"
      ;;
    "php" )
      command="php $workingDir/fileGetContents.php"
      ;;
    * )
      echoError "FEHLER: Die Option \"netmonUrl\" wurde in der Konfigurationsdatei nicht korrekt gesetzt .. Ausführung abgebrochen."
      ;;
  esac

  grepParam="(?<=client_count>)[^<]+"
  clients=$($command $url | grep -oP $grepParam)

  if [ -z "$clients" ]; then
    clients=0
  fi

  [[ $clients == ?(-)+([0-9]) ]] && total=$(($total + $clients))

  time=$(date +"%H:%M")
  separator=";"

  output=$time$separator$clients$separator
  echo $output>>$dataDir/$paramRouterId/$date

  if [ $chownString ]; then
    chown $chownString $dataDir/$paramRouterId/$date
  fi
}

initFunction() {
  newRouterCounter=0
  newRouterDone=0
  error=""

  while [ $newRouterDone -eq 0 ]; do
    clear
    if [ $newRouterCounter -gt 0 ]; then
      echo -e "Hast du einen weiteren Router den du beobachten möchtest?\n(Falls nein, einfach \"ENTER\" drücken)"
    fi
    echo -e "Bitte die Id des zu beobachtenden Freifunk Router angeben$error:"
    read newRouterId
    error=""

    if [ "$newRouterId" -eq "$newRouterId" ] 2>/dev/null; then
      mkdir $dataDir/$newRouterId
      if [ $chownString ]; then
        chown $chownString $totalDir
      fi
      ((newRouterCounter++))
    else
      if [ -z $newRouterId ]; then
        if [ $newRouterCounter -gt 0 ]; then
          newRouterDone=1
        fi
      fi
      error="\n${RED}FEHLER: Die Eingabe war keine Zahl .. nur Zahlen können eingegeben werden${NC}"
    fi
  done
  echo "in Bearbeitung ..."
}

getMaximumValue() {
  paramYesterday=$2
  paramRouterId=$1
  maximumFile="maximum"
  separator=";"

  maximum=$(awk -F";" '($2>=v){v=$2}END{print v}' $dataDir/$paramRouterId/$paramYesterday)
  output=$paramYesterday$separator$paramRouterId$separator$maximum$separator
  echo $output>>$dataDir/$maximumFile
  if [ $chownString ]; then
    chown $chownString $dataDir/$maximumFile
  fi
}

if [ ! $dataDir ]; then
  dataDir="$workingDir/freifunkdata"
elif [ $(echo ${dataDir} | cut -c1-1) == "." ]; then
  dataDir="$workingDir/$(echo ${dataDir} | tail -c +3)"
elif [ $(echo ${dataDir} | cut -c1-1) == "/" ]; then
  dataDir=$dataDir
else
  dataDir="$workingDir/freifunkdata"
fi

#set total-folder
if [ ! $totalDir ]; then
  totalDataDir="$dataDir/Total"
else
  totalDataDir="$dataDir/$totalDir"
fi

#set chown user and group
chownString=$false
if [ $chownUser ]; then
  chownString="$chownUser"
fi
if [ $chownGroup ]; then
  chownString="$chownString:$chownGroup"
fi

#if init parameter do setup
if [ $parameter ]; then
  #check existence of data-folder and create it if it doesn't
  if [ ! -d $dataDir ]; then
    mkdir $dataDir
    if [ $chownString ]; then
      chown $chownString $dataDir
    fi
  fi

  #abort script if data-folder could not be created
  if [ ! -d $dataDir ]; then
    echoError "FEHLER: Das Datenverzeichnis \"$dataDir\" konnte nicht angelegt werden.\nPrüfe die Zugriffsrechte."
  fi

  #check existence of total-folder and create it if it doesn't
  if [ ! -d $totalDataDir ]; then
    mkdir $totalDataDir
    if [ $chownString ]; then
      chown $chownString $totalDataDir
    fi

    initFunction
  else
    initParameter=false
  fi
fi

#abort script if data-folder could not be created
if [ ! -d $dataDir ]; then
  echoError "FEHLER: Das Datenverzeichnis \"$dataDir\" existiert nicht\nFühre das Skript mit dem Parameter \"init\" aus um die Datenstruktur zu erstellen."
fi

#init counters
total=0
dirCounter=0
date=$(date +"%Y-%m-%d")

#parse data-folder and crawl each router
for D in `find $dataDir -type d`; do
  if [ $D != $dataDir ]; then
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
  if [ ! -f $totalDataDir/$date ]; then
    yesterday=$(date +"%Y-%m-%d" -d "yesterday")
    if [ -f $totalDataDir/$yesterday ]; then
      for D in `find $dataDir -type d`; do
        if [ $D != $dataDir ]; then
          if [ -f $D/$yesterday ]; then
            routerId=$(basename $D)
            getMaximumValue $routerId $yesterday
          fi
        fi
      done
    fi
  fi

  output=$time$separator$total$separator
  echo $output>>$totalDataDir/$date

  if [ $chownString ]; then
    chown $chownString $totalDataDir/$date
  fi
fi

if [ "$initParameter" == "true" ]; then
  echo -e "\nFertig.\n\nDu kannst nun das Skript in deinem Cron eintragen, z.B. wie folgt um alle 30 Minuten die Anzahl der verbundenen Clients abzufragen:\n*/30 * * * * bash $workingDir/freifunkcrawler.sh"
fi
