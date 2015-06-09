#!/bin/sh

targetFolder="/var/www/k4cg.org/stats/freeasinfunk"
totalFolder="Total"
maximumFile="maximum" #filename for per day stats

getMaximumValue() {
  paramYesterday=$2
  paramRouterId=$1

  separator=";"

  maximum=$(awk -F";" '($2>=v){v=$2}END{print v}' $targetFolder/$paramRouterId/$paramYesterday)
  output=$paramYesterday$separator$paramRouterId$separator$maximum$separator
  echo $output>>$targetFolder/$maximumFile
  chown www-data:www-data $targetFolder/$maximumFile
}

yesterday=$(date +"%Y-%m-%d" -d "yesterday")
total=0

for D in `find $targetFolder -type d`
do
  if [ $D != $targetFolder ]; then
    if [ -f $D/$yesterday ]; then
      routerId=$(basename $D)
      getMaximumValue $routerId $yesterday
    fi
  fi
done
