%% Osteocyte lacunar counting analysis
% Take a set of .tif stack(s) and return the number of osteocytes in their
% top, middle, and bottom sections in an excel sheet and a labeled volume.
% To try different analysis settings (number of erosions or dilations, size
% or shape of structuring element used), change the variables under the
% heading "ANALYSIS SETTINGS"

% Setup 
% cd(); % Change to directory with your custom functions
clear; clc; close all;

% Get the output data directory
oDir = uigetdir('', 'Where to output images and data?');

% Get the analysis table and make a copy for concatenation
[maxVers, aFile] = getMaxFileVers(oDir, 'lacunarDensityAnalyses-Auto');
aTable = readtable(fullfile(oDir, aFile), 'ReadVariableNames', true);
aTableNew = aTable;     % Create a copy

%%%     ANALYSIS SETTINGS   %%%
se = strel('cuboid', [4 6 6]); 
numErosions = 4; 
numDilations = 3;
mySettings = ['Gaussian Filtered, Threshold mean*1.9, ' ...
    'se cuboid 4x6x6, 4x erosions, 3x dilations'];
mySettingsExt = '_gauss-Cub4x6x6-Er4-Di3';

% Select file(s)
[tfiles, tpath] = uigetfile([oDir, '\*.tif'], 'Choose the .tif file', ...
    'Multiselect', 'on');

% If only one file selected, convert to cell for the loop to run properly
if ischar(tfiles)   
    tfiles = {tfiles};  
end

for tIdx = 1:size(tfiles, 2)

    % Get the file
    tfile = tfiles{tIdx};
    
    % Open the data
    fprintf('Opening %s... ', tfile);
    volume = readMultipageTif(fullfile(tpath, tfile));
    fprintf('opened.\n');

    % Create an empty version of the analysis table to collect the data
    aTableAdd = array2table(cell(1, size(aTable, 2)), ...
        'VariableNames', aTable.Properties.VariableNames);

    % Convert volume from 0 255 to 0 to 1 (typical for image of type double)
    volume = mat2gray(volume);

    % Do a Gaussian filter. On a 3D volume, imgaussfilt runs on each 2D slice
    % (confirmed when rounded to 10^-9 for grayscale values 0 to 1
    % Can try: volMedian = medfilt3(volume, [1 1 1]); 
    fprintf('Filtering... ')
    volGauss = imgaussfilt(volume);

    % Get threshold by getting the mean and multiplying by 1.9
    % Can try: volThresh = imbinarize(volGauss);
    threshold = mean(volGauss, 'all') * 1.9;
    volThresh = volGauss > threshold;

    % Erode and dilate so only lacunae are left
    fprintf('eroding... ')
    volEroded = volThresh; 
    for i = 1:numErosions
        volEroded = imerode(volEroded, se);
    end
    fprintf('dilating... ')
    volDilated = volEroded;
    for i = 1:numDilations
        volDilated = imdilate(volDilated, se);
    end

    % Remove objects on edges
    fprintf('removing edge objects... ');
    volNoEdges = imclearborder(volDilated);

    % Count the objects in the different regions
    fprintf('counting objects... '); 
    [num_top, num_mid, num_bot, L] = getLacunarCounts(volNoEdges);
    fprintf('done analyzing.\n');

    % Create the multicolor volume
    fprintf('Creating color volume... ');
    volComb = createOverlayRGB(volume, L == 1, L == 2, L == 3);
    fprintf('done.\n');

    % Save the volumes as three separate files (1top.tif, 2mid.tif, 3bot.tif), 
    % and a single multicolor volume.
    fprintf('Saving all volumes... ')
    [~, fileOutName, ~] = fileparts(tfile);
    fileOutName = [fileOutName, '_analy', getTodayStr(), mySettingsExt];
    writeMultipageTif(L == 1, fullfile(oDir, [fileOutName, '_1top.tif']));
    writeMultipageTif(L == 2, fullfile(oDir, [fileOutName, '_2mid.tif']));
    writeMultipageTif(L == 3, fullfile(oDir, [fileOutName, '_3bot .tif']));
    writeMultipageTif(volComb, fullfile(oDir, [fileOutName, '_4color.tif']));
    fprintf('done.\n')

    % Collect the data for the output spreadsheet
    aTableAdd.InputFileName = tfile;
    aTableAdd.OutputFileName = fileOutName;
    aTableAdd.DateAnalyzed = getTodayStr();
    aTableAdd.Settings = mySettings;
    aTableAdd.Threshold = threshold;
    aTableAdd.Num_Top = num_top;
    aTableAdd.Num_Mid = num_mid;
    aTableAdd.Num_Bot = num_bot;
    aTableAdd.Num_Tot = num_top + num_mid + num_bot;

    % Append the data
    aTableNew = vertcat(aTableNew, aTableAdd);
    
end

% Save the new table data
writeNewTable(aTable, aTableNew, oDir, 'lacunarDensityAnalyses-Auto', ...
    maxVers + 1);
