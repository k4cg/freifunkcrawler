<?php
date_default_timezone_set('Europe/Berlin');
define('DS', DIRECTORY_SEPARATOR);

//parse ini file with settings and create settings variables
$settingsArray = parse_ini_file("freifunkconfig.ini.php");

if($settingsArray) {
  foreach($settingsArray as $key => $value) {
    if(!empty($value)) {
      $$key = $value;
    }
  }
} else {
  die("config file missing");
}

if(!isset($dataDir)) {
  $dataDir = 'freifunkdata';
}

define('DATADIR', dirname(__FILE__) . DS . $dataDir . DS);

if(!isset($netmonUrl)) {
  die('settings "netmonUrl" missing!');
}

if(!isset($title)) {
  $title = 'freifunkstats';
}

$date = checkDateParameterOrRedirect();

$statsMaximumMedianArray = returnStatsMaximumMedianArray();

if(count($statsMaximumMedianArray) > 0) {
  $statsDayArray = returnStatsDayArray($date);
  $navigation = returnNavigation($date);
  $coloursArray = returnColoursArray(count($statsDayArray));
  $maximumMedianChartData = returnChartData($statsMaximumMedianArray, 'maximum', $coloursArray, 'maximumMedianChart');
  $dayChartData = returnChartData($statsDayArray, 'Total', $coloursArray, 'dayChart');
}

function returnChartData($dataArray, $timeStringKey, $coloursArray, $chartName) {
  $dataArrayKeys = array_keys($dataArray);
  $labels = $dataArray[$timeStringKey]['timeString'];
  $chartName .= 'Data';
  $chartData = <<< CHARTHEAD
var $chartName = {
labels : [$labels],
datasets : [
CHARTHEAD;

  $counter = 0;
  foreach($dataArray as $array) {
    $label = $dataArrayKeys[$counter];
    $hostnameFile = DATADIR . $label . DS . 'hostname';
    if(file_exists($hostnameFile)) {
      $label = trim(file_get_contents($hostnameFile));
    }
    $colour = $coloursArray[$counter];
    $data = $dataArray[$dataArrayKeys[$counter]]['valueString'];
    $chartData .= <<<CHARTDATA
{
  label: "$label",
  fillColor : "rgba($colour,0.2)",
  strokeColor : "rgba($colour,1)",
  pointColor : "rgba($colour,1)",
  pointStrokeColor : "#fff",
  pointHighlightFill : "#fff",
  pointHighlightStroke : "rgba($colour,1)",
  data : [$data]
}
CHARTDATA;

    if(count($dataArray)-1 != $counter) {
      $chartData .= ",\n";
    }
    $counter++;
  }
  $chartData .= "\n]\n}\n";
  return $chartData;
}

function returnColoursArray($count) {
  $returnArray = Array('151,187,205', '193,97,31', '141,138,119', '125,20,118', '90,211,209', '255,200,112', '97,103,116', '255,90,94');
  $tmpColoursArray = $returnArray;
  
  //a workaround if there are more lines than colours so we don't run out of colors (and thus cause errors)
  while($count > count($returnArray)){
    $returnArray = array_merge($returnArray, $tmpColoursArray);
  }
  return $returnArray;
}

function returnNavigation($date) {
  $scriptName = $_SERVER["SCRIPT_NAME"];
  $previousDay = date("Ymd", strtotime("$date -1 days"));
  $nextDay = date("Ymd", strtotime("$date +1 days"));
  $dir = DATADIR . 'Total' . DS;
  
  if(file_exists($dir . dateDashFormat($previousDay))) {
    $previousDayDashFormat = dateDashFormat($previousDay);
    $previousDayString = "previous day: <a href=\"$scriptName?date=$previousDay\">$previousDayDashFormat</a>";
  }
  
  if(file_exists($dir . dateDashFormat($nextDay))) {
    $nextDayDashFormat = dateDashFormat($nextDay);
    $nextDayString = "next day: <a href=\"$scriptName?date=$nextDay\">$nextDayDashFormat</a>";
  }
  
  $returnValue = <<<NAV
    <div id="nav">
      $previousDayString<br/>
      $nextDayString<br/>
    </div>
NAV;
  
  return $returnValue;
}

function checkDateParameterOrRedirect() {
  $yesterday = date('Ymd', strtotime("-1 days"));
  
  if(isset($_GET['date'])) {
    $paramDate = intval($_GET['date']);
  
    if(strlen($paramDate)==8) {
      return dateDashFormat($paramDate);
    } else {
      header('Location: //' . $_SERVER["HTTP_HOST"] . $_SERVER["SCRIPT_NAME"] . '?date=' . $yesterday);
      die();
    }
  } else {
    header('Location: //' . $_SERVER["HTTP_HOST"] . $_SERVER["SCRIPT_NAME"] . '?date=' . $yesterday);
    die();
  }
}

function dateDashFormat($date) {
  return substr($date, 0, 4) . '-' .  substr($date, 4, 2) . '-' .  substr($date, 6, 2);
}

function readCsvFile($filename, $column = FALSE) {
  $returnArray = Array();
  $timeString = '';
  $valueString = '';
  if(($handle = fopen($filename, 'r')) !== FALSE) {
    while(!feof($handle)) {
      $tmpData = fgets($handle);
      $tmpData = explode(';', trim($tmpData));
      //day files
      if(count($tmpData) == 3) {
        $timeString .= '"' . $tmpData[0] . '",';
        $valueString .= '"' . $tmpData[1] . '",';
      }
      //per day files
      if(count($tmpData) == 4) {
        if($tmpData[1] == $column) {
          $timeString .= '"' . $tmpData[0] . '",';
          $valueString .= '"' . $tmpData[2] . '",';
        }
      }
    }
    fclose($handle);
    unset($handle);
    if(strlen($timeString) > 0 ) {
      $timeString = substr($timeString, 0, -1);
    }
    if(strlen($valueString) > 0 ) {
      $valueString = substr($valueString, 0, -1);
    }
    $returnArray['timeString'] = $timeString;
    $returnArray['valueString'] = $valueString;
  }
  return $returnArray;
}

function returnStatsDayArray($date) {
  $returnArray = Array();
  $directories = scandir(DATADIR);
  
  foreach($directories as $dir) {
    if($dir != '.' && $dir != '..') {
      $currentFolder = $dir;
      $dir = DATADIR . $dir . DS;
      if(is_dir($dir)) {
        if(file_exists($dir . $date)) {
          $filename = $dir . $date;
          $returnArray[$currentFolder] = readCsvFile($filename);
        } else {
          #die("requested stats-file don't exist");
        }
      }
    }
  }
  
  $returnArray = reorderStatsDayArray($returnArray);
  
  return $returnArray;
}

function reorderStatsDayArray($array) {
  //this tweak reorders the folders in the array so that "Total" is the very first one (looks better onmouseover)
  $tmpArray = $array;
  $totalArray = array_splice($tmpArray, count($tmpArray)-1, 1);
  $array = $totalArray + $array;
  return $array;
}

function returnStatsMaximumMedianArray() {
  $returnArray = Array();
  $perDayFilesArray = Array('maximum', 'median');
  foreach($perDayFilesArray as $perDayFile) {
    $column = $perDayFile;
    if($perDayFile == 'maximum') {
      $column = 'Total';
    }
    $returnArray[$perDayFile] = readCsvFile(DATADIR . $perDayFile, $column);
  }
  if(count($returnArray) > 1) {
    return $returnArray;
  } else {
    return FALSE;
  }
}

$html = <<<HTML
<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>$title</title>
<script src="./js/Chart.min.js"></script>
</head>
<body>
<div style="width: 95%; margin: auto;">
  <div>
$navigation
    <div>
      <h1>connected clients - maximum/median per day view</h1>
      <canvas id="maximumMedianChart" height="100" width="900"></canvas>
    </div>
    <div>
      <h1>connected clients - day view - $date</h1>
      <canvas id="dayChart" height="250" width="900"></canvas>
    </div>
  </div>
</div>
<script>
$maximumMedianChartData
$dayChartData
window.onload = function(){
  var ctx = document.getElementById("dayChart").getContext("2d");
  window.dayChart = new Chart(ctx).Line(dayChartData, {
    scaleBeginAtZero: true,
    responsive: true,
    animation: false,
    pointHitDetectionRadius: 4,
    multiTooltipTemplate: "<%= datasetLabel %>: <%= value %>"
  });
  var qwe = document.getElementById("maximumMedianChart").getContext("2d");
  window.perDayChart = new Chart(qwe).Line(maximumMedianChartData, {
    scaleBeginAtZero: true,
    responsive: true,
    animation: false,
    pointHitDetectionRadius: 4,
    multiTooltipTemplate: "<%= datasetLabel %>: <%= value %>"
  });
}
</script>
</body>
</html>
HTML;

echo $html;

?>
