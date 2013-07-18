<?php

$con=mysqli_connect("localhost","root","","wsn_lab");
// Check connection
if (mysqli_connect_errno())
  {
  echo "Failed to connect to MySQL: " . mysqli_connect_error();
  }

$result = mysqli_query($con,"SELECT FileAddress FROM file WHERE ActivityID='1'");

echo ($result);

$File=("main.ihex");
for($i=0;$i<3;$i++){

        echo exec("tos-bsl -c /dev/ttyUSB".$i." --telosb  -r -e -I -p".$File);
}

?>
