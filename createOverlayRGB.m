function volComb = createOverlayRGB(volume, volOverR, volOverG, ...
    volOverB, darken, trans)
% Takes a grayscale volume (volume) and a binary volume (volOver) and
% outputs a truecolor volume (colors are in the 4th dimension), where the
% binary volume is in green. Can also take an optional transparency value,
% that determines how transparent (0) or opaque (1) the green is.

% Check for darken value
if ~exist('darken', 'var')
    darken = 0.75;
end

% Check for transparency value
if ~exist('trans', 'var')
    trans = 0.55;
end

% If image is in 0-255 format, convert to 0-1 format
if max(volume(:)) > 1
    volume = mat2gray(volume);
end

% Create the RGB volume
volComb = cat(4, volume * darken, volume * darken, volume * darken) + ...
    cat(4, volOverR * trans, volOverG * trans, volOverB * trans);
end
