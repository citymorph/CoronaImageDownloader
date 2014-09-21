Corona Image Downloader
=====================

##Usage##

Used for downloading image resources on device based on display.imageSuffix
* Significantly reduces APK / IPA size
* Significantly reduces application's size on device
* Each device downloads images only for its own resolutions


##Server side##

###Images###

Create a images folder on your web server and place your image resources there. Devide images into separate subfolders by image suffix, as shown in the image bellow.

![alt tag](https://raw.githubusercontent.com/promptcode/CoronaImageDownloader/master/Images/ftp.png)

###imageDownloader.php###

Place the PHP script into the same parent folder where you have created the images folder on your web server.

```php
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
```

##Client side##

###config.lua###

Setup image suffixes in your configuration. Image suffix names must correspond to image subfolders on the web server.

```lua
application = {
	content =
    {
        --graphicsCompatibility = 1, 
        width = 320,
        height = 480,
        scale = "zoomStretch",

        imageSuffix = {
           ["@2x"] = 2.0,
           ["@3x"] = 3.0,
           ["@4x"] = 4.0,
         }

    }
}
```

###main.lua###

Check out the sample Corona project in this repository. Quick preview:

```lua
-------------------------------------------------
-- SETUP DATABASE CONNECTION
-- Required to use Image downloader
-------------------------------------------------
local path = system.pathForFile("sample.db", system.DocumentsDirectory)
db = sqlite3.open(path)  

-- Your custom callback function
-- Gets called when all resources all sucessuflly downloaded
local function onAllResourcesDownloadComplete()
	print("onAllResourcesDownloadComplete")
end

-- Your custom callback function
-- Gets called when single resource is sucessuflly downloaded
local function onSingleResourceDownloadComplete(downloaded, total)
	print("onSingleResourceDownloadComplete", downloaded .. "/" .. total)
end

-------------------------------------------------
-- SETUP IMAGE DOWNLOADER MODULE
-- Requires a db connection and a path to your imageDownloader.php
-------------------------------------------------
local id = require("imageDownloader")
id:set(db, "http://citybusvz.comze.com/corona-test/imageDownloader.php", onAllResourcesDownloadComplete, onSingleResourceDownloadComplete)

-- Use reset to delete all resources and start downloading again
-- If you remove this line, resources will be downloaded only once, untill they all download sucessfully
id:reset()

-- Start downloading images
id:downloadImages()
```

###scene.lua###

Once all images have been downloaded, display them from images subfolder in system.DocumentsDirectory.

```lua
-- Button
local facebookButton = widget.newButton{
			baseDir = system.DocumentsDirectory,
			defaultFile = "images/facebook.png",
			overFile = "images/facebook_active.png",
			width = 82, 
			height = 29,
		}
localGroup:insert(facebookButton)

--Image
local bgAll = display.newImageRect( "images/start_meni_background.png", system.DocumentsDirectory, 320, 479 )
bgAll.x = _W / 2
bgAll.y = _H / 2
localGroup:insert(bgAll);
```

##Properties##

You can easily change any of id (image downloader) table / object properties. List of currenly used properties:

```lua
-- Directory where to save downloaded images
id.imageDirectory = system.DocumentsDirectory
-- Subfolder where to save downloaded
id.imageSubfolderName = "images"
-- Database table name to be used by this module
id.tableName = "image_downloader_params"
-- Title of an alert shown when resources info cannot be retrieved
id.errorConnectingTitle = "Error connecting to server"
-- Message of an alert shown when resources info cannot be retrieved
id.errorConnectingMessage = "Cannot connect to resources server. " ..
							"Please check your internet connection and try again later."
-- Title of an alert shown when image download fails
id.errorDownloadingTitle = "Error downloading resources"
-- Message of an alert shown when image download fails
id.errorDownloadingMessage = "Failed to download resources from server. " .. 
							 "Please check your internet connection and try again later."
-- Button label to quit application when alert popup shows (only on Android)
id.exitButtonLabel = "Exit"
-- Button label to try again when alert popup shows (only on Android)
id.tryAgainButtonLabel = "Try again"
-- Message to be displayed in the progress text field while downloading resources
id.downloadingMessage = "Downloading resources"
-- Message to be displayed in the progress text field while requiring resources info
id.startingDownloadMessage = "Requiring resources info"
-- Message to be displayed in the progress text field when all resources are downloaded
id.completedDownloadMessage = "Resources download complete"
-- If true, a progress view will be shown on screen
id.useProgressView = true
-- If true, a progress text will be show on screen
id.useProgressText = true
-- If true, a progress view and progress text will be removed when all resources are downloaded
id.removeDisplayObjectsWhenDone = false

```

##Customization##

You can use your own custom progress and text view's.

```lua
-------------------------------------------------
-- SETUP IMAGE DOWNLOADER MODULE
-- Requires a db connection and a path to your imageDownloader.php
-------------------------------------------------
local id = require("imageDownloader")
id:set(db, "http://citybusvz.comze.com/corona-test/imageDownloader.php")

-- Custom progress view
id.progressView  = widget.newProgressView {
    left = 30,
    top = display.contentHeight / 2,
    width = display.contentWidth - 60,
    isAnimated = true
}

-- Custom progress text
id.progressText = display.newText( id.startingDownloadMessage, display.contentWidth / 2, display.contentHeight / 2 - 20, native.systemFont, 14 )
id.progressText:setFillColor( 0/255, 118/255, 255/255 )

-- Start downloading images
id:downloadImages()
```

##Display downloaded images##

Once downloaded, you can display your images from images subfolder in system.DocumentsDirectory.

```lua
-- Image
local bgAll = display.newImageRect( "images/start_meni_background.png", system.DocumentsDirectory, 320, 479 )
bgAll.x = _W / 2
bgAll.y = _H / 2
localGroup:insert(bgAll);

-- Button
local facebookButton = widget.newButton{
			baseDir = system.DocumentsDirectory,
			defaultFile = "images/facebook.png",
			overFile = "images/facebook_active.png",
			width = 82, 
			height = 29
		}
localGroup:insert(facebookButton)
```

And thats it. Feel free to contact me with your suggestions.