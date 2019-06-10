function MibiWriteTilingXmlCenterRect(outputFileName,inputFileName,TileSize,xNum,yNum,Overlap)
% Add this line in command window MibiWriteTilingXmlCenterRect('outputFileName.xml','inputFileName.xml',TileSize,NumRows,NumCols,Overlap)
% example: MibiWriteTilingXmlCenterRect('test.xml','180615-HIGHPRESET.xml',5600,5,6,200)

% fill in the outputfilename, inputfilename, tilesize and Overlap 
% Function creates an xml to tile a large rectangle area
% outputFileName - the output xml file
% inputFileName - the input xml file with center point coordinates
% TileSize - the size of each frame in motor(MIBI) units
% xNum - number of frames(points) in one column
% yNum - number of frames(points) in one row
% Overlap - the amount of overlap between two adjacent frames

%% read input xml
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
coord(1,1) = coord(3,1) - floor((yNum - 1)/2) * (TileSize - Overlap);
coord(1,2) = coord(3,2) + floor((xNum - 1)/2) * (TileSize - Overlap);
coord(2,1) = coord(3,1) + floor(yNum/2) * (TileSize - Overlap);
coord(2,2) = coord(3,2) - floor(xNum/2) * (TileSize - Overlap);

% Populate pointsLoc with all points coordinates
pointsLoc = zeros(xNum*yNum,2);
direction = 0; % 1 indicates move rightwards and 0 indicates move leftwards (flips on start)
currPoint = coord(1,:);
for i=1:xNum
    direction=~direction;
    for j=1:yNum
        if (i==1 && j==1) % deal with first point
            pointsLoc(1,:) = currPoint;
        elseif (j==1) % deal with first point in line. Move up is - move down is +
            pointsLoc((i-1)*yNum+j,1) = currPoint(1);
            pointsLoc((i-1)*yNum+j,2) = currPoint(2) - (TileSize - Overlap);%change sign currPoint(2) +/- (TileSize-Overlap)
        else % move right or left, according to direction
            if direction
                pointsLoc((i-1)*yNum+j,1) = currPoint(1) + (TileSize - Overlap);
            else
                pointsLoc((i-1)*yNum+j,1) = currPoint(1) - (TileSize - Overlap);
            end
            pointsLoc((i-1)*yNum+j,2) = currPoint(2);
        end
        % update current point
        currPoint(1) = pointsLoc((i-1)*yNum+j,1);
        currPoint(2) = pointsLoc((i-1)*yNum+j,2);
    end
end

fTable = fopen([pwd, '/ScanningTable.xml'],'w'); % need to have a different name from all
for i=1:xNum
    for j=1:yNum
        toAdd = ['Point', num2str((i-1)*yNum+j),' X= ' , num2str(pointsLoc((i-1)*yNum+j,1)), ' Y= ', num2str(pointsLoc((i-1)*yNum+j,2)), '\n'];
        x{(i-1)*yNum + j} = pointsLoc((i-1)*yNum+j,1);
        y{(i-1)*yNum + j} = pointsLoc((i-1)*yNum+j,2);
        
        fprintf(fTable, toAdd);
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
for i=1:xNum
    for j=1:yNum
        for k= 1:length(pointData)
            currStr = pointData{k};
            currStr = strrep(currStr,'\','\\');
            
            % This changes point names from 'topleft' to 'PointX' where X
            % is the point number. 
            %toName = strfind(currStr,'<Point PointName=');
            %if toName
            %    currStr = strrep(currStr, 'topleft', ['Point', num2str((i-1)*yNum+j)]);
            %end
            
            tof = strfind(currStr,'<RowNumber0');
            if tof
                currStr = strrep(currStr,num2str(coord(3,1)),num2str(pointsLoc((i-1)*yNum+j,1)));
                currStr = strrep(currStr,num2str(coord(3,2)),num2str(pointsLoc((i-1)*yNum+j,2)));
                %currStr = strcat(currStr, MIBIStub, '\n');
            end
            fprintf(fileID,currStr);
        end
    end
end
fprintf(fileID,'  </Root>\n');
fprintf(fileID,'</DocRoot>\n');
fclose(fileID);
