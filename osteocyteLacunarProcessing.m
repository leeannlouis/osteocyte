%% Take .czi(s) and save tif stack(s) to use for lacunar analysis
% This script takes in the directory where the processing data is held, and
% .czi file(s). It loads those volumes, rotates and crops them as directed
% by the user, and outputs them into the directory. It also outputs a new
% table with the processing summary, including rotations applied, image 
% size, crop locations, and input / output file names.

% Must have Bio-Formats installed. Put it in the toolbox folder and then
% use the pathtool to ensure it is included.
% https://docs.openmicroscopy.org/bio-formats/6.1.0/developers/matlab-dev.html

% Setup
% cd(); % Change to the directory where your custom functions are held
clear; clc; close all;
% set(0,'DefaultFigureWindowStyle','docked') % Dock figures if preferred

% Hard coded stuff
thickness = 30;     % in um. Crop all data to this thickness. 

% Get the output data directory
oDir = uigetdir('', 'Where is the table / where to output data?');

% Get the processing table data
[maxVers, pFile] = getMaxFileVers(oDir, 'lacunarDensityProcessing');
pTable = readtable(fullfile(oDir, pFile), 'ReadVariableNames', true);
pTableNew = pTable;     % Create a copy of the tables for concatenation

% Get the date in the proper format
todayStr = getTodayStr();

%% Load czi files, process (rotate and crop), save volume and metadata

% Get the .czi file(s) to analyze
[cfiles, cpath] = uigetfile('.czi', 'Choose the .czi file(s)', 'MultiSelect', 'on');

% Change to cell if only one file selected
if ischar(cfiles)   
    cfiles = {cfiles};  
end

for cIdx = 1:size(cfiles, 2)
   
    % Get the file name
    cfile = cfiles{cIdx};
    
    % Check if the file has been evaluated previously
    redo = 'NA';
    if ismember(cfile, pTable.InputFileName)
        
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
        fprintf('cannot open, not a Bioformats file.\n');
    end

    % Get key file metadata
    metadata = czi{1, 4};
    width = metadata.getPixelsSizeX(0).getValue();
    height = metadata.getPixelsSizeY(0).getValue();
    allSlices = metadata.getPixelsSizeZ(0).getValue();
    xstep = str2double(metadata.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER));
    ystep = str2double(metadata.getPixelsPhysicalSizeY(0).value(ome.units.UNITS.MICROMETER));
    zstep = str2double(metadata.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER));

    % Get the desired number of slices based on the hard-coded thickness (could
    % also use getCropZ to choose manual cropping)
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

    % Get the cropping region in XY
    [xmin, xmax, ymin, ymax] = getCropXY(volRot);
    volCrop = volRot(ymin:ymax, xmin:xmax, :);

    % Save the new volume in a multi-page tif with the same name as the
    % original file plus the extension _proc[today's date].tif. 
    [~, pFileName, ~] = fileparts(cfile);
    pFileName = [pFileName, '_proc', todayStr, '.tif'];
    fprintf(['Saving data with name ', char(pFileName), '... '])
    writeMultipageTif(volCrop, fullfile(oDir, pFileName));
    fprintf('done. \n')

    % Collect metadata
    pTableAdd = array2table(cell(1, size(pTable, 2)), ...
        'VariableNames', pTable.Properties.VariableNames); % Make a clean row
    dataDirParts = regexp(cpath, '\', 'split'); % Get the input data directory
    pTableAdd.DataDirectory = dataDirParts{end-1};
    pTableAdd.InputFileName = cfile;
    pTableAdd.OutputFileName = pFileName;
    pTableAdd.DateProcessed = todayStr;
    pTableAdd.RotationPerformed_Deg = rotation;
    pTableAdd.IsRedo = redo;
    pTableAdd.Width_Pixels = size(volCrop, 2);
    pTableAdd.Height_Pixels = size(volCrop, 1);
    pTableAdd.Depth_Pixels = size(volCrop, 3);
    pTableAdd.XResolution_um = xstep;
    pTableAdd.YResolution_um = ystep;
    pTableAdd.ZResolution_um = zstep; 
    pTableAdd.CropX1 = xmin;        pTableAdd.CropX2 = xmax;
    pTableAdd.CropY1 = ymin;        pTableAdd.CropY2 = ymax;
    pTableAdd.CropZ1 = 1;           pTableAdd.CropZ2 = numSlices;

    % Append the new data
    pTableNew = vertcat(pTableNew, pTableAdd);

end

% Save the updated metadata file
writeNewTable(pTable, pTableNew, oDir, 'lacunarDensityProcessing', maxVers + 1);
