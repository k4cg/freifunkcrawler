#!/bin/sh

targetFolder="/var/www/k4cg.org/stats/freeasinfunk"
totalFolder="Total"
medianFile="median" #filename for daily stats and name for column

calculateMedian() {
  paramYesterday=$2
  paramRouterId=$1

  separator=";"

  median=$(awk -F ";" '{ sum += $2; n++ } END { printf("%.0f\n", sum / n); }' $targetFolder/$paramRouterId/$paramYesterday)
  output=$paramYesterday$separator$paramRouterId$separator$median$separator
  total=$(($total + $median))
  echo $output>>$targetFolder/$medianFile
}

yesterday=$(date +"%Y-%m-%d" -d "yesterday")
total=0

for D in `find $targetFolder -type d`
do
  if [ $D != $targetFolder ]; then
    if [ -f $D/$yesterday ]; then
      routerId=$(basename $D)
      if [ $routerId != $totalFolder ]; then
        calculateMedian $routerId $yesterday
      fi
    fi
  fi
done

output=$yesterday$separator$medianFile$separator$total$separator
echo $output>>$targetFolder/$medianFile
chown www-data:www-data $targetFolder/$medianFile
