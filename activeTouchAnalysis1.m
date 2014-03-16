function result = activeTouchAnalysis(varargin)
strain = 'PV-Cre/ROSA-Cre-tdTomato'; % PV-Cre/ROSA-Cre-tdTomato, B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato, VIP-ires-Cre/ROSA-CreR-tdTomato, SOM-ires-Cre/ROSA-CreR-tdTomato
mksqlite('open', 'C:\Users\kiritani\Documents\data\GitHub\experiments\db\development.sqlite3');
query = ['SELECT * FROM analyses INNER JOIN cells ON analyses.cell_id = cells.id INNER JOIN mice ON cells.mouse_id = mice.id INNER JOIN users ON users.id = mice.user_id WHERE species_strain = "', strain, '" AND analysis_type = "active touch" AND email = "taro.kiritani@epfl.ch"'];
queryResult = mksqlite(query);
mksqlite('close');

c = clock;
if strcmp(strain, 'PV-Cre/ROSA-Cre-tdTomato')
    cellType = 'PV';
elseif strcmp(strain, 'B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato')
    cellType = 'ETV';
elseif strcmp(strain, 'VIP-ires-Cre/ROSA-CreR-tdTomato')
    cellType = 'VIP';
elseif strcmp(strain, 'SOM-ires-Cre/ROSA-CreR-tdTomato')
    cellType = 'SOM';
end
dirName = ['C:\Users\kiritani\Documents\data\analysis\activeTouch\', cellType, date, '-',num2str(c(4)), num2str(c(5))];
mkdir(dirName);

%% whisk onset group analysis
neurons = containers.Map();
traceWindow = 1;
for n = 1:length(queryResult)
    [onsetSnippetsWhisker, whiskTimeVec, onsetSnippetsEphys, ephysTimeVec, onsetSnippetsSpike, onsets] = activeTouchOnset(queryResult(n), traceWindow);
    neuron.onsetSnippetsWhisker = onsetSnippetsWhisker;
    neuron.whiskTimeVec = whiskTimeVec;
    neuron.onsetSnippetsEphys = onsetSnippetsEphys;
    neuron.ephysTimeVec = ephysTimeVec;
    neuron.onsetSnippetsSpike = onsetSnippetsSpike;
    neuron.onsets = onsets;
    neuron.expNum = queryResult(n).experiment_number;
    if neurons.isKey(int2str(queryResult(n).cell_id))
        neurons(int2str(queryResult(n).cell_id)) = combineTwoNeuronStructures(neuron, neurons(int2str(queryResult(n).cell_id)));
    else
        neurons(int2str(queryResult(n).cell_id)) = neuron;
    end
end

keys = neurons.keys;
for k = 1:length(keys)
    neuron = neurons(keys{k});
    figure;
    subplot(221)
    plot(ephysTimeVec - traceWindow, (neuron.onsetSnippetsEphys)', 'b');
    hold on
    plot(ephysTimeVec - traceWindow, nanmean(neuron.onsetSnippetsEphys, 2), 'LineWidth', 5, 'Color', 'r');
    title(['cell ', neuron.expNum]) 
    xlim([-traceWindow traceWindow])
    xlabel('sec')
    ylabel('mV')
    subplot(222)
    plot(whiskTimeVec - traceWindow, (neuron.onsetSnippetsWhisker)', 'b');
    hold on
    plot(whiskTimeVec - traceWindow, nanmean(neuron.onsetSnippetsWhisker, 2), 'LineWidth', 5, 'Color', 'r');
    xlim([-traceWindow traceWindow])
    xlabel('sec')
    ylabel('deg')
    subplot(223)
    histVec = [];
    for n = 1:length(neuron.onsetSnippetsSpike)
        for m = 1:length(neuron.onsetSnippetsSpike{n})
            line([neuron.onsetSnippetsSpike{n}(m), neuron.onsetSnippetsSpike{n}(m)], [n-1 n]);
        end
        histVec = [histVec, neuron.onsetSnippetsSpike{n}];
    end
    xlim([-traceWindow traceWindow])
    xlabel('sec')
    ylabel('trials')
    spRate = histc(histVec,[-1 0 1]) / n; % firing rates -1 to 0 sec and 0 to 1 sec.
    subplot(224);
    bar(spRate(1:2))
    set(gca, 'xticklabel',{'quiet','whisk'});
    ylabel('freq (Hz)')
    
    figFileName = ['cell_id', keys{k}];
    hgsave([dirName, filesep, figFileName])
end

p = mfilename('fullpath');
dos(['copy ', p, '.m ', dirName, filesep, 'freeWhiskAnalysis.m']);

end


%%
function Snippets = activeTouchOnset(sqlRecord, traceWindow)

% load .mat files
filesToLoad = textscan(sqlRecord.file, '%s', 'delimiter', ';');
filesToLoad = filesToLoad{1};
for k = 1:length(filesToLoad)
    load(filesToLoad{k}, '-mat');
end

ephysInterval = 1/header.ephys.ephys.sampleRate; % usually 40k Hz.
% cameraInterval = whiskTs.TimeInfo.Increment; % usually 500 Hz.

ephysTrace = timeseries(data.ephys.trace_1, 'StartTime', ephysInterval, 'Interval', ephysInterval);
% whiskMove = classifyWhiskState(whiskTs);

onsets = diff(onOffTiming) == 1;
onsets = onOffTimingTs.Time(onsets); % this should read whiskMove.Time(find(onsets))??
offsets = diff(onOffTiming) == -1;
offsets = onOffTimingTs.Time(offsets);

Snippets.onsetSnippetsEphys = arrayfun(@(k) squeeze(ephysTrace.resample(onsets(k) - traceWindow:ephysInterval:onsets(k, 1) + traceWindow).Data), [1:length(onsets)], 'UniformOutput', 0);
onsetSnippetsSpike = arrayfun(@(k) intersect(peakTiming(peakTiming > (WhiskPeriods(k, 1) - traceWindow)), peakTiming(peakTiming < (WhiskPeriods(k, 1) + traceWindow))), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);  % with Ts     onsetSnippetsSpike{k} = squeeze(spikeTs.resample(WhiskPeriods(k, 1) - traceWindow:ephysInterval:WhiskPeriods(k, 1) + traceWindow).Data); with mat    onsetSnippetsSpike{k} = spikeVec(round((WhiskPeriods(k, 1) - traceWindow) / ephysInterval):round((WhiskPeriods(k, 1) + traceWindow) / ephysInterval));
Snippets.onsetSnippetsSpike = arrayfun(@(k) onsetSnippetsSpike{k} - WhiskPeriods(k, 1), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);

onsetSnippetsWhisker = cell2mat(onsetSnippetsWhisker);
onsetSnippetsEphys = cell2mat(onsetSnippetsEphys);
% onsetSnippetsSpike = cell2mat(onsetSnippetsSpike);
whiskTimeVec = cameraInterval * [1:size(onsetSnippetsWhisker, 1)];
ephysTimeVec = ephysInterval * [1:size(onsetSnippetsEphys, 1)];

end

function spikePhaseAnalysis
    
    %do this only during the whisking periods.
    h = hilbert(angleArray-mean(angleArray));
    phase = zeros(1, length(h));
    for k = 1:length(h)
        phase(k) = atan(arctan(imag(h(k))/real(h(k))));
    end
    
    % to do: plot the whisk position and spikes aligned.
    for k = 1:length(spikeTimings)
        whiskTrace.resample(spikeTimings(k)-0.1:0.002:spikeTimings(k)+ 1);
    end
    
end

function cs = combineTwoNeuronStructures(s1, s2)
    s1.onsetSnippetsWhisker = [s1.onsetSnippetsWhisker, s2.onsetSnippetsWhisker];
    s1.onsetSnippetsEphys = [s1.onsetSnippetsEphys, s2.onsetSnippetsEphys];
    s1.onsetSnippetsSpike = [s1.onsetSnippetsSpike, s2.onsetSnippetsSpike];
    s1.onsets = [s1.onsets; s2.onsets];
    cs = s1;
end

function [FFTs, lengthVec] = snippets2FFTs(snippets, Fs)
    FFTs = cell(1, size(snippets, 1));
    lengthVec = zeros(1, length(snippets));
    
    for k = 1:length(snippets)
        % fft of snippets
        trace = squeeze(snippets{k}.Data);
        trace = trace(~isnan(trace));
        L = length(trace); % Length of signal
        NFFT = 2^nextpow2(L); % Next power of 2 from length of data
        freq = fft(trace, NFFT)/L;
        f = Fs/2*linspace(0,1,NFFT/2 + 1);
        lengthVec(k) = L;
        FFTs{k} = timeseries(f, abs(freq(1:NFFT/2+1)));
    end
end