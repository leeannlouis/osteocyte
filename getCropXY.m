function [xmin, xmax, ymin, ymax] = getCropXY(volume, figHandle)
% Given an input volume, ask the user for the cropping region by looking at
% the top and bottom slices. Optional input for figure handle.

% Check for figureHandle input
if ~exist('figHandle', 'var')
    figHandle = 1;
end
fig = figure(figHandle);

% Get the first and last images
imFirst = volume(:, :, 1); imLast = volume(:, :, end); 

% Get the maximum x and y and set those as the initial crop regions
xmin = 1; ymin= 1;              % Initialize min values
[maxY, maxX] = size(imFirst);   % Get max values
xmax = maxX; ymax = maxY;       % Initialize max values

% Ask the user for cropping region until it is correct
needsCrop = 'Y';    % Initialize user input variable
while strcmpi(needsCrop, 'Y') || isempty(needsCrop)
    
    % Show cropped image
    clf(fig); 
    figure(figHandle);
    hold on;
    imshowpair(imFirst, imLast, 'montage');
    
    % Draw rectangles to indicate cropping region
    rectangle('Position', [xmin, ymin, (xmax-xmin), (ymax-ymin)], ...
        'EdgeColor', 'white', 'LineStyle', '--'); 
    rectangle('Position', [xmin+maxX, ymin, (xmax-xmin), (ymax-ymin)], ...
        'EdgeColor', 'white', 'LineStyle', '--');
    
    % Indicate first and last slice
    text(1, 1, 'First Slice', 'VerticalAlignment', 'top', ...
        'FontSize', 20, 'Color', 'white');
    text(maxX+1, 1, 'Last Slice', 'VerticalAlignment', 'top', ...
        'FontSize', 20, 'Color', 'white');
    
    % Draw split line and finish
    xline(maxX, 'Color', 'white', 'LineWidth', 1.0);
    hold off;

    % Ask user if the image needs to be rotated
    needsCrop = input('Does the image need to be cropped? Y/N [Y] ', 's');
    
    % Check for incorrect responses
    while ~ismember(needsCrop, {'Y', 'N', 'y', 'n', ''})
        needsCrop = input('Invalid entry, try again. Does the image need to be cropped? Y/N [Y] ', 's');
    end
    
    % Ask for crop if requested
    if strcmpi(needsCrop, 'Y') || isempty(needsCrop)

        % Ask the user for points on the first and last images for cropping
        clf(fig); 
        figure(figHandle);
        hold on; 
        imshow(imFirst)
        text(0, 1, 'Click upper left and lower right corners for first slice', ...
            'Units', 'normalized', 'VerticalAlignment', 'top', 'Color', 'red');
        p = ginput(2);
        imshow(imLast)
        text(0, 1, 'Click upper left and lower right corners for last slice', ...
            'Units', 'normalized', 'VerticalAlignment', 'top', 'Color', 'red');
        q = ginput(2);

        % Get the x and y corner coordinates as integers
        xmin = min([floor(p(1)), floor(p(2)), floor(q(1)), floor(q(2))]);
        ymin = min([floor(p(3)), floor(p(4)), floor(q(3)), floor(q(4))]);
        xmax = max([ceil(p(1)), ceil(p(2)), ceil(q(1)), ceil(q(2))]);
        ymax = max([ceil(p(3)), ceil(p(4)), ceil(q(3)), ceil(q(4))]);

        % Ensure the dimensions are within the original image
        [maxY, maxX] = size(imFirst);
        if xmin < 1,    xmin = 1,   end
        if ymin < 1,    ymin = 1,   end
        if xmax > maxX, xmax = maxX,    end
        if ymax > maxY, ymax = maxY,    end
        hold off; 
        
    end

end

end