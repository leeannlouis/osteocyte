function out = getMetadata(czi, cfilefull)
% Given a Bio-Formats file (czi) and its full file name (cfilefull), 
% extracts key metadata: image height, image width, number of slices, 
% resolutions in the XY and Z planes, pinhole size, detector zoom, date and 
% time acquired, rotations applied, sample number, region (top or bottom),
% section (1 or 2) and any notes. Outputs these as a cell array (out) in
% the order required by the database. Must have Bio-Formats installed. 

% Get the metadata
metadata = czi{1, 4};

% Get the hash table to retrieve settings for which metadata collection
% functions have not been written
hash = czi{1, 2};

% Get image size and pixel dimensions
width = metadata.getPixelsSizeX(0).getValue();
height = metadata.getPixelsSizeY(0).getValue();
numSlices = metadata.getPixelsSizeZ(0).getValue();
xstep = str2double(metadata.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER));
ystep = str2double(metadata.getPixelsPhysicalSizeY(0).value(ome.units.UNITS.MICROMETER));
zstep = str2double(metadata.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER));

% Get scan settings
pinholeSize = str2double(metadata.getChannelPinholeSize(0, 0).value());
detectorZoom = str2double(metadata.getDetectorZoom(0, 0));

% Extract the timestamp of the scan. Convert the date to a number with
% format 'YYYYMMDD', and time with format 'HHMM' in 24 hr format.
dateTimeAcquired = char(metadata.getImageAcquisitionDate(0));
dateTimeStruct = regexp(dateTimeAcquired, '(?<date>\d+-\d+-\d+)T(?<time>\d+:\d+)', 'names');
dateAcquired = str2double(erase(dateTimeStruct.date, '-')); 
timeAcquired = str2double(erase(dateTimeStruct.time, ':'));

% Extract any rotation data from the hash table
rot = str2double(hash.get(...
    'Global HardwareSetting|ParameterCollection|RoiRotation #1'));

% Extract the name of the data directory
dInfo = regexp(cfilefull, '\\data\\(?<dir>[\w-]+)\\', 'names');
directory = dInfo.dir;

% Extract just the file name
cfile = regexp(cfilefull, '[\w-]+.czi', 'match');

% Extract sample info from the filename, including sample number, region
% (top or bottom), and section (1 or 2)
expression = 'samp(?<sample>\d+)\w_reg(?<reg>\w)_sec(?<sec>\d)';
fInfo = regexp(cfilefull, expression, 'names');
sampNum = str2double(fInfo.sample); 
region = fInfo.reg; 
section = str2double(fInfo.sec);

% Check if a note is present at the end of the file data
nInfo = regexp(cfilefull, 'date\d+_(?<note>\w+).czi$', 'names');
if isempty(nInfo)
    note = '';
else
    note = nInfo.note;
end

% Collect the metadata
out = horzcat({directory}, cfile, sampNum, {region}, section, ...
    dateAcquired, timeAcquired, xstep, zstep, pinholeSize, ...
    detectorZoom, rot, {note});

end 
