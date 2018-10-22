% MIBI smooth stitching script
% Author: Dmitry Tebaykin
% Contact: dmitry.tebaykin@stanford.edu

%% Necessary parameters
% Provide the XML file path from the run, stitching parameters will be
% extracted automatically. Example: xmlFileName = '180501_Hip_Panel3ug_Final-2b.xml';
xmlFileName = ''; % Leave this blank for now

% Output folder for stitched images. Default: current working directory
OutputFolder = [pwd];

% Point to folder where the Point folders with TIFs are located. pwd stands for current
% working directory (path at the top of Matlab)
% Example for a different folder: TIFs_PATH = [pwd, '/extracted']
% This relies on your TIFs being inside TIFs_PATH/PointX/TIFs/ folder. To
% change this - modify MibiStitchLoopSupport around line 62
TIFs_PATH = [pwd]; 
dataSize = 508; % Resolution of one frame, minus 4 pixels. Example: 512x512 - 4 = 508

% Stitch start and end points.
startPoint = 2; % Start stitching from this point number
endPoint = 0; % End stitching with this point number. Zero means all points to the end
skipPoints = []; % These points will be skipped during stitching (The stitch should advance, leaving a blank space)

%% Set these if no XML is available
% Set stitching parameters manually if no XML file is available
xNumPoint = 12; % Set this to the number of rows
yNumPoint = 9; % Set this to the number of columns
direction = 0; % Choose starting stitch direction: 0 = left, 1 = right

% new stitch
% X and Y refer to pixel matrix row and column
ydRight = 28; % Shift this many pixels when moving right
xdRight = 2; % Vertical tilt of the image, shift this many pixels up each time when moving right
ydTop = 10; % Shift right by ydTop pixels when moving up one row. Horizontal tilt
xdTop = -33; % Should be negative or 0. Controls vertical coregistration when moving up one row. Positive value would yield blank space between rows

% Gather all channel names
ImageNamesP = dir([TIFs_PATH,'/Point1/TIFs/*tif']);
ImageNamesP = {ImageNamesP.name};
ImageNames{1, length(ImageNamesP)} = [];
for i = 1:length(ImageNamesP)
    ImageNames{1,i} = ImageNamesP{i};
end
allChannels = ImageNames;

% Overwrite the above to stitch specific channels only
%allChannels = ["dsDNA", "CD56"];

%% Calculating the rest of the offsets and starting the loop
ydRight = dataSize - ydRight; % Adjusting for the relative shift when going right
ydLeft = dataSize - ydRight; % do not change, similar to ydRight
xdLeft = -xdRight; % do not change, similar to xdRight

% Create a weights matrix
weights = zeros(dataSize, dataSize);
for k = 1:floor(dataSize/2)
    weights([k, dataSize - k + 1], k : dataSize - k + 1) = k;
    weights(k : dataSize - k + 1, [k, dataSize - k + 1] ) = k;
end

% Start the loop
for channelNonChar = allChannels
    channel = char(channelNonChar);
    disp(['Making stitched TIF for: ', channel]);
    MibiStitchLoopSupport;
end
disp('Finished stitching all channels');
    

