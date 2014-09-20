<?php
// Get params from request
$imageSuffix = $_GET["imageSuffix"];
$getInfo = $_GET["getInfo"];

// Get images and sort them
$path  = "images/" . $imageSuffix . "x/*.png";
$images = glob($path); 
sort($images);

if (isset ($getInfo)) {
	// Send images information 
	echo json_encode($images);
}
else {
	$index = $_GET["index"] - 1; 
	// Image selection
	if (count($images) >= $index) { // make sure that the image exists
		$img = $images[$index];
		// Send image as response
		$img_data = file_get_contents($img);
		header("Content-type: image/png"); 
		echo $img_data;  
	} else {
		echo 'Error, image not found!';
	}
} 
?>