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
  
  
  /**
  Before Insert to Job table we need to clean all the row of 
  table which done before. 
  for this we can use following Command:
  "TRUNCATE TABLE name"
  
  **/
  # To insert new job into DB
  if ($_POST['DBTable'] == "job") {
    # code...
    $ActivityID = json_decode($_POST['ActivityID']);
    $GroupID = json_decode($_POST['GroupID']);
    $JobDate = json_decode($_POST['JobDate']);
    $JobID = json_decode($_POST['JobID']);
    $MoteID = json_decode($_POST['MoteID']);
    $UserID = json_decode($_POST['UserID']);
    $sql="INSERT INTO job (ActivityID,GroupID,JobDate,JobID,MoteID,UserID)
    VALUES ('$ActivityID','$GroupID','$JobDate','$JobID','$MoteID','$UserID')";
  }

# To insert new User into DB
 if ($_POST['DBTable'] == "user") {
    # code...
    $UserID = json_decode($_POST['UserID']);
    $UserName = json_decode($_POST['UserName']);
    $UserPass = json_decode($_POST['UserPass']);

    $sql="INSERT INTO user (UserID,UserName,UserPass)
    VALUES ('$UserID','$UserName','$UserPass')";
  }


 if (!mysqli_query($con,$sql))
  {
  die('Error: ' . mysqli_error($con));
  }
echo "Record added successfully!";
 //close connection
 mysqli_close($con);
 
?> 