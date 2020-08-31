function volComb = createOverlay(volume, volOver, transpareny)
% Takes a grayscale volume (volume) and a binary volume (volOver) and
% outputs a truecolor volume (colors are in the 4th dimension), where the
% binary volume is in green. Can also take an optional transparency value,
% that determines how transparent (0) or opaque (1) the green is.

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
