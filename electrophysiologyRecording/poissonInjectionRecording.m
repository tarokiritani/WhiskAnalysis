classdef poissonInjectionRecording < patchWhiskingRecording
    properties(GetAccess = 'private', SetAccess = 'private')
        currentInjection
    end
    
    methods
        function obj = poissonInjectionRecording(files)
            obj@patchWhiskingRecording(files)
            filesToLoad = textscan(files, '%s', 'delimiter', ';');
            filesToLoad = filesToLoad{1};
            for k = 1:length(filesToLoad)
                if(strfind(filesToLoad{k}, 'xsg'))
                    xsgFile = filesToLoad{k}; 
                elseif(strfind(filesToLoad{k}, 'signal'))
                    load(filesToLoad{k});
                end
            end
            load(xsgFile)
            s = get(signal,'signal');
            ephysInterval = 1/header.ephys.ephys.sampleRate; % usually 40k Hz.
            obj.currentInjection = timeseries(s, 'StartTime', ephysInterval, 'Interval', ephysInterval);
        end
        
        function ci = getCurrentInjection(obj)
            ci = currentInjection;
        end
        
        function onsets = getOnsetTiming(obj)
            currentDeriv = diff(obj.curentInjection.Data);
            onsets = find(CurrentDeriv > 0);
            onsets = obj.currentInjection.Time(onsets);
        end
        
        function offsets = getOffsetTiming(obj)
            currentDeriv = diff(obj.curentInjection.Data);
            offsets = find(CurrentDeriv < 0);
            offsets = obj.currentInjection.Time(offsets);
        end
        
        function onsetSnippets = getOnsetSnippets(obj)
            onsets = obj.getOnsetTiming;
            onsetSnippets = arrayfun(@(x) obj.whiskTrace.resample(onsets(x)-1:obj.whiskTrace.TimeInfo.Incement:onsets(x)+1), onsets, 'UniformOutput', 'false');
        end
        
        function offsetSnippets = getOffsetSnippets(obj)
            offsets = obj.getOffsetTiming;
            offsetSnippets = arrayfun(@(x) obj.whiskTrace.resample(offsets(x)-1:obj.whiskTrace.TimeInfo.Incement:offsets(x)+1), offsets, 'UniformOutput', 'false');
        end
    end

end
