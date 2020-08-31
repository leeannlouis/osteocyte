function [zmin, zmax] = getCropZ(volume, figHandle)

% Check for figureHandle input
if ~exist('figHandle', 'var')
    figHandle = 1;
end

% Ask the user for input rotations until the rotation is correct
needsCrop = 'Y';    % Initialize user input variable
zmin = 1; zmax = size(volume, 3);   % Initialize crop variables
while strcmpi(needsCrop, 'Y') || isempty(needsCrop)
    
    % Crop by the given amount
    volCropped = volume(:, :, zmin:zmax); 
    
    % Display the cropped volume
    figure(figHandle); sliceViewer(volCropped);
    
    % Ask user if the image needs to be rotated
    needsCrop = input('Does the volume need to be cropped in Z? Y/N [Y] ', 's');
    
    % Check for incorrect responses
    while ~ismember(needsCrop, {'Y', 'N', 'y', 'n', ''})
        needsCrop = input('Invalid entry, try again. Does the image need to be cropped in Z? Y/N [Y] ', 's');
    end
    
    % Ask for crop if requested
    if strcmpi(needsCrop, 'Y') || isempty(needsCrop)
        
        % Get start cropping index
        zmin = input('Start index? Typing 1 indicates no crop [1]:');
        if isempty(zmin)
            zmin = 1;
        end
        
        % Get end cropping index
        endIdxStr = num2str(size(volume, 3));
        zmax = input(['End index? Typing ', endIdxStr, ...
            ' indicates no crop [', endIdxStr, ']:']);
        if isempty(zmax)
            zmax = 1;
        end

    end

end

end