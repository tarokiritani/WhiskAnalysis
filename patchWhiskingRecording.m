classdef patchWhiskingRecording < patchRecording
    properties(GetAccess = 'private', SetAccess = 'private')
        whiskTrace
    end
    
    methods
        function obj = patchWhiskingRecording(files)
            filesToLoad = textscan(files, '%s', 'delimiter', ';');
            filesToLoad = filesToLoad{1};
            for k = 1:length(filesToLoad)
                if~(strfind(filesToLoad{k}, 'xsg'))
                    if~(strfind(filesToLoad{k}, 'pike'))
                        whiskFile = filesToLoad{k};
                    end
                end
            end
            obj@patchRecording(files);
            load(whiskFile)
            obj.whiskTrace = whiskTs;
        end
        
        function wt = getWhiskTrace(obj)
            wt = obj.whiskTrace;
        end
        
        function Snippets = getSnippets(obj)
            [WhiskPeriods, QuietPeriods] = classifyWhiskState(obj.whiskTrace, 'longWhiskingTime', true);
           
            Snippets.onsetSnippetsWhisker = arrayfun(@(k) whiskTs.resample(WhiskPeriods(k, 1) - traceWindow:cameraInterval:WhiskPeriods(k, 1) + traceWindow), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);
            Snippets.onsetSnippetsEphys = arrayfun(@(k) ephysTrace.resample(WhiskPeriods(k, 1) - traceWindow:ephysInterval:WhiskPeriods(k, 1) + traceWindow), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);
            onsetSnippetsSpike = arrayfun(@(k) intersect(peakTiming(peakTiming > (WhiskPeriods(k, 1) - traceWindow)), peakTiming(peakTiming < (WhiskPeriods(k, 1) + traceWindow))), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);  % with Ts     onsetSnippetsSpike{k} = squeeze(spikeTs.resample(WhiskPeriods(k, 1) - traceWindow:ephysInterval:WhiskPeriods(k, 1) + traceWindow).Data); with mat    onsetSnippetsSpike{k} = spikeVec(round((WhiskPeriods(k, 1) - traceWindow) / ephysInterval):round((WhiskPeriods(k, 1) + traceWindow) / ephysInterval));
            Snippets.onsetSnippetsSpike = arrayfun(@(k) onsetSnippetsSpike{k} - WhiskPeriods(k, 1), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);
            Snippets.whiskSnippetsWhisker = arrayfun(@(k) whiskTs.resample(WhiskPeriods(k, 1):cameraInterval:WhiskPeriods(k, 2)), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);
            Snippets.whiskSnippetsEphys = arrayfun(@(k) ephysTrace.resample(WhiskPeriods(k, 1):ephysInterval:WhiskPeriods(k, 2)), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);     
            Snippets.whiskSnippetsSpike = arrayfun(@(k) intersect(peakTiming(peakTiming > WhiskPeriods(k, 1)), peakTiming(peakTiming < WhiskPeriods(k, 2))), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);
            Snippets.quietSnippetsWhisker = arrayfun(@(k) whiskTs.resample(QuietPeriods(k,1):cameraInterval:QuietPeriods(k,2)), [1:size(QuietPeriods, 1)], 'UniformOutput', 0);
            Snippets.quietSnippetsEphys = arrayfun(@(k) ephysTrace.resample(QuietPeriods(k,1):ephysInterval:QuietPeriods(k,2)), [1:size(QuietPeriods, 1)], 'UniformOutput', 0);
            Snippets.quietSnippetsSpike = arrayfun(@(k) intersect(peakTiming(peakTiming > QuietPeriods(k, 1)), peakTiming(peakTiming < QuietPeriods(k, 2))), [1:size(QuietPeriods, 1)], 'UniformOutput', 0);

            Snippets.whiskSnippetsWhisker = Snippets.whiskSnippetsWhisker(~cellfun('isempty', Snippets.whiskSnippetsWhisker));
            Snippets.whiskSnippetsEphys = Snippets.whiskSnippetsEphys(~cellfun('isempty', Snippets.whiskSnippetsEphys));
            Snippets.quietSnippetsWhisker = Snippets.quietSnippetsWhisker(~cellfun('isempty', Snippets.quietSnippetsWhisker));
            Snippets.quietSnippetsEphys = Snippets.quietSnippetsEphys(~cellfun('isempty', Snippets.quietSnippetsEphys));

            Snippets.spikeSnippets = spikeSnippets;

            Snippets.ephysSampleRate = header.ephys.ephys.sampleRate;
            Snippets.cameraInterval = cameraInterval;
            Snippets.ephysTrace{1} = ephysTrace;
            Snippets.whiskTrace{1} = whiskTs;
            Snippets.WhiskPeriods{1} = WhiskPeriods;
            Snippets.QuietPeriods{1} = QuietPeriods;
        end
    end
end