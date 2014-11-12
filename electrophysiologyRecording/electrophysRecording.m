classdef electrophysRecording < handle
    properties(GetAccess = 'private', SetAccess = 'private')
        ephysTrace
        ephysInterval
        spikeTiming
    end
    
    methods
        function obj = electrophysRecording(xsgFile, spikeFile)
            load(xsgFile, '-mat')
            interval = 1/header.ephys.ephys.sampleRate; % usually 40k Hz.
            obj.ephysTrace = timeseries(data.ephys.trace_1, 'StartTime', interval, 'Interval', interval);
            try
                load(spikeFile)
                obj.spikeTiming = peakTiming;
            end
            obj.ephysInterval = interval;
        end
        
        function et = getEphysTrace(obj)
            et = obj.ephysTrace;
        end
        
        function st = getSpikeTiming(obj)
            st = obj.spikeTiming;
        end
        
    end
end