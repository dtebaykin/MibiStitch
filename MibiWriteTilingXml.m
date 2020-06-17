%% This script creates an xml to tile a large rectangular area
% Author: Dmitry Tebaykin 
% dmitry.tebaykin@stanford.edu

%% SCRIPT INPUTS 
% outputFileName - the output xml file path
% inputFileName - the input xml file with single point coordinates
% horizontalJog - the amount of movement during a horizontal step in motor(MIBI) units
% verticalJog - the amount of movement during a vertical step in motor(MIBI) units

outputFileName = "test.xml";
inputFileName = "2018-10-20_Glia_run1.xml"; % IMPORTANT: the input XML has to contain a single point
anchorPoint = 0; % 0 = center, 1 = first point, 2 = last point

colNum = 24; % colNum - number of columns in stitch
rowNum = 9; % rowNum - number of rows in stitch

horizontalJog = 5400; % Calculate this as: TileSize - desired horizontal overlap
verticalJog = 5400; % Calculate this as: TileSize - desired vertical overlap

direction = 0; % 1 = start by moving left, 0 = start by moving right
skipPoints = [12:50,65:90,150,151,202:215]; % Example: skipPoints = [2,3,5]; Examine ScanningPlot.png for predicted tiling


%% SCRIPT START, NO USER INPUT NECESSARY BEYOND THIS POINT
% read input xml
textXML = fileread(inputFileName);
paramNames= {'XAttrib', 'YAttrib'};
% it means coord={0,0:0,0} to create an array of zeros for two rows two
% columns to pre-allocate/reserve space in the computer.
% It helps to make and display the initial XAttrib and YAttrib coordinate for Points A and C like so:
%-85500      216680
%-85500      222080
coord = zeros(3,2);
% find parameters
for i=1:length(paramNames)
    pattern=[paramNames{i},'="([\+-\w.]+)"\>'];%to recognise all symbol in the xml file in a sequence such as numeric followed alphabetic angle bracket
    [matchExp,tok,ext]= regexp(textXML, pattern, 'match','tokens','tokenExtents');
    coord(3,i) = str2num(tok{1}{1});
end

% Calculate top left and bottom right corners given the center point
switch anchorPoint
    case 0
        coord(1,1) = coord(3,1) - floor((colNum - 1)/2) * horizontalJog;
        coord(1,2) = coord(3,2) + floor((rowNum - 1)/2) * verticalJog;
        coord(2,1) = coord(3,1) + floor(colNum/2) * horizontalJog;
        coord(2,2) = coord(3,2) - floor(rowNum/2) * verticalJog;
        
    case 1
        coord(1,1) = coord(3,1);
        coord(1,2) = coord(3,2);
        coord(2,1) = coord(3,1) + (colNum - 1) * horizontalJog;
        coord(2,2) = coord(3,2) - (rowNum - 1) * verticalJog;
        
    case 2
        coord(1,1) = coord(3,1) - (colNum - 1) * horizontalJog;
        coord(1,2) = coord(3,2) + (rowNum - 1) * verticalJog;
        coord(2,1) = coord(3,1); 
        coord(2,2) = coord(3,2);
        
    otherwise
        disp('ERROR: Set anchorPoint to 0, 1 or 2')
end

%% Populate pointsLoc with all points coordinates
pointsLoc = zeros(rowNum*colNum,2);
currPoint = coord(1,:);
for i = 1:rowNum
    direction=~direction;
    for j = 1:colNum
        if (i == 1 && j == 1) % deal with first point
            pointsLoc(1,:) = currPoint;
        elseif (j == 1) % deal with first point in line. Move up is "-", move down is "+"
            pointsLoc((i - 1) * colNum + j, 1) = currPoint(1);
            pointsLoc((i - 1) * colNum + j, 2) = currPoint(2) - verticalJog; %change sign currPoint(2) +/- verticalJog
        else % move right or left, according to direction
            if direction
                pointsLoc((i - 1) * colNum + j, 1) = currPoint(1) + horizontalJog;
            else
                pointsLoc((i - 1) * colNum + j, 1) = currPoint(1) - horizontalJog;
            end
            pointsLoc((i - 1) * colNum + j, 2) = currPoint(2);
        end
        
        % update current point
        currPoint(1) = pointsLoc((i - 1) * colNum + j, 1);
        currPoint(2) = pointsLoc((i - 1) * colNum + j, 2);
    end
end

%% Create ScanningTable.xml - it contains number and coordinates for each point as a summary from the full XML file
fTable = fopen([pwd, '/ScanningTable.xml'],'w'); % need to have a different name from all
pointName = 1; % Keeps track of point number that will go into output XML file - from 1 to N, ignores skipped points
x = {};
y = {};
for i=1:rowNum
    for j=1:colNum
        pointNumber = (i-1) * colNum + j;
        if ~ismember(pointNumber, skipPoints) 
            toAdd = ['Point', num2str(pointName),' ' , num2str(pointsLoc(pointNumber,1)), ' ', num2str(pointsLoc(pointNumber,2)), '\n'];
            x{pointName} = pointsLoc(pointNumber,1);
            y{pointName} = pointsLoc(pointNumber,2);

            fprintf(fTable, toAdd);
            pointName = pointName + 1;
        end
    end
end
fclose(fTable);

%% produce plot of points
set(0,'DefaultFigureVisible','off');
plot_dir(cell2mat(x), cell2mat(y), coord(:,1), coord(:,2));
saveas(gcf,'ScanningPlot.png');
set(0,'DefaultFigureVisible','on');

%% print to output file

% get the header and sections from the input file
% divide input file to rows
C = strsplit(textXML,'\n');

% print header into output file. Stop when getting to <Point
fileID = fopen(outputFileName,'w');
i=1;
k = strfind(C{i},'<Point');
while isempty(k)
    currText = strrep(C{i},'\','\\');
    fprintf(fileID,currText);
    i=i+1;
    k = strfind(C{i},'<Point');
end

% get point data
pointData = {};
pointData{1} = C{i};
i=i+1;
k = strfind(C{i},'<Point');
while isempty(k)
    pointData{end+1} = C{i};
    i=i+1;
    k = strfind(C{i},'</Point');
end
pointData{end+1} = C{i};

%fStub = fopen('MIBIWriteTilingXMLStub.txt','r');
%MIBIStub = fscanf(fStub, '%c', Inf);
%fclose(fStub);

% gerenerate all points and print to file
pointName = 1;
for i=1:rowNum
    for j=1:colNum
        pointNumber = (i-1) * colNum + j;
        if ~ismember(pointNumber, skipPoints)           
            for k= 1:length(pointData)
                currStr = pointData{k};
                currStr = strrep(currStr,'\','\\');

                % This changes point names to 'PointX' where X is the point number. 
                toName = strfind(currStr,'<Point PointName=');
                if toName
                    currStr = ['<Point PointName="Point', num2str(pointName), '">\n'];
                end

                tof = strfind(currStr,'<RowNumber0');
                if tof
                    currStr = strrep(currStr, num2str(coord(3,1)), num2str(pointsLoc(pointNumber, 1)));
                    currStr = strrep(currStr, num2str(coord(3,2)), num2str(pointsLoc(pointNumber, 2)));
                    %currStr = strcat(currStr, MIBIStub, '\n');
                end
                fprintf(fileID,currStr);
            end
            pointName = pointName + 1;
        end
    end
end
fprintf(fileID,'  </Root>\n');
fprintf(fileID,'</DocRoot>\n');
fclose(fileID);
