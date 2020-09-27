%% Osteocyte lacunar counting analysis
% Takes a .tif stack(s) as created by osteocyteLacunarProcessing and finds
% osteocytes (bright labelled cells) in the image. Divides these into top,
% middle, an bottom based on their centroid locations. Stores the numbers
% of osteocytes in each section in the database and three .tif stack
% volumes, which can be passed to createOverlay.m or createOverlayRGB.m to
% create overlays, then to sliceViewer to see where these osteocytes are.

% To try different analysis settings (number of erosions or dilations, size
% or shape of structuring element used), change the variables under the
% heading "ANALYSIS SETTINGS".

% Requires Image Processing Toolbox (shapes, erosions, dilations), and
% sqlite3 + mksqlite for database work

% Note: this currently takes ~2 min per tif stack

% Setup 
clear; clc; close all;

% Get the output data directory
oDir = uigetdir('', 'Where to output images and data?');

% Connect to the osteocyte.db database
[dbfile, dbpath] = uigetfile('\*.db', 'Choose the .db file');
mksqlite('open', fullfile(dbpath, dbfile));

% Get today string for future use
todayStr = getTodayStr();

%%%     ANALYSIS SETTINGS   %%%
se = strel('rectangle', [6 6]); 
numErosions = 4; 
numDilations = 3;
mySettings = 'SeRec6x6Er4Di3';
mySettingsExt = '';

% Select file(s)
[tfiles, tpath] = uigetfile([oDir, '\*.tif'], 'Choose the .tif file(s)', ...
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
    
    % Use the file name to find the resolutions from the database
    resolutions = mksqlite(['SELECT scans.PixelSizeXY_um, ', ...
        'scans.PixelSizeZ_um FROM processing ', ...
        'LEFT JOIN scans ON scans.FileName = processing.InputFileName ', ...
        'WHERE processing.OutputFileName = "', tfile, '"']); 
    xstep = resolutions.PixelSizeXY_um; 
    ystep = resolutions.PixelSizeXY_um;
    zstep = resolutions.PixelSizeZ_um;

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
    
    % Remove objects on edges (42% faster than removing small objects first)
    fprintf('removing edge objects... ');
    volNoEdges = imclearborder(volDilated);
    
    % Get a volume with labeled connected volumes
    fprintf('finding objects... \n');
    CC = bwconncomp(volNoEdges);    % get connected 3D objects
    volObjs = labelmatrix(CC);      % change CC output to 3D
    numObjs = CC.NumObjects;        % get the total objects found

    % Get the volumes of all objects. Note that we could use bwareaopen 
    % to remove small objects, but this assumes isotropic voxel size.
    % In other words, each pixel has the same dimensions in x, y, and z.
    % This is not the case. Insted, we need to calculate the object volumes
    % given the pixel resolutions. Calculating volume in one line (summing 
    % all voxels vs. going slice by slice) gives the same volume to e-12 um
    % and is 44% faster. In the future, could try to use interpn in the 
    % future to resize the volume for isotropic voxel size, then use 
    % bwareaopen.
    objVols = zeros(numObjs, 1);    % vector to store object volumes
    fprintf('calculating object volumes... ');
    for idxObj = 1:numObjs
        
        % Make the volume into 1's so you can sum them to get the volume
        binaryObj = (volObjs == idxObj);
        
        % Volume is now just the sum of the 1's times the resolutions 
        thisVol = sum(binaryObj(:)) * xstep * ystep * zstep;
       
        % Store the volume
        objVols(idxObj) = thisVol;
        
    end

    % Remove objects smaller than 100 um^3.
    fprintf('removing objects smaller than 100 um^3...\n');
    volOcys = volObjs;              % make a copy of the volume
    for idxObj = 1:numObjs
        if objVols(idxObj) < 100
            volOcys(volOcys == idxObj) = 0;
        end
    end

    % Count the objects in the different regions
    fprintf('counting objects... '); 
    [num_top, num_mid, num_bot, L] = getLacunarCounts(volOcys);
    num_tot = num_top + num_mid + num_bot;
    fprintf('done analyzing.\n');

    % Save the volumes as three separate files (1top.tif, 2mid.tif, 3bot.tif), 
    fprintf('Saving all volumes... ')
    [~, fileOutName, ~] = fileparts(tfile);
    fileOutName = [fileOutName, '_analy', todayStr, mySettingsExt];
    fullFileOut = fullfile(oDir, '\output\', fileOutName);
    writeMultipageTif(L == 1, [fullFileOut, '_1top.tif']);
    writeMultipageTif(L == 2, [fullFileOut, '_2mid.tif']);
    writeMultipageTif(L == 3, [fullFileOut, '_3bot .tif']);
    fprintf('done.\n')
    
    % Create and save the multicolor volume
%     fprintf('Creating and saving color volume... ');
%     volComb = createOverlayRGB(volume, L == 1, L == 2, L == 3);
%     writeMultipageTif(volComb, [fullFileOut, '_4color.tif']));
%     fprintf('done.\n');

    % Collect the data to add and get it in the right format for use in a
    % SQL query. That is, TEXT outputs have double quotes around them,
    % numbers are converted to strings for use in the query, and all values
    % are separated by commas
    values_to_add = createSqlValueList({tfile, fileOutName, todayStr, ...
        mySettings, threshold, num_top, num_mid, num_bot, num_tot});
    
    % Add the data to the database
    mksqlite(['INSERT INTO lacunar_counts(InputFileName, OutputFileName, ' ...
        'DateAnalyzed, Settings, Threshold, NumTop, NumMid, NumBot, NumTot) ' ...
        'VALUES (', values_to_add, ')']);

end

% Get a copy of the new lacunar_count datasheet that you appended here
% using a SQL command. It comes out as a structure, convert to a table.
newTable = struct2table(mksqlite('SELECT * FROM lacunar_counts'));
fileNameOut = ['lacunar_counts-', todayStr, '.csv'];
writetable(newTable, fullfile(oDir, fileNameOut));
fprintf(['New file created: ', fileNameOut, '\n']);

% Close the database
mksqlite('close');
