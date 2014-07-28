function detectSpikes(threshold, varargin)
p = inputParser;
defaultWindow = 0.008; % in second this has to be small. otherwise busrty spikes cannot be separated.
p.addOptional('spikeWindow', defaultWindow, @isnumeric);
parse(p,varargin{:});

[fileName, pathName,filterIndex] = uigetfile('C:\Users\kiritani\Documents\data\cells\*.xsg', 'choose an .xsg file');
load(fullfile(pathName, fileName), '-mat');

ephysSampleRate = header.ephys.ephys.sampleRate;

ephysTrace = timeseries(data.ephys.trace_1, 'StartTime', 1/ephysSampleRate, 'Interval', 1/ephysSampleRate);
if isscalar(threshold)
    spikes = data.ephys.trace_1 > threshold;
elseif isvector(threshold)
    spikes = (data.ephys.trace_1 - threshold) > 0;
end
    
crossingPoints = find(diff(spikes) == 1);
crossingPoints = ephysTrace.Time(crossingPoints);
peakTiming = zeros(1, length(crossingPoints));
spikeSnippets = cell(length(crossingPoints), 1);

spikeWindow = p.Results.spikeWindow;

for k = 1:length(crossingPoints)
        % first align to the threshold. then find the peak and align to it.
        spikeSnippets{k} = ephysTrace.resample(crossingPoints(k):1/ephysSampleRate:crossingPoints(k) + spikeWindow);
        spikeDownIndex = find(spikeSnippets{k}.Data < (spikeSnippets{k}.Data(1) - 1), 1, 'first');
        if ~isempty(spikeDownIndex)
            [m, i] = max(spikeSnippets{k}.Data(1:spikeDownIndex));
            peakTiming(k) = spikeSnippets{k}.Time(i);
            if peakTiming(k) - spikeWindow > 0 && peakTiming(k) + spikeWindow < ephysTrace.TimeInfo.End
                spikeSnippets{k} = ephysTrace.resample(peakTiming(k) - spikeWindow:1/ephysSampleRate:peakTiming(k)+ spikeWindow);
            else
                spikeSnippets{k} = [];
            end
        else
            spikeSnippets{k} = [];
        end
end

peakTiming = peakTiming(peakTiming ~= 0);
spikeSnippets = spikeSnippets(~cellfun('isempty',spikeSnippets));
spikeVec = sparse(ones(1, length(peakTiming)), round(ephysSampleRate * peakTiming), ones(1, length(peakTiming)), 1, length(data.ephys.trace_1));
spikeVec = full(spikeVec);
spikeTs = timeseries(spikeVec, 'StartTime', 1/ephysSampleRate, 'Interval', 1/ephysSampleRate);
uisave({'threshold', 'peakTiming', 'spikeSnippets', 'spikeTs', 'spikeVec'}, fullfile(pathName, [fileName, 'spike']));