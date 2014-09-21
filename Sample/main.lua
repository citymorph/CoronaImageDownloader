-------------------------------------------------
-- CORONA SDK - IMAGE DOWNLOADER - SAMPLE - MAIN
--
-- @Daniel 13.09.2014
-------------------------------------------------

-------------------------------------------------
-- REQUIRE MODULES
-------------------------------------------------
local sqlite3 = require ("sqlite3")
local id = require("imageDownloader")

--Main function, called on applications first start
local function main()
	
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
	id:set(db, "http://citybusvz.comze.com/corona-test/imageDownloader.php", onAllResourcesDownloadComplete, onSingleResourceDownloadComplete)
	
	-- Use reset to delete all resources and start downloading again
	-- If you remove this line, resources will be downloaded only once, untill they all download sucessfully
	id:reset()

	-- Start downloading images
	id:downloadImages()

end

main();

