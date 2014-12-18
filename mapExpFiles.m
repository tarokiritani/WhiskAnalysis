function M = mapExpFiles(files)
M = containers.Map;
files = textscan(files, '%s', 'delimiter', ';');
files = files{1};
for m = 1:numel(files)
    if sum(strcmp('data', who('-file', files{m})))
        M('xsgFile') = files{m};
    elseif sum(strcmp('spikeTs', who('-file', files{m})))
        M('spikeFile') = files{m};
    elseif sum(strcmp('whiskTs', who('-file', files{m})))
        M('whiskFile') = files{m};
    elseif sum(strcmp('onOffTiming', who('-file', files{m})))
        M('activeTouchFile') = files{m};
    elseif sum(strcmp('signal', who('-file', files{m})))
        M('cInjectionFile') = files{m};
    end
end