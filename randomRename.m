function randomRename()
% Asks user for an input directory of files, and an output directory. Makes
% a copy of all files and randomly renames them with a number from 1 to n,
% where n is the number of files. Also outputs a table of the old and new
% filenames. Assumes that the last 4 digits of all file names are the
% extension. 

% Get the directory to pull all the files from (dirIn) and the directory to
% output the name files in a randomly numbered list.
dirIn = uigetdir('', 'Directory in?');
dirOut = uigetdir('', 'Directory out?');

% Fetch all the files in the directory. Then, make take just the file names
% out of the directory structure as a cell array. Finally, convert that
% horizontal cell array to a vertical / stacked string array.
directoryInfo = dir(dirIn);
fileListFull = {directoryInfo(:).name};
fileListStack = string(fileListFull)';

% Only keep the files, not the directories. This includes the current
% directory ('.') and the parent directory ('..'), both of which are added
% to any MATLAB call to dir. We can do this by extracting the 'isdir'
% information from the directory structure. 
fileListDirs = [directoryInfo(:).isdir];    % Boolean info
fileList = fileListStack(~fileListDirs);    % Final list of file names

% Create a randomly ordered list of numbers from 1 to n, where n is the
% number of files. Transpose it to make it a stacked, row-wise list to make
% things easier later using the ' command.
numFiles = length(fileList);
randomListRaw = datasample(1:numFiles, numFiles, 'Replace', false)';

% Convert these numbers to strings for file names
randomListStr = string(randomListRaw);

% Pad the front of the number strings with 0's based on the number that has
% the most digits. Ex: if the largest number 101, ensure all strings are 
% padded up to 3 characters. 
charsToPad = max(strlength(randomListStr));
randomListPad = pad(randomListStr, charsToPad, 'left', '0');

% Copy the files from dirIn to dirOut, using the new random number names
% and keeping the original extension.
for idxFile = 1:numFiles
     
    % Get the original file name and its full file name with directory.
    % Need to convert to a character to do the indexing in a later step.
    thisFileName = char(fileList(idxFile));
    inputFullFileName = fullfile(dirIn, thisFileName); 
    
    % Create the new file name using the random number and the original
    % file extension. Assumes last 4 characters are the extension. 
    outputBaseFileName = strcat(randomListPad(idxFile), ...
        thisFileName((end-3):end)); 
    
    % Create the full file name.
    outputFullFileName = fullfile(dirOut, outputBaseFileName); 
    
    % Copy the file
    copyfile(inputFullFileName, outputFullFileName); 
         
end

% Finally, output a reference table that shows the relationships between
% the old and new filenames.
translationList = [fileList, randomListPad];
translationFileName = fullfile(dirOut, 'translation_file.txt');
writematrix(translationList, translationFileName);

end

