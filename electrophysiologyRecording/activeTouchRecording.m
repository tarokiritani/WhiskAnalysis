classdef activeTouchRecording < patchWhiskingRecording
    properties(GetAccess = 'private', SetAccess = 'private')
        onOffTiming
    end
    
    methods
        function obj = activeTouchRecording(xsgFile, spikeFile, whiskFile, activeTouchFile)
            obj@patchWhiskingRecording(xsgFile, spikeFile, whiskFile)
            load(files)
            obj.onOffTiming = onOffTiming;
        end
        
        function to =GetOnsets(obj)
            onOff = obj.onOffTiming;
            onsets = onOff(:,1);
            interval = obj.ephysTrace.TimeInfo.Increment;
            to = arrayfun(@(x) obj.ephysTrace.resample(x-1:interval:x+1), onsets, 'uniformOutput', False);
        end
        
        function to = offsets(obj)
            onOff = obj.onOffTiming;
            offsets = onOff(:,2);
            interval = obj.ephysTrace.TimeInfo.Increment;
            to = arrayfun(@(x) obj.ephysTrace.resample(x-1:interval:x+1), offsets, 'uniformOutput', False);
        end
        
    end
end