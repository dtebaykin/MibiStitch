% MIBI smooth stitching script
% Author: Dmitry Tebaykin
% Contact: dmitry.tebaykin@stanford.edu

%% Necessary parameters
% Provide the XML file path from the run, stitching parameters will be
% extracted automatically. Example: xmlFileName = '180501_Hip_Panel3ug_Final-2b.xml';
xmlFileName = '';

% Output folder for stitched images. Default: current working directory
OutputFolder = [pwd];

% Point to folder where the Point folders with TIFs are located. pwd stands for current
% working directory (path at the top of Matlab)
% Example for a different folder: TIFs_PATH = [pwd, '/extracted']
% Assumption: tif files are located in PointX/TIFs/ folder, change that
% around lines 120-130 if this is wrong.
TIFs_PATH = [pwd]; 
channel = 'dsDNA';
dataSize = 508; % Resolution of one frame, minus 4 pixels. Example: 512x512 - 4 = 508

% Stitch start and end points.
startPoint = 2; % Start stitching from this point number
endPoint = 0; % End stitching with this point number. Zero means all points to the end
skipPoints = []; % These points will be skipped during stitching (The stitch should advance, leaving a blank space)

%% Set these if no XML is available
% Set stitching parameters manually if no XML file is available
xNumPoint = 0; % Set this to the number of rows
yNumPoint = 0; % Set this to the number of columns
direction = 0; % Choose starting stitch direction: 0 = left, 1 = right

%% new stitch
% X and Y refer to pixel matrix row and column
ydRight = 0; % Shift this many pixels when moving right
xdRight = 0; % Vertical tilt of the image, shift this many pixels up each time when moving right
ydTop = 0; % Shift right by ydTop pixels when moving up one row. Horizontal tilt
xdTop = 0; % Should be negative or 0. Controls vertical coregistration when moving up one row. Positive value would yield blank space between rows

%% New stitch and the rest of offsets
% Calculate other offsets based on the above presets
ydLeft = ydRight; % do not change
ydRight = dataSize - ydRight; % do not change
xdLeft = -xdRight; % do not change
 
if endPoint == 0
    endPoint = xNumPoint * yNumPoint;
end

if (direction == 0)
    startPosGlobal = ([(xNumPoint - 1/2) * dataSize, (yNumPoint - 1/2) * dataSize]); % Starting point: bottom right
else
    startPosGlobal = ([(xNumPoint - 1/2) * dataSize, (1/2) * dataSize]); % Starting point: bottom left
end 

% Create list of points for this stitch
pointList = startPoint : endPoint + 1;

allDataStitch = zeros((xNumPoint + 2) * dataSize, (yNumPoint + 2) * dataSize);

% Create a weights matrix
weights = zeros(dataSize, dataSize);
for k = 1:floor(dataSize/2)
    weights([k, dataSize - k + 1], k : dataSize - k + 1) = k;
    weights(k : dataSize - k + 1, [k, dataSize - k + 1] ) = k;
end

% Main stitching loop, this code should not be modified on run-to-run basis
for i=1:xNumPoint
    xloc = xNumPoint - i + 1;
    for j=1:yNumPoint
        yloc = yNumPoint - j + 1;
        currPoint = (i-1) * yNumPoint + j;
       
        % Set serpentine direction for even and odd rows
        if (mod(i,2) == 0)
            currentDirection = ~direction;
            if direction == 0
                yloc = j;
            end
        else
            currentDirection = direction; 
            if direction == 1
                yloc = j;
            end
        end
       
        % Get current data frame 
        currData = double(imread([TIFs_PATH, '/Point', num2str(pointList(currPoint)), '/TIFs/', channel, '.tif']));
        currData = currData(3 : dataSize + 2, 3 : dataSize + 2);
       
        % Get first position
        if (i == 1) && (j == 1) % first point. No coregistering
            currPos = startPosGlobal;
            allDataStitch(currPos(1) : currPos(1) + dataSize - 1, currPos(2) : currPos(2) + dataSize - 1) = currData;
            continue;
        end
           
       % Stitching starts here.
       lastPos = currPos;
              
       if (currentDirection == 1) && ~(yloc == 1) % registering along right movement
           currPos = ([lastPos(1) + xdRight, lastPos(2) + ydRight]);          
       elseif ((currentDirection == 0) && (yloc == yNumPoint)) || ((currentDirection == 1) && (yloc == 1)) % registration along top movement
           currPos = ([lastPos(1) - dataSize - xdTop, lastPos(2) + ydTop]); % shift coordinates. if more pos moving up or increasing gap between frames. 
       elseif (currentDirection == 0) && ~(yloc == yNumPoint) %registering along left movement
           currPos = ([lastPos(1) + xdLeft, lastPos(2) - ydRight]);
       end
       
       % Skip the point if needed, leaving blank space in the stitch
       if ismember(currPoint, skipPoints) 
           continue;
       end
       
       % Add the current point to the stitch matrix, adjusting for existing
       % pixels in the overlap
       prevData = allDataStitch(currPos(1) : currPos(1) + dataSize - 1, currPos(2) : currPos(2) + dataSize - 1);
       currData = MibiCalcOverlap(prevData, currData, weights);

       allDataStitch(currPos(1) : currPos(1) + dataSize - 1, currPos(2) : currPos(2) + dataSize - 1) = currData;
   end
end



% plot final image
%figure; 
data=allDataStitch;
% data(data>capImage) = capImage;
% imagesc(data);
% colormap(gray);
% colorbar;
% title(p{1}.massDS.Label{plotChannelInd});T
%set(gca,'xtick',[],'ytick',[]);

if ~exist(OutputFolder,'dir')
    mkdir(OutputFolder);
end

%Make and save images and close figures
imwrite((uint16(data)),[OutputFolder,'/Stitched_',channel,'.tif']);
close all;
