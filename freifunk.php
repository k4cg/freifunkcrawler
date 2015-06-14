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

$dataDirFirstChar = substr($dataDir, 0, 1);
if($dataDirFirstChar == '/') {
  define('DATADIR', $dataDir . DS);
} elseif ($dataDirFirstChar == '.') {
  if(substr($dataDir, 1, 1) == '/') {
    $dataDir = substr($dataDir, 2);
  } else {
    $dataDir = substr($dataDir, 1);
  }
  define('DATADIR', dirname(__FILE__) . DS . $dataDir . DS);
}


if(!isset($netmonUrl)) {
  die('settings "netmonUrl" missing in config file!');
}

if(!isset($title)) {
  $title = 'freifunkstats';
}

if(!isset($totalDir)) {
  $totalDir = 'Total';
}

define('TOTALDIR', DATADIR . $totalDir . DS);

if(isset($inlineJavaScript) && $inlineJavaScript) {
  $javaScript = '<script type="application/javascript">' . file_get_contents(dirname(__FILE__) . DS . 'js' . DS . 'Chart.min.js') . '</script>';
} else {
  $javaScript = '<script src="./js/Chart.min.js"></script>';
}

$date = checkDateParameterOrRedirect();
$statsDayArray = returnStatsDayArray($date);

$maximumPerDayChartData = FALSE;
$dayChartData = FALSE;

if($statsDayArray) {
  $navigation = returnNavigation($date);
  $coloursArray = returnColoursArray(count($statsDayArray));
  $dayChartData = returnChartData($statsDayArray, $totalDir, $coloursArray, 'dayChart');
  $statsMaximumPerDayArray = returnStatsMaximumArray($totalDir);
  if($statsMaximumPerDayArray) {
  	$maximumPerDayChartData = returnChartData($statsMaximumPerDayArray, 'maximum', $coloursArray, 'maximumPerDayChart');
  }
}

$maximumPerDayCanvas = '';
if($maximumPerDayChartData) {
  $maximumPerDayCanvas = <<< CANVAS
    <div>
	  <h1>verbundene Clients - Maximum Tagesansicht</h1>
	  <canvas id="maximumPerDayChart" height="100" width="900"></canvas>
    </div>
CANVAS;
}

$dayCanvas = ''; 
if($dayChartData) {
  $dayCanvas = <<< CANVAS
    <div>
      <h1>verbundene Clients - Tagesansicht - $date</h1>
      <canvas id="dayChart" height="250" width="900"></canvas>
    </div>
CANVAS;
}

if(strlen($maximumPerDayCanvas)+strlen($dayCanvas) == 0) {
  if(!file_exists($dataDir . '/' . $totalDir)) {
    $errorMessage = <<< ERROR
    <div>
      <h1 style="color:red;">FEHLER - Datenstruktur nicht vorhanden</h1>
      <p>Es wurden keine Daten gefunden .. Bitte f&uuml;hre das Skript mit dem Parameter "init" aus um die Datenstruktur einzurichten.</p>
      <span style="border: 1px solid #666; background-color: #aaa; padding: 5px;">bash freifunkcrawler.sh init</span>
    </div>
ERROR;
  } else {
    $errorMessage = <<< ERROR
    <div>
      <h1 style="color:red;">FEHLER - zu wenig Daten</h1>
      <p>Es sind zu wenige Daten vorhanden .. Bitte f&uuml;hre das Skript mindestens zwei Mal aus um gen&uuml;gend Daten f&uuml;r die Anzeige zu sammeln.</p>
    </div>
ERROR;
  }
  $dayCanvas = $errorMessage;
}

function returnChartData($dataArray, $timeStringKey, $coloursArray, $chartName) {
  $chartData = FALSE;
  $dataArrayKeys = array_keys($dataArray);
  if(count(explode(',', $dataArray[$timeStringKey]['timeString']))>1) {
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
  }
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
  $dir = TOTALDIR;
  
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
  	if(file_exists(TOTALDIR . dateDashFormat($yesterday))) {
  	  $dateParam = $yesterday;
  	} else {
  	  $dateParam = date('Ymd');
  	}
    header('Location: //' . $_SERVER["HTTP_HOST"] . $_SERVER["SCRIPT_NAME"] . '?date=' . $dateParam);
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
  	//TODO SET YESTERDAY IF GIVEN DATE DOESNT EXIST
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
  if(count($returnArray)>0) {
    return reorderStatsDayArray($returnArray);
  } else {
  	return FALSE;
  }
  
}

function reorderStatsDayArray($array) {
  //this tweak reorders the folders in the array so that the total-folder is the very first one (looks better onmouseover)
  $tmpArray = $array;
  $totalArray = array_splice($tmpArray, count($tmpArray)-1, 1);
  $array = $totalArray + $array;
  return $array;
}

function returnStatsMaximumArray($totalDir) {
  $returnArray = Array();
  $perDayFile= 'maximum';
  $column = $totalDir;

  $tmpVal = readCsvFile(DATADIR . $perDayFile, $column);
  if(!empty($tmpVal)) {
    $returnArray[$perDayFile] = $tmpVal;
  }
  
  if(count($returnArray) > 0) {
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
$javaScript
</head>
<body>
<div style="width: 95%; margin: auto;">
  <div>
$navigation
$maximumPerDayCanvas
$dayCanvas
  </div>
</div>
<script>
$maximumPerDayChartData
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
  var qwe = document.getElementById("maximumPerDayChart").getContext("2d");
  window.perDayChart = new Chart(qwe).Line(maximumPerDayChartData, {
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
