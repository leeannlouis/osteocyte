# osteocyte
functions and scripts for analysis of image data of bone cells

volComb = createOverlay(volume, volOver) takes a grayscale volume 
(volume) and a binary volume (volOver) and outputs a truecolor 
volume where the binary volume is green. if sent to sliceViewer, this 
shows the grayscale volume with the binary volume as a transparent 
green overlay to check that the binary volume was created correctly

randomRename() asks the user for an input directory and an output 
directory. it then generates a random permutation of the vector of 
numbers from 1 to n, where n is the number of files. it then copies 
the files from the old directory to the new directory while naming 
them with the random number, padded with zeros in the front. it also
creates a file 'translation.txt' in the output directory that lists 
the old file names with the number they were assigned in the output
directory.
