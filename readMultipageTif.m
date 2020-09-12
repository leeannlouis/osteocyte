function tif_stack = readMultipageTif(tif_file)
% Given a multipage tif file (tif_file), read it and output the stack as a
% 3D volume (tif_stack).

% Get the structure information
tif_info = imfinfo(tif_file);

% Using the information, create an empty stack
tif_stack = zeros(tif_info(1).Height, tif_info(1).Width, size(tif_info, 1));

% Create the volume
for i = 1:size(tif_stack, 3)
   
    % Add each image to the stack
    tif_stack(:, :, i) = imread(tif_file, i);
    
end

end
