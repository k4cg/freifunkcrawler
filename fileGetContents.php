<?php

if(count($argv)==2) {
  $url = filter_var($argv[1], FILTER_VALIDATE_URL);
  if($url) {
    $content = @file_get_contents($url);
    echo $content;
  } else {
    echo "0";
  }
} else {
  echo "0";
}

?>
