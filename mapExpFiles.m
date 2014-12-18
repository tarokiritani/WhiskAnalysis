function M = mapExpFiles(files)
M = containers.Map;
files = textscan(files, '%s', 'delimiter', ';');
files = files{1};

fileVarPair = {'xsgFile', 'data';
               'spikeFile', 'spikeTs';
               'whiskFile', 'whiskTs';
               'cInjectionFile', 'signal';
               'activeTouchFile', 'onOffTiming'};
for n = 1:size(fileVarPair, 1)
    M(fileVarPair{n, 1}) = '';
    for m = 1:numel(files)
        if sum(strcmp(fileVarPair{n, 2}, who('-file', files{m})))
            M(fileVarPair{n, 1}) = files{m};
            break
        end 
    end
end