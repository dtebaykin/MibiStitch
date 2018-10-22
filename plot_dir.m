function [h1, h2] = plot_dir (vX, vY, xPos, yPos)
%function [h1, h2] = plot_dir (vX, vY)
%Plotting x-y variables with direction indicating vector to the next element.
%Example
%   vX = linspace(0,2*pi, 10)';
%   vY = sin (vX);
%   plot_dir(vX, vY);

rMag = 0.5;

% Length of vector
lenTime = length(vX);

% Indices of tails of arrows
vSelect0 = 1:(lenTime-1);
% Indices of tails of arrows
vSelect1 = vSelect0 + 1;

% X coordinates of tails of arrows
vXQ0 = vX(vSelect0);
% Y coordinates of tails of arrows
vYQ0 = vY(vSelect0);

% X coordinates of heads of arrows
vXQ1 = vX(vSelect1);
% Y coordinates of heads of arrows
vYQ1 = vY(vSelect1);

% vector difference between heads & tails
vPx = (vXQ1 - vXQ0) * rMag;
vPy = (vYQ1 - vYQ0) * rMag;

% make plot 
h1 = plot (vX, vY, '.-'); hold on;
plot(xPos, yPos, 'b*');
%set(gca, 'Ydir', 'reverse');
% add arrows 
h2 = quiver (vXQ0,vYQ0, vPx, vPy, 0, 'r'); 
%set(gca, 'Ydir', 'reverse');
grid on; hold off
axis equal