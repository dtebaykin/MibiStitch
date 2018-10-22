% Create two files: xml table of all points and their coordinates for the
% given run; png figure of connections between the points
%
% Author: Dmitry Tebaykin
% Contact: dmitry.tebaykin@stanford.edu

function MibiDrawDirection(inputFileName)
%% read input xml
textXML = fileread(inputFileName);
paramNames= {'XAttrib', 'YAttrib'};
pointsLoc = zeros(0,2);

% find parameters
for i=1:length(paramNames)
    pattern=[paramNames{i},'="([\+-\w.]+)"\>'];
    [matchExp,tok,ext]= regexp(textXML, pattern, 'match','tokens','tokenExtents');
    
    for j=1:length(tok)
        pointsLoc(j,i) = str2double(tok{j}{1});
    end
end

x = cell(length(pointsLoc), 1);
y = cell(length(pointsLoc), 1);
fTable = fopen([pwd, '/ScanningTable.xml'],'w'); 
for i = 1:length(pointsLoc)
    toAdd = ['Point', num2str(i),' X= ' , num2str(pointsLoc(i,1)), ' Y= ', num2str(pointsLoc(i,2)), '\n'];
    x{i} = pointsLoc(i,1);
    y{i} = pointsLoc(i,2);

    fprintf(fTable, toAdd);
end
fclose(fTable);

%% produce plot of points
set(0,'DefaultFigureVisible','off');
plot_dir(cell2mat(x), cell2mat(y), pointsLoc(:,1), pointsLoc(:,2));
saveas(gcf,'ScanningPlot.png');
set(0,'DefaultFigureVisible','on');


