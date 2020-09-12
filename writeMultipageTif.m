function writeMultipageTif(volIn, filename)
% Takes in a volume (volIn) and saves it as a multipage tif in a file
% called filename. Assumes a grayscale volume if ndims(volIn) = 3, and a
% truecolor volume if ndims(volIn) = 4. (Does not currently handle
% indexed color volumes).

if ndims(volIn) == 3

    % Write the grayscale dataset
    for i = 1:size(volIn, 3)

        % Get the image
        I = mat2gray(volIn(:, :, i));

        % For the first slice, use mode overwrite to ensure you aren't
        % appending a prexisiting file. After slice 1, append.
        if i == 1
            imwrite(I, filename, 'tif', 'WriteMode', 'overwrite');
        else
            imwrite(I, filename, 'tif', 'WriteMode', 'append');
        end

    end

elseif ndims(volIn) == 4

    % Save a truecolor image stack (size x by y by z by c, where c = 3) as
    % a multipage tif. To do this, first reshape one slice to a single 
    % truecolor slice, then get its indexed colormap. Use the center slice
    % to ensure colors are present. Use that colormap to create all the
    % other indexed slices.
    [x, y, z, c] = size(volIn);       % Get the volume dimensions
    M = volIn(:, :, round(z/2), :);   % Get the center slice
    I = reshape(M, [x, y, c]);          % Reshape to a single truecolor image
    [~, map] = rgb2ind(I, 256);         % Get the indexed colormap
    
    % Save the dataset
    for i = 1:z
        I = reshape(volIn(:, :, i, :), [x, y, c]);
        A = rgb2ind(I, map);            % Use the indexed colormap
        if i == 1
            imwrite(A, map, filename, 'tif', 'WriteMode', 'overwrite');
        else
            imwrite(A, map, filename, 'tif', 'WriteMode', 'append');
        end
    end

end
