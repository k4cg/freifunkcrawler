<?php

if(count($argv)==2) {
  $url = $argv[1];
  $content = @file_get_contents($url);
  echo $content;
} else {
  echo "0";
}

?>
