<?php
$con=mysqli_connect("localhost","root","","wsn_lab");
// Check connection
if (mysqli_connect_errno())
  {
  echo "Failed to connect to MySQL: " . mysqli_connect_error();
  }

mysqli_query($con,"UPDATE job SET ID=36
WHERE Name='Peyman'");

mysqli_close($con);
?> 