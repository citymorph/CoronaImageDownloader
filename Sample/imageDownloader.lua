-------------------------------------------------
-- CORONA SDK - IMAGE DOWNLOADER
-- Version: 1.0.0
-- Used for downloading images depending on imageSuffix
--
-- Revised BSD License:
--
-- Copyright (c) 2014, Daniel Strmečki <email: daniel.strmecki@gmail.com, web: promptcode.com>
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--   * Redistributions of source code must retain the above copyright
--     notice, this list of conditions and the following disclaimer.
--   * Redistributions in binary form must reproduce the above copyright
--     notice, this list of conditions and the following disclaimer in the
--     documentation and/or other materials provided with the distribution.
--   * Neither the name of the <organization> nor the
--     names of its contributors may be used to endorse or promote products
--     derived from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL DANIEL STRMEČKI BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------

local lfs = require ("lfs")
local json = require ("json")
local widget = require( "widget" )

local id = {}

-------------------------------------------------
-- STATIC PROPERTIES
-------------------------------------------------

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

id.imageSuffix = 1
id.skipedErrors = 0
id.db = nil
id.phpImageDownloaderUrl = nil
id.downloadedImages = 0
id.numberOfImages = 0
id.imageRelativePaths = nil
id.lastRequestedImage = 0
id.requestImageFunction = nil
id.requestInfoFunction = nil
id.progressView = nil
id.progressText = nil
id.callbackWhenDone = nil
id.callbackOnDownloadStatusChange = nil

-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------

-- Replace string
function strReplace(s, what, with)
    return string.gsub(s, what, with)
end

-- Get first index of char in string
local function strIndexOf(s1, s2)
    return string.find(s1, s2)
end

-- Get last index of char in string
local function strLastIndexOf(haystack, needle)
    --Set the third arg to false to allow pattern matching
    local found = haystack:reverse():find(needle:reverse(), nil, true)
    if found then
        return haystack:len() - needle:len() - found + 2 
    else
        return found
    end
end

-- Substring
local function strSubstring(s, from, to)
    return string.sub(s, from, to) 
end

-- Length
local function strLength(s)
    return string.len(s)
end

-- Save downloaded images number
local function setDownloadedImages(downloadedImages)
	local q2 = [[UPDATE ]] .. id.tableName  .. [[ SET value = ']] .. downloadedImages ..[[' WHERE name = 'downloadedImages';]]
	id.db:exec(q2)
end

-- Get downloaded images number
local function getDownloadedImages()
	local value = 0
	for row in db:nrows("SELECT * FROM " .. id.tableName .. " WHERE name = 'downloadedImages'") do
		value = row.value
	end
	return tonumber(value)
end

-- Save images count
local function setNumberOfImages(numberOfImages)
	local q2 = [[UPDATE ]] .. id.tableName  .. [[ SET value = ']] .. numberOfImages ..[[' WHERE name = 'numberOfImages';]]
	id.db:exec(q2)
end

-- Get images count
local function getNumberOfImages()
	local value = 0
	for row in db:nrows("SELECT * FROM " .. id.tableName .. " WHERE name = 'numberOfImages'") do
		value = row.value
	end
	return tonumber(value)
end

-- Create images subfolder in imageDirectory
local function createImagesSubfolder()
	-- Get raw path to app's Documents directory
	local docs_path = system.pathForFile("", id.imageDirectory)

	-- change current working directory
	local success = lfs.chdir( docs_path ) -- returns true on success
	local new_folder_path
	local dname = id.imageSubfolderName
	if success then
	    lfs.mkdir( dname )
	end
end

-- Delete all images in imageDirectory images subfolder
local function deleteAllDownloadedImages()
	local doc_dir = id.imageDirectory;
	local doc_path = system.pathForFile(id.imageSubfolderName, doc_dir);
	local resultOK, errorMsg;
	 
	for file in lfs.dir(doc_path) do
	    local theFile = system.pathForFile(id.imageSubfolderName .. "/" .. file, doc_dir);
	 
	    if (lfs.attributes(theFile, "mode") ~= "directory") then
	        resultOK, errorMsg = os.remove(theFile);
	 
	        if (resultOK == false) then
	            print("IMAGE DOWNLOADER - internal error - cannot remove file: " .. file .. ": " .. errorMsg);
	        end
	    end
	end 
end

-- Check how many images have been downloaded
local function checkNeedForDownload()
	if (id.downloadedImages == 0) then
		-- Check if referece to DB object is set
		if (id.db == nil) then
			print("IMAGE DOWNLOADER- internal error - no referece to database set")
			return;
		end

		-- Create table if it does not exist
		local q1 = [[CREATE TABLE IF NOT EXISTS ]] .. id.tableName .. [[ (id INTEGER PRIMARY KEY autoincrement, name, value);]]
		id.db:exec(q1)

		-- Insert default value if no values are present, else get value from database
		id.downloadedImages = getDownloadedImages()
		id.numberOfImages = getNumberOfImages()
		if (0 == id.downloadedImages) then
			local q2 = [[INSERT INTO ]] .. id.tableName  .. [[ VALUES (NULL, 'downloadedImages', '0');]]
			id.db:exec(q2)

			local q3 = [[INSERT INTO ]] .. id.tableName  .. [[ VALUES (NULL, 'numberOfImages', '0');]]
			id.db:exec(q3)

			createImagesSubfolder()
		end
	end
end

-- Alert complete listener on error while getting image count
local function onImageDownloadAlertComplete( event )
	if "clicked" == event.action then
        local i = event.index
        if 1 == i then
        	id.requestImageFunction(id.lastRequestedImage)
        else
        	native.requestExit()
        end
    end
end

-- Listener for downloading images
local function imagesDownloadListener( event )
    if ( event.isError ) then
    	if (id.skipedErrors < 3) then
    		-- Try again three time and only then prompt the user
    		id.requestImageFunction(id.lastRequestedImage)
    		id.skipedErrors = id.skipedErrors + 1
    	else
	        if system.getInfo("platformName") == "Android" then
	        	native.showAlert( id.errorDownloadingTitle, id.errorDownloadingMessage, { id.tryAgainButtonLabel, id.exitButtonLabel }, onImageDownloadAlertComplete )
	        else
	        	native.showAlert( id.errorDownloadingTitle, id.errorDownloadingMessage, { id.tryAgainButtonLabel }, onImageDownloadAlertComplete )
	        end
	    end
    elseif ( event.phase == "ended" ) then
        --print( "Displaying response image file", event.response.filename )

        id.downloadedImages = id.downloadedImages + 1
        id.skipedErrors = 0
        setDownloadedImages(id.downloadedImages)

        --print("Downloaded image " .. id.downloadedImages .. " of " .. id.numberOfImages)
        local percents = (id.downloadedImages + 1) / (id.numberOfImages + 1)
        if (id.useProgressView == true) then
	        id.progressView:setProgress( percents )
	    end
	    if (id.useProgressText == true) then
        	id.progressText.text = id.downloadingMessage .. ": " .. math.round (percents * 100) .. "%"
   		end
   		if (id.callbackOnDownloadStatusChange ~= nil) then
   			id.callbackOnDownloadStatusChange(id.lastRequestedImage, id.numberOfImages)
   		end
        
        if (id.downloadedImages < id.numberOfImages) then
        	id.requestImageFunction(id.lastRequestedImage + 1)
        else
        	if (id.removeDisplayObjectsWhenDone == true) then
    			if (id.progressView ~= nil) then
    				id.progressView:removeSelf()
    				id.progressView = nil
    			end
    			if (id.progressText ~= nil) then
    				id.progressText:removeSelf()
    				id.progressText = nil
    			end
    		else
    			if (id.useProgressText == true) then
    				id.progressText.text = id.completedDownloadMessage
    			end
    		end
    		system.setIdleTimer( true ) 
    		if (id.callbackWhenDone ~= nil) then
        		id.callbackWhenDone()
        	end
        end
    end
end

-- Request images download
id.requestImageFunction = function(i)
	id.lastRequestedImage = i
	local imgName = id.imageRelativePaths[i]
	imgName = strSubstring(imgName, strLastIndexOf(imgName, "/") + 1, strLength(imgName))
	local params = "?imageSuffix=" .. id.imageSuffix .. "&index=" .. i
	network.download(
	    id.phpImageDownloaderUrl .. params,
	    "GET",
	    imagesDownloadListener,
	    "images/" .. imgName,
	    id.imageDirectory
	)
end

-- Setup progress view and start downloading images
local function doDownloadImages()
	if (id.phpImageDownloaderUrl == nil) then
		print("IMAGE DOWNLOADER - internal error - no reference / url to PHP script set!")
	end

	if (id.useProgressView == true) then
		id.progressView:setProgress( 1 / (id.numberOfImages + 1))
	end

	if (id.useProgressText == true) then
		if (id.progressText ~= nil) then
			local percents = (id.downloadedImages + 1) / (id.numberOfImages + 1)
			id.progressText.text = id.downloadingMessage .. ": " .. math.round (percents * 100) .. "%"
		end
	end

	if (id.useProgressView == true) then
		if (id.progressView ~= nil) then
			local percents = (id.downloadedImages + 1) / (id.numberOfImages + 1)
			id.progressView:setProgress(percents)
		end
	end

	system.setIdleTimer( false ) 

	id.requestImageFunction(id.downloadedImages + 1)
end

-- Alert complete listener on error while getting image count
local function onImageCountAlertComplete( event )
	if "clicked" == event.action then
        local i = event.index
        if 1 == i then
        	id.requestInfoFunction()
        else
        	native.requestExit()
        end
    end
end

-- Listener for getting image count
local function imagesCountListener( event )
    if ( event.isError ) then
        if system.getInfo("platformName") == "Android" then
        	native.showAlert( id.errorConnectingTitle, id.errorConnectingMessage, { id.tryAgainButtonLabel, id.exitButtonLabel }, onImageCountAlertComplete )
        else
        	native.showAlert( id.errorConnectingTitle, id.errorConnectingMessage, { id.tryAgainButtonLabel }, onImageCountAlertComplete )
        end
    else
    	local images = json.decode(event.response)
    	id.numberOfImages = #images
    	id.imageRelativePaths = images;
        setNumberOfImages(id.numberOfImages)
        doDownloadImages()
    end
end

-- Request images info (count)
id.requestInfoFunction = function()

	-- Create the pregress view
	if (id.useProgressView == true) then
		if (id.progressView == nil) then
			id.progressView  = widget.newProgressView
			{
			    left = 30,
			    top = display.contentHeight / 2,
			    width = display.contentWidth - 60,
			    isAnimated = true
			}
		end
		id.progressView:setProgress( 0.0 )
	end

	-- Create the pregress info text
	if (id.useProgressText == true) then
		if (id.progressText == nil) then
			id.progressText = display.newText( id.startingDownloadMessage, display.contentWidth / 2, display.contentHeight / 2 - 20, native.systemFont, 14 )
			id.progressText:setFillColor( 0/255, 118/255, 255/255 )
		end
	end	

	local params = "?imageSuffix=" .. id.imageSuffix .. "&getInfo=true"
	network.request( 
		id.phpImageDownloaderUrl .. params, 
		"GET", 
		imagesCountListener
	)
end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

-- Setter for imageDownloader properties
-- db and phpImageDownloaderUrl are the only required parameters
function id:set(db, phpImageDownloaderUrl, callbackWhenDone, callbackOnDownloadStatusChange, progressView, progressText)
	id.db = db or nil
	id.phpImageDownloaderUrl = phpImageDownloaderUrl or nil
	id.progressView = progressView or nil
	id.progressText = progressText or nil
	id.callbackWhenDone = callbackWhenDone or nil
	id.callbackOnDownloadStatusChange = callbackOnDownloadStatusChange or nil
	local imageSuffix = display.imageSuffix
	if (imageSuffix == nil) then
        id.imageSuffix = 1
    else
    	imageSuffix = strReplace(imageSuffix, "@", "")
    	imageSuffix = strReplace(imageSuffix, "x", "")
    	id.imageSuffix = tonumber(imageSuffix)
    end
end

-- Check if images need to be downloaded and start download
function id:downloadImages()
	checkNeedForDownload()
	print("id.downloadedImages: ", id.downloadedImages)
	print("id.numberOfImages: ", id.numberOfImages)
	if (id.downloadedImages ~= id.numberOfImages or id.downloadedImages == 0) then
		id.requestInfoFunction()
	else
		system.setIdleTimer( true ) 
		if (id.callbackWhenDone ~= nil) then
			id.callbackWhenDone()
		end
	end
end

-- Delete all images so the process can start from beggining
function id:reset()
	deleteAllDownloadedImages()
	local q1 = [[DELETE FROM ]] .. id.tableName  .. [[ WHERE 1 = 1;]]
	id.db:exec(q1)
	local q2 = [[INSERT INTO ]] .. id.tableName  .. [[ VALUES (NULL, 'downloadedImages', '0');]]
	id.db:exec(q2)
	local q3 = [[INSERT INTO ]] .. id.tableName  .. [[ VALUES (NULL, 'numberOfImages', '0');]]
	id.db:exec(q3)
end

return id