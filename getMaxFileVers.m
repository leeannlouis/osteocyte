function [maxVers, theFileName] = getMaxFileVers(theDir, nameFormat)
% Given a directory the format of the file name of interest, gets the 
% maximum version number. Assumes version is in the format "v\d+" in the 
% file name. Outpus the version number and the full file name.

% Get the listing of files with the name format
theListing = dir(theDir);
theFilesRaw = {theListing.name};
theFiles = theFilesRaw(contains(theFilesRaw, nameFormat));

% Get the version number of each file
fileVersions = zeros(1, length(theFiles));
for fileNum = 1:length(theFiles)
    versInfo = regexp(theFiles{fileNum}, 'v(\d+)-\d+', 'tokens');
    thisVers = str2double(versInfo{1});
    fileVersions(1, fileNum) = thisVers;
end

% Get the max version number and the associated file
[maxVers, maxIdx] = max(fileVersions);
theFileName = theFiles{maxIdx};

end
