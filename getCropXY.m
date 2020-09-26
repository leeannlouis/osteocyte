function [x1, x2, y1, y2] = getCropXY(volume, cropSetting, figHandle)
% Given an input volume (volume), asks the user for the top left and bottom
% right corners to use to crop the image. Does this twice. If 'cropSetting'
% is 'inclusive', the largest area of the selected points is used. with
% this setting, point click order does not matter. if 'cropSetting' is 
% 'exclusive', it takes the smallest area given. The function then assumes
% that points are clicked in the order 1) upper left, 2) lower right, 3) 
% upper left, 4) lower right. Ouputs the x and y coordinates of the 
% cropping region. Optional input for figure handle.

% Check for figureHandle input
if ~exist('figHandle', 'var')
    figHandle = 1;
end
fig = figure(figHandle);

% Get the first and last images
imFirst = volume(:, :, 1); imLast = volume(:, :, end); 

% Get the maximum x and y and set those as the initial crop regions
x1 = 1; y1= 1;              % Initialize min values
[ymax, xmax] = size(imFirst);   % Get max values
x2 = xmax; y2 = ymax;       % Initialize max values

% Ask the user for cropping region until it is correct
needsCrop = 'Y';    % Initialize user input variable
while strcmpi(needsCrop, 'Y') || isempty(needsCrop)
    
    % Show cropped image
    clf(fig); 
    figure(figHandle);
    hold on;
    imshowpair(imFirst, imLast, 'montage');
    
    % Draw rectangles to indicate cropping region
    rectangle('Position', [x1, y1, (x2-x1), (y2-y1)], ...
        'EdgeColor', 'white', 'LineStyle', '--'); 
    rectangle('Position', [x1+xmax, y1, (x2-x1), (y2-y1)], ...
        'EdgeColor', 'white', 'LineStyle', '--');
    
    % Indicate first and last slice
    text(1, 1, 'First Slice', 'VerticalAlignment', 'top', ...
        'FontSize', 20, 'Color', 'white');
    text(xmax+1, 1, 'Last Slice', 'VerticalAlignment', 'top', ...
        'FontSize', 20, 'Color', 'white');
    
    % Draw split line and finish
    xline(xmax, 'Color', 'white', 'LineWidth', 1.0);
    hold off;

    % Ask user if the image needs to be cropped
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

        % Get the x and y corner coordinates as integers.
        if strcmpi(cropSetting, 'inclusive')   
            % To take the largest (inclusive) area input:
            x1 = min([floor(p(1)), floor(p(2)), floor(q(1)), floor(q(2))]);
            y1 = min([floor(p(3)), floor(p(4)), floor(q(3)), floor(q(4))]);
            x2 = max([ceil(p(1)), ceil(p(2)), ceil(q(1)), ceil(q(2))]);
            y2 = max([ceil(p(3)), ceil(p(4)), ceil(q(3)), ceil(q(4))]);
            
        elseif strcmpi(cropSetting, 'exclusive')
            % To take the smallest area input (assumes first click is upper
            % left and second click is upper right)
            x1 = max([ceil(p(1)), ceil(q(1))]);
            y1 = max([ceil(p(3)), ceil(q(3))]);
            x2 = min([floor(p(2)), floor(q(2))]);
            y2 = min([floor(p(4)), floor(q(4))]);
            
        else
            error('Second arguement must be "inclusive" or "exclusive"');
        end

        % Ensure the dimensions are within the original image
        [ymax, xmax] = size(imFirst);
        if x1 < 1,    x1 = 1;   end
        if y1 < 1,    y1 = 1;   end
        if x2 > xmax, x2 = xmax;    end
        if y2 > ymax, y2 = ymax;    end
        hold off; 
        
    end

end

end
