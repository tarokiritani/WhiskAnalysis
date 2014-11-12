classdef negInjectionRecording < patchWhiskingRecording
    
    methods
        function obj = negInjectionRecording(files)
            obj@patchWhiskingRecording(files);
        end
        
        function ts = getAverageTrace(obj)
            et = obj.getEphysTrace;
            snippets = arrayfun(@(x) et.resample(x:et.TimeInfo.Increment:x+0.5).Data, [0 1 2 3],'UniformOutput', 0)
            
        end
        
        function [inputR, tau] = calcParameters(obj)
            ts = obj.getAverageTrace;
            baselineVm = ts.resample(0:ts.TimeInfo.Increment:0.1);
            baselineVm = mean(baselineVm);
            afterVm = ts.resample(0.3:ts.TimeInfo.Increment:0.6);
            inputR = afterVm-baselineVm / -100; % inject -100pA
            transient = ts.resample(0.101:ts.TimeInfo.Increment:0.2);
            
        end
        
        
        
    end
end