function volComb = createOverlay(volume, volOver, transpareny)
% Takes a grayscale volume (volume) and a binary volume (volOver) and 
% outputs a truecolor volume where the binary volume is green. If passed to 
% the sliceViewer function, this shows the grayscale volume with the 
% binary volume as a transparent green overlay to check that the binary 
% volume was created correctly. also takes optional variable transparency 
% that indicates how transparent (0) or opaque (1) the overlay is.

% Check for transparency value
if ~exist('transparency', 'var')
    transparency = 0.55;
end

% If image is in 0-255 format, convert to 0-1 format
if max(volume(:)) > 1
    volume = mat2gray(volume);
end

    volComb = cat(4, volume, volume, volume) + ...
        cat(4, zeros(size(volOver)), volOver*transparency, zeros(size(volOver)));
end
