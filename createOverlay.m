function volComb = createOverlay(volume, volOver)
% Takes a grayscale volume (volume) and a binary volume (volOver) and
% outputs a truecolor volume (colors are in the 4th dimension), where the
% binary volume is in green. 
    volComb = cat(4, volume, volume, volume) + ...
        cat(4, zeros(size(volOver)), volOver*0.25, zeros(size(volOver)));
end