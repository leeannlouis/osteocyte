function [num_top, num_mid, num_bot, L] = getLacunarCounts(volume)
% Given a binary volume, get all the connected objects. Output the number
% of objects in the top third of the image (num_top), middle third of the
% image (num_mid), and bottom third of the image (num_bot). Output a labeled
% volume (L) with top cells labeled 1, middle cells 2, and bottom cells 3. 

% Get all the connected objects
CC = bwconncomp(volume);

% Create the emtpy matrix to store the volume labeled 1, 2, or 3 for top,
% middle, and bottom lacunae
L = zeros(size(volume)); 

% Get the centroids of all objects
props = regionprops(CC, 'centroid');

% Initialize counters
num_top = 0; 
num_mid = 0; 
num_bot = 0;

% Determine the cutoff for the top third of the image and middle third of
% the image. Centroids in the "top" are from 0 to 1/3 of the height.
% Centroids in the "middle" are from 1/3 of the height to 2/3 of the
% height. Everything else should be in the "bottom".
y_top = (1/3) * size(volume, 1);
y_mid = (2/3) * size(volume, 1);

% Figure out which objects are in the top, middle, and bottom portions of
% the image. Note that centroids come out as [x-coordinate, y-coordinate,
% 3rd-dimension ...], so the second coordinate is the y-coordinate.
for obj = 1:size(props, 1)
    
    % Get this object's y-dimension
    y = props(obj).Centroid(2);
    
    % Add to the relevant counter and properly label the volume
    if y <= y_top
        num_top = num_top + 1;
        L(CC.PixelIdxList{obj}) = 1;
    elseif y <= y_mid
        num_mid = num_mid + 1;
        L(CC.PixelIdxList{obj}) = 2;
    else
        num_bot = num_bot + 1;
        L(CC.PixelIdxList{obj}) = 3;
    end
    
end

end
