classdef poissonInjectionRecording < patchWhiskingRecording
    properties(GetAccess = 'private', SetAccess = 'private')
        currentInjection
    end
    
    methods
        function obj = poissonInjectionRecording(xsgFile, spikeFile, whiskFile, cInjectionFile)
            obj@patchWhiskingRecording(xsgFile, spikeFile, whiskFile)
            load(xsgFile, '-mat')
            load(cInjectionFile, '-mat')
            s = get(signal,'signal');
            ephysInterval = 1/header.ephys.ephys.sampleRate; % usually 40k Hz.
            obj.currentInjection = timeseries(s, 'StartTime', ephysInterval, 'Interval', ephysInterval);
        end
        
        function ci = getCurrentInjection(obj)
            ci = obj.currentInjection;
        end
        
        function onsets = getOnsetTiming(obj)
            currentDeriv = diff(obj.currentInjection.Data);
            onsets = find(currentDeriv > 0);
            onsets = obj.currentInjection.Time(onsets);
        end
        
        function offsets = getOffsetTiming(obj)
            currentDeriv = diff(obj.currentInjection.Data);
            offsets = find(currentDeriv < 0);
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
