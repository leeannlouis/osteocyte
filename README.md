# osteocyte
functions and scripts for analysis of image data of bone cells

volComb = createOverlay(volume, volOver, transparency) takes a grayscale 
volume (volume) and a binary volume (volOver) and outputs a truecolor 
volume where the binary volume is green. if sent to sliceViewer, this 
shows the grayscale volume with the binary volume as a transparent 
green overlay to check that the binary volume was created correctly. 
also takes optional variable transparency that indicates how 
transparent (0) or opaque (1) the overlay is.

[x1, x2, y1, y2] = getCropXY(volume, figHandle)
Given an input volume, ask the user for the cropping region by looking at
the top and bottom slices. Ouputs the x and y coordinates of the cropping
region. Optional input for figure handle. 

[z1, z2] = getCropZ(volume, figHandle)
Given an input volume, ask the user whether the number of slices should
be cropped by allowing the user to look at the stack of slices. Ouputs 
the start and end slice numbers of the cropping region. Optional input 
for figure handle. 

[maxVers, theFileName] = getMaxFileVers(theDir, nameFormat)
Given a directory the format of the file name of interest, gets the 
maximum version number. Assumes version is in the format "_v\d+_"
in the file name. Outpus the version number and the full file name.

out = getMetadata(czi, cfilefull)
Given an open Bio-Format file, outputs key metadata in the order and 
format required by the database. Must have Bio-Formats installed. 

rotation = getRotation(image, figHandle)
Given an image, display it and ask the user whether rotation is needed,
and how much, until the user is satisfied with the figure. Optional
arguement figureHandle allows control over figure output.

osteocyteMetadataCollection takes one or more .czi files requested from the 
user. Checks whether they are in the metadata database; if not, adds them 
and creates a new version of the data base.
Must have Bio-Formats installed. Put it in the toolbox folder and then
use the pathtool to ensure it is included.
https://docs.openmicroscopy.org/bio-formats/6.1.0/developers/matlab-dev.html

randomRename() asks the user for an input directory and an output 
directory. it then generates a random permutation of the vector of 
numbers from 1 to n, where n is the number of files. it then copies 
the files from the old directory to the new directory while naming 
them with the random number, padded with zeros in the front. it also
creates a file 'translation.txt' in the output directory that lists 
the old file names with the number they were assigned in the output
directory.
