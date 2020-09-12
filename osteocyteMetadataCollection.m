%% Gets metadata from .czi file(s) given by the user
% Take one or more .czi files requested from the user. Checks whether they
% are in the metadata database; if not, adds them and creates a new version
% of the data base.
% Must have Bio-Formats installed. Put it in the toolbox folder and then
% use the pathtool to ensure it is included.
% https://docs.openmicroscopy.org/bio-formats/6.1.0/developers/matlab-dev.html

% Clear
clear; clc;

% Setup
cDir = uigetdir('', 'Where is the code?');
cd(cDir);

% Get the directory containing the metadata
dDir = uigetdir('', 'Where is the metadata stored?');

% Get the latest version of the metadata table
[maxVers, metaFile] = getMaxFileVers(dDir, 'osteocyteMetadata');

% Load the metadata table
metaTable = readtable(fullfile(dDir, metaFile), 'ReadVariableNames', true);
metaTableNew = metaTable;    % New table to store new metadata results

% Get the number for the next new key
if isempty(metaTable.Index)
    newKeyIdx = 1;
else
    newKeyIdx = max(metaTable.Index) + 1;
end

% Get the .czi file(s) to analyze
[cfiles, path] = uigetfile(['C:\Users\Leeann\OneDrive - CUNY\' ...
    'project_osteocyte\data\*.czi'], 'Choose the .czi file(s)', ...
    'Multiselect', 'on');

% If only one file selected, make it a cell so that the rest of the code 
% runs correctly
if ~iscell(cfiles)
    cfiles = {cfiles};
end

% Cycle through all files selected
for cidx = 1:size(cfiles, 2)
    
    % Get the current file
    cfile = cfiles{cidx};
    
    % Check whether the file is already in the metadata table
    if ~any(strcmpi(cfile, metaTable.('FileName')))

        % If no data exists, try to open the file
        try
            
            % Try to open. Use evalc to suppress text output of bfopen
            fprintf('Trying to open %s... ', cfile)
            [~, data] = evalc('bfopen([path, cfile])');
            fprintf('opened.\n')

            % Try to get the metadata
            try
                fprintf('Collecting metadata for %s... ', cfile)
                newData = getMetadata(data, [path, cfile]);
                fprintf('collected.\n\n', cfile)
            
                % Fix the key index
                newData{1} = newKeyIdx;
                newKeyIdx = newKeyIdx + 1;

                % Append table with metadata
                metaTableNew = vertcat(metaTableNew, newData);
                
            catch
                fprintf(' not in the proper file name format. Skipped.\n\n', cfile)
            end

        catch
            fprintf(' not a BioFormats file. Skipped.\n\n', cfile)
        end

    else
        % If data already exists, skip the file
        fprintf('Data for %s already exists. Did not collect metadata.\n', cfile);

    end
    
end

% If you got data, add it and create a new excel file.
if size(metaTableNew, 1) ~= size(metaTable, 1)

    % Get the new version number. Add a 0 in front of it if needed.
    newVers = maxVers + 1;
    versName = num2str(newVers, '%02.f');
    
    % Get the date in the proper format
    t = today('datetime');
    t.Format = 'yyyyMMdd';
    t = char(t);
    
    % Get the full file name
    fileout = ['osteocyteMetadata-v', versName, '-', t, '.xls'];

    % Write the file
    writetable(metaTableNew, fullfile(dDir, fileout));

    fprintf(['New file created for new results: ', fileout, '\n']);
    
else
    
    fprintf('No new data, no file saved.\n');
    
end