<?php

$con=mysqli_connect("localhost","root","","wsn_lab");
// Check connection
if (mysqli_connect_errno())
  {
  echo "Failed to connect to MySQL: " . mysqli_connect_error();
  }

  
// find the FileAddress field in DB for Actiity one which is Beacon  
$result = mysqli_query($con,"SELECT FileAddress FROM file WHERE ActivityID='1'");
if (!$result) {
    die('Query failed: ' . mysql_error());
}
//mysqli_result::fetch_assoc -- mysqli_fetch_assoc — Fetch a result row as an associative array
$row = mysqli_fetch_assoc($result);
$File = $row['FileAddress'];  



for($i=0;$i<3;$i++){

        echo exec("tos-bsl -c /dev/ttyUSB".$i." --telosb  -r -e -I -p".$File);
		
		}

?>
