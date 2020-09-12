function writeNewTable(oldTable, newTable, thisDir, thisFileName, thisVersNum)
% Takes the old table (oldTable) and new table (newTable) and compares
% their row number. If different, outputs a new table in the given
% directory (thisDir) with the filename given by thisFileName plus the
% version number given by thisVersNum, and the date (ex:
% thisFileName-v01-20200910.xls).

% Get the date in the proper format
todayStr = getTodayStr();

if size(oldTable, 1) ~= size(newTable, 1)
    
    % Get the new version number. Add a 0 in front of it if needed.
    versName = num2str(thisVersNum, '%02.f');
    
    % Get the full file name
    fileNameOut = [thisFileName, '-v', versName, '-', todayStr, '.xls'];

    % Write the file
    writetable(newTable, fullfile(thisDir, fileNameOut));
    fprintf(['New file created: ', fileNameOut, '\n']);
    
else
    
    fprintf('No new data, no file saved.\n');
    
end

end
