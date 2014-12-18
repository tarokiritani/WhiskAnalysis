classdef patchRecording < electrophysRecording
    
    methods
        function obj = patchRecording(xsgFile, spikeFile)
            obj@electrophysRecording(xsgFile, spikeFile);           
        end
    end
    
end
