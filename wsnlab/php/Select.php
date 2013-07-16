<?php
$con=mysqli_connect("localhost","root","","wsn_lab");
// Check connection
if (mysqli_connect_errno())
  {
  echo "Failed to connect to MySQL: " . mysqli_connect_error();
  }

$result = mysqli_query($con,"SELECT * FROM user WHERE UserID='7'");

//Create a Table to store




/**
	mysqli_fetch_array() function to return the first row from the recordset as an array.
	Each call to mysqli_fetch_array() returns the next row in the recordset. 
	The while loop loops through all the records in the recordset. 
	To print the value of each row, we use the PHP $row variable ($row['FirstName'] and $row['LastName']).
	**/

$row = mysqli_fetch_array($result);
$jsonstr =array('UID'=>$row['UserID'] , 'UN'=>$row['UserName'] , 'UP'=>$row['UserPass']);
 echo json_encode($jsonstr);


mysqli_close($con);
?> 