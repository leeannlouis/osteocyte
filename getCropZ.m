function [z1, z2] = getCropZ(volume, figHandle)
% Given an input volume, ask the user whether the number of slices should
% be cropped by allowing the user to look at the stack of slices. Ouputs 
% the start and end slice numbers of the cropping region. Optional input 
% for figure handle. 

% Check for figureHandle input
if ~exist('figHandle', 'var')
    figHandle = 1;
end

% Ask the user for input rotations until the rotation is correct
needsCrop = 'Y';    % Initialize user input variable
z1 = 1; z2 = size(volume, 3);   % Initialize crop variables
while strcmpi(needsCrop, 'Y') || isempty(needsCrop)
    
    % Crop by the given amount
    volCropped = volume(:, :, z1:z2); 
    
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
        z1 = input('Start index? Typing 1 indicates no crop [1]:');
        if isempty(z1)
            z1 = 1;
        end
        
        % Get end cropping index
        endIdxStr = num2str(size(volume, 3));
        z2 = input(['End index? Typing ', endIdxStr, ...
            ' indicates no crop [', endIdxStr, ']:']);
        if isempty(z2)
            z2 = 1;
        end

    end

end

end