% Calculate the intersection of two frames: previous and current. 
% Inputs:
% previous - overlap in the previous data
% current - overlap in the current frame
% Output:
%   currentAdj - current frame, adjusted for the overlap
%
% Author: Dmitry Tebaykin
% Contact: dmitry.tebaykin@stanford.edu

function currentAdj = MibiCalcOverlap(previous, current, weights)
% Area before the overlap that does not inherit from the other frame
%OVERLAP_BUFFER = 20;

currentAdj = current;

% Find all non-zero pixels from previous frames in the current frame
[row, col, val] = find(previous);

% If there is no overlap with previous frames - return
if isempty(val)
    return;
end

% Find the maximum weight
%maxWeightIndex = min([max(row), max(col)]);
%maxWeight = weights(maxWeightIndex, maxWeightIndex);

% Adjust the current frame accordingly
% For now: assuming previous frame does not go past center of the current
% frame
for k = 1:length(val)
    i = row(k);
    j = col(k);
    %currentAdj(i, j) = round((maxWeight - weights(i,j) + 1) / maxWeight * previous(i,j) + weights(i,j) / maxWeight * current(i,j));
    if i >= j
        currentAdj(i, j) = mean([previous(i,j),current(i,j)]) / 4; % Intensity for ROW overlap
    else
        currentAdj(i, j) = mean([previous(i,j),current(i,j)]) / 2; % Intensity for COL overlap
    end
end

