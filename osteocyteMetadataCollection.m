%% Gets metadata from .czi file(s) given by the user
% Take one or more .czi files requested from the user. Checks whether they
% are in the metadata database; if not, adds them and creates a new version
% of the data base.

% Must have Bio-Formats MATLAB Toolbox installed. Download bfmatlab.zip
% from the page below and add to the toolbox using the pathtool
% https://www.openmicroscopy.org/bio-formats/downloads/

% Clear
clear; clc;

% Get the directory containing the metadata
dDir = uigetdir('', 'Where to output metadata file copy?');

% Connect to the osteocyte.db database
[dbfile, dbpath] = uigetfile('\*.db', 'Choose the .db file');
mksqlite('open', fullfile(dbpath, dbfile));

% Get today string for future use
todayStr = getTodayStr();

% Get the .czi file(s) to analyze
[cfiles, cpath] = uigetfile('', 'Choose the .czi file(s)', ...
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
    priorData = mksqlite(['SELECT * FROM scans WHERE FileName = "', cfile, '"']);
    redo = 'NA';
    if ~isempty(priorData)
        
        % Ask user if they want to redo the processing
        redo = input(['Data already exists for ', cfile, '. Redo? Y/N '], 's');
        while ~ismember(redo, {'Y', 'N', 'y', 'n'})
            redo = input('Invalid entry, try again. ', 's');
        end
        
    end
    
    % If yes, continue and delete the old record
    if ~ismember(redo, {'Y', 'y', 'NA'})
        fprintf(['Skipping ', cfile, '.\n'])
        continue
    else
        mksqlite(['DELETE FROM scans WHERE FileName = "', cfile, '"']);
    end
    
    % Try to open the file
    try

        % Try to open. Use evalc to suppress text output of bfopen
        fprintf('Trying to open %s... ', cfile)
        [~, data] = evalc('bfopen([cpath, cfile])');
        fprintf('opened.\n')

        % Try to get the metadata
        try
            fprintf('Collecting metadata for %s... ', cfile)
            newData = getMetadata(data, [cpath, cfile]);
            fprintf('collected.\n\n', cfile)

            % Add the data to the database
            values_to_add = createSqlValueList(newData);
            mksqlite(['INSERT INTO scans(DataDirectory, FileName, ', ...
                'SampleID, Region, Section, DateAcquired, TimeAcquired, ', ...
                'PixelSizeXY_um, PixelSizeZ_um, PinholeSize_um, ', ...
                'ScanZoom, ScanRotation, Note) VALUES (', values_to_add, ')']);

        catch
            fprintf(' not in the proper file name format. Skipped.\n\n', cfile)
        end

    catch
        fprintf(' not a BioFormats file. Skipped.\n\n', cfile)
    end
    
end

% Get a copy of the metadata datasheet using a SQL command. It comes out 
% as a structure, convert to a table.
newTable = struct2table(mksqlite('SELECT * FROM scans'));
fileNameOut = ['scans-', todayStr, '.csv'];
writetable(newTable, fullfile(dDir, fileNameOut));
fprintf(['New file created: ', fileNameOut, '\n']);

% Close the database
mksqlite('close');
