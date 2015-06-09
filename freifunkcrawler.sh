#!/bin/sh

targetFolder="/var/www/k4cg.org/stats/freeasinfunk"
totalFolder="Total"

crawlFreifunk() {
  paramRouterId=$1

  xml=https://netmon.freifunk-franken.de/api/rest/router/$paramRouterId
  clients=$(curl -s $xml | grep -oP '(?<=client_count>)[^<]+')
  #url="https://netmon.freifunk-franken.de/router.php?router_id=$paramRouterId"
  #clients=$(curl -s $url | grep -oP '(?<=Clients:</b> ).*?(?=<br>)')
  if [ -z "$clients" ]; then
    clients=0
  fi
  [[ $clients == ?(-)+([0-9]) ]] && total=$(($total + $clients))
  date=$(date +"%Y-%m-%d")
  time=$(date +"%H:%M")
  separator=";"

  output=$time$separator$clients$separator
  echo $output>>$targetFolder/$paramRouterId/$date
  chown www-data:www-data $targetFolder/$paramRouterId/$date
}

total=0

for D in `find $targetFolder -type d`
do
  if [ $D != $targetFolder ]; then
    if [ ! -f $D/disabled ]; then
      routerId=$(basename $D)
      if [ $routerId != $totalFolder ]; then
        crawlFreifunk $routerId
      fi
    fi
  fi
done

output=$time$separator$total$separator
echo $output>>$targetFolder/$totalFolder/$date
