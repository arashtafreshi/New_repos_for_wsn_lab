<?php
// Create connection
$con=mysqli_connect("localhost","root","","wsn_lab");

// Check connection
if (mysqli_connect_errno($con))
  {
  echo "Failed to connect to MySQL: " . mysqli_connect_error();
  }
else
	{
	echo "Connectedddd!";
  }
  
// A list of permitted file extensions
	$allowed = array('png', 'jpg', 'gif','zip');

	if(isset($_FILES['upl']) && $_FILES['upl']['error'] == 0){

	$extension = pathinfo($_FILES['upl']['name'], PATHINFO_EXTENSION);

	if(!in_array(strtolower($extension), $allowed)){
		echo '{"status":"error"}';
		
	}

	if(move_uploaded_file($_FILES['upl']['tmp_name'], 'uploads/'.$_FILES['upl']['name'])){
		echo '{"status":"success"}';
	}
  
  $sql="INSERT INTO file (ActivityID,FileAddress) VALUES ('5','" . mysql_real_escape_string('/uploads/'.$_FILES['upl']['name']) . "')";
 }
 if (!mysqli_query($con,$sql))
  {
  die('Error: ' . mysqli_error($con));
  }
echo "1 Peyman record added";
 //close connection
 mysqli_close($con);
 
?> 