function rotation = getRotation(image, figHandle)
% Given an image, display it and ask the user whether rotation is needed,
% and how much, until the user is satisfied with the figure. Optional
% arguement figureHandle allows control over figure output.

% Check for figureHandle input
if ~exist('figHandle', 'var')
    figHandle = 1;
end

% Ask the user for input rotations until the rotation is correct
needsRot = 'Y'; % Initialize user input variable
rotation = 0;   % Initialize rotation variable
while strcmpi(needsRot, 'Y') || isempty(needsRot)
    
    % Rotate the slice by the given amount
    imRot = imrotate(image, rotation); 
    
    % Display the slice with the chosen rotation
    if rotation == 0
        figure(figHandle); imshow(image);
    else
        figure(figHandle); imshowpair(image, imRot, 'montage');
    end
    
    % Ask user if the image needs to be rotated
    needsRot = input('Does the image need to be rotated? Y/N [Y] ', 's');
    
    % Check for incorrect responses
    while ~ismember(needsRot, {'Y', 'N', 'y', 'n', ''})
        needsRot = input('Invalid entry, try again. Does the image need to be rotated? Y/N [Y] ', 's');
    end
    
    % Ask for rotation if requested
    if strcmpi(needsRot, 'Y') || isempty(needsRot)
        rotation = input(['Rotation value (+CCW, -CW) (prior: ', ...
            num2str(rotation), '): ']);
        
        % Check for missing value
        if isempty(rotation)
            rotation = 0;
        end
        
    end

end

end
