% MIBI smooth stitching script used by the all channel stitch loop
% Author: Dmitry Tebaykin
% Contact: dmitry.tebaykin@stanford.edu

if exist(xmlFileName, 'file')
    textXML = fileread(xmlFileName);
    paramNames= {'XAttrib', 'YAttrib'};
    pointsLoc = zeros(0,2);

    for i=1:length(paramNames)
        pattern=[paramNames{i},'="([\+-\w.]+)"\>'];
        [matchExp,tok,ext]= regexp(textXML, pattern, 'match','tokens','tokenExtents');

        for j=1:length(tok)
            pointsLoc(j,i) = str2double(tok{j}{1});
        end
    end

    % Calculate number of rows and cols
    if endPoint == 0
        endPoint = length(pointsLoc);
    end

else
    if endPoint == 0
        endPoint = xNumPoint * yNumPoint;
    end

    if (direction == 0)
        startPosGlobal = ([(xNumPoint - 1/2) * dataSize, (yNumPoint - 1/2) * dataSize]); % Starting point: bottom right
    else
        startPosGlobal = ([(xNumPoint - 1/2) * dataSize, (1/2) * dataSize]); % Starting point: bottom left
    end 
end

% Create list of points for this stitch
pointList = startPoint : endPoint + 1;

allDataStitch = zeros((xNumPoint + 2) * dataSize, (yNumPoint + 2) * dataSize);

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
