%% Take .czi(s) and save tif stack(s) to use for lacunar analysis
% This script takes in the .czi file(s), which are 2D images or 3D stacks
% taken by Zeiss-branded microscope. Here we used the LSM800, a laser
% scanning confocal microscope. Images are of fluorescent stained cortical
% bone. Script loads those volumes, rotates and crops them as directed
% by the user, and outputs them as a .tif stack  into the given output 
% directory. It also adds this processing data (rotation, cropping
% locations, image size, processing date, etc.) to the database.

% Must have Bio-Formats MATLAB Toolbox installed. Download bfmatlab.zip
% from the page below and add to the toolbox using the pathtool
% https://www.openmicroscopy.org/bio-formats/downloads/

% Setup
clear; clc; close all;
% set(0,'DefaultFigureWindowStyle','docked') % Dock figures if preferred

% Hard coded stuff
thickness = 30;     % in um. Crop all data to this thickness. 

% Get the output data directory
oDir = uigetdir('', 'Analysis folder to output .csv and .tif files');

% Connect to the osteocyte.db database
[dbfile, dbpath] = uigetfile('\*.db', 'Choose the .db file');
mksqlite('open', fullfile(dbpath, dbfile));

% Get today string for future use
todayStr = getTodayStr();

% Get the .czi file(s) to analyze
[cfiles, cpath] = uigetfile('.czi', 'Choose the .czi file(s)', 'MultiSelect', 'on');

% Change to cell if only one file selected
if ischar(cfiles)   
    cfiles = {cfiles};  
end

% Step through all the data
for cIdx = 1:size(cfiles, 2)
   
    % Get the file name
    cfile = cfiles{cIdx};
    
    % Check if the file has been evaluated previously
    priorData = mksqlite(['SELECT * FROM processing WHERE ' ...
        'InputFileName = "', cfile, '"']);
    redo = 'NA';
    if ~isempty(priorData)
        
        % Ask user if they want to redo the processing
        redo = input(['Data already exists for ', cfile, '. Redo? Y/N '], 's');
        while ~ismember(redo, {'Y', 'N', 'y', 'n'})
            redo = input('Invalid entry, try again. ', 's');
        end
        
    end
    
    % Continue if the response is yes
    if ~ismember(redo, {'Y', 'y', 'NA'})
        fprintf(['Skipping ', cfile, '.\n'])
        continue
    end
    
    % Try to open the file
    try 
        fprintf('Opening %s... ', cfile);
        [~, czi] = evalc('bfopen([cpath, cfile])');
        fprintf('opened.\n');
    catch
        fprintf('not a Bioformats file or Bioformats not installed.\n');
    end

    % Get key file metadata
    metadata = czi{1, 4};
    width = metadata.getPixelsSizeX(0).getValue();
    height = metadata.getPixelsSizeY(0).getValue();
    zstep = str2double(metadata.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER));
    
    % Get the desired number of slices based on the hard-coded thickness 
    % (could also use getCropZ to choose manual cropping) and the file's
    % pixel size in the z-axis.
    numSlices = floor(thickness / zstep); 

    % Get the data
    series = czi{1, 1};

    % Create empty holders
    volume = zeros(height, width, numSlices);

    % Create volume. Only use the desired number of slices
    for idxSlice = 1:numSlices
        thisImage = series{idxSlice, 1};
        volume(:, :, idxSlice) = thisImage;
    end
    clear thisImage;

    % Convert volume from 0 255 to 0 to 1 (typical for image of type double)
    volume = mat2gray(volume);

    % Get the middle slice and use it to get the rotation. 
    midSlice = volume(:, :, round(size(volume, 3)/2));
    rotation = getRotation(midSlice);

    % Rotate the volume
    volRot = imrotate(volume, rotation);

    % Get the cropping region in XY. Use an exclusive cropping region to
    % ensure that no external parts of 
    [xmin, xmax, ymin, ymax] = getCropXY(volRot, 'exclusive');
    volCrop = volRot(ymin:ymax, xmin:xmax, :);

    % Save the new volume in a multi-page tif with the same name as the
    % original file plus the extension _proc[today's date].tif. 
    [~, pFileName, ~] = fileparts(cfile);
    pFileName = [pFileName, '_proc', todayStr, '.tif'];
    fprintf(['Saving data with name ', char(pFileName), '... '])
    %writeMultipageTif(volCrop, fullfile(oDir, pFileName));
    fprintf('done. \n')

    % Collect the data to add and get it in the right format for use in a
    % SQL query. That is, TEXT outputs have double quotes around them,
    % numbers are converted to strings for use in the query, and all values
    % are separated by commas
    dataDirParts = regexp(cpath, '\', 'split'); % Get the input data directory
    values_to_add = createSqlValueList({dataDirParts{end-1}, cfile, pFileName, ...
        todayStr, redo, rotation, size(volCrop, 2), size(volCrop, 1), ...
        size(volCrop, 3), xmin, xmax, ymin, ymax, 1, numSlices});
    
    % Add the data to the database
    mksqlite(['INSERT INTO processing(DataDirectory, InputFileName, ', ...
        'OutputFileName, DateProcessed, IsRedo, RotationPerformed_Deg, ', ...
        'Width_Pixels, Height_Pixels, Depth_Pixels, CropX1, CropX2, ', ...
        'CropY1, CropY2, CropZ1, CropZ2) VALUES (', values_to_add, ')']);

end

% Get a copy of the new processing datasheet that you appended here
% using a SQL command. It comes out as a structure, convert to a table.
newTable = struct2table(mksqlite('SELECT * FROM processing'));
fileNameOut = ['processing-', todayStr, '.csv'];
writetable(newTable, fullfile(oDir, fileNameOut));
fprintf(['New file created: ', fileNameOut, '\n']);

% Close the database
mksqlite('close');
