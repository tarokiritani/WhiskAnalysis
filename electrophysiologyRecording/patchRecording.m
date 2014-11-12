classdef patchRecording < electrophysRecording
    
    methods
        function obj = patchRecording(files)
            filesToLoad = textscan(files, '%s', 'delimiter', ';');
            filesToLoad = filesToLoad{1};
            spikeFile = '';
            for k = 1:length(filesToLoad)
                if(strfind(filesToLoad{k}, 'xsg'))
                    xsgFile = filesToLoad{k};
                elseif(strfind(filesToLoad{k}, 'pike'))
                    spikeFile = filesToLoad{k};
                end
            end
            obj@electrophysRecording(xsgFile, spikeFile);
            
        end
        
        
        
    end
    
end
