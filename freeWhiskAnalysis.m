function result = freeWhiskAnalysis(varargin)
strain = 'B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato'; % PV-Cre/ROSA-Cre-tdTomato, B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato, VIP-ires-Cre/ROSA-CreR-tdTomato, SOM-ires-Cre/ROSA-CreR-tdTomato
mksqlite('open', 'C:\Users\kiritani\Documents\data\GitHub\experiments\db\development.sqlite3');
query = ['SELECT * FROM analyses INNER JOIN cells ON analyses.cell_id = cells.id INNER JOIN mice ON cells.mouse_id = mice.id INNER JOIN users ON users.id = mice.user_id WHERE species_strain = "', strain, '" AND analysis_type = "free whisking" AND email = "taro.kiritani@epfl.ch"'];
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
dirName = ['C:\Users\kiritani\Documents\data\analysis\freewhisk\', cellType, date, '-',num2str(c(4)), num2str(c(5))];
mkdir(dirName);

%% whisk onset group analysis
neurons = containers.Map();
traceWindow = 1;
for n = 1:length(queryResult)
    Snippets = getSnippets(queryResult(n), traceWindow);
    Snippets.expNum = queryResult(n).experiment_number;
    if neurons.isKey(int2str(queryResult(n).cell_id))
        neurons(int2str(queryResult(n).cell_id)) = combineTwoNeuronStructures(Snippets, neurons(int2str(queryResult(n).cell_id)));
    else
        neurons(int2str(queryResult(n).cell_id)) = Snippets;
    end
end

keys = neurons.keys;
h = 2;
v = 3;

for k = 1:length(keys)
    neuron = neurons(keys{k});
    figure;
    subplot(h, v, 1)
    plot(neuron.ephysTimeVec - traceWindow, (neuron.onsetSnippetsEphys)', 'b');
    hold on
    plot(neuron.ephysTimeVec - traceWindow, nanmean(neuron.onsetSnippetsEphys, 2), 'LineWidth', 5, 'Color', 'r');
    title(['cell ', neuron.expNum]) 
    xlim([-traceWindow traceWindow])
    xlabel('sec')
    ylabel('mV')
    subplot(h, v, 2)
    hold on
    arrayfun(@(n) plot([1:length(meanWhisk)]*neuron.cameraInterval-traceWindow, squeeze(neuron.onsetSnippetsWhisker{n}.Data)), [1:length(neuron.onsetSnippetsWhisker)]);
    meanWhisk = nanmean(cell2mat(arrayfun(@(n) squeeze(neuron.onsetSnippetsWhisker{n}.Data)', [1:length(neuron.onsetSnippetsWhisker)], 'UniformOutput', 0)'));
    plot([1:length(meanWhisk)]*neuron.cameraInterval-traceWindow, meanWhisk, 'LineWidth', 5, 'Color', 'r');
    xlim([-traceWindow traceWindow])
    xlabel('sec')
    ylabel('deg')
    subplot(h, v, 3)
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
    subplot(h, v, 4);
    bar(spRate(1:2))
    set(gca, 'xticklabel',{'quiet','whisk'});
     ylabel('freq (Hz)')
    
    Fs = neuron.ephysSampleRate;  % sampling frequency
    coeffVals = cell(1, length(neuron.whiskSnippetsEphys));
%     maxlag = 0.1 / ephysInterval; % lag is 100 ms.

    [FFTwhisk, lengthVecWhisk] = snippets2FFTs(neuron.whiskSnippetsEphys, Fs);

    for kk = 1:length(FFTwhisk)
        FFTwhisk{kk} = squeeze(FFTwhisk{kk}.resample(1:1:50).Data);
    end

    FFTwhisk = cell2mat(FFTwhisk);
    FFTwhisk = FFTwhisk * lengthVecWhisk'/sum(lengthVecWhisk);
    subplot(h, v, 5);plot(FFTwhisk);
    hold on;
    xlabel('Hz')
    ylabel('|\itmV|')
    [FFTquiet, lengthVecQuiet] = snippets2FFTs(neuron.quietSnippetsEphys, Fs);

    for kk = 1:length(FFTquiet)
        FFTquiet{kk} = squeeze(FFTquiet{kk}.resample(1:1:50).Data);
    end

    FFTquiet = cell2mat(FFTquiet);
    FFTquiet = FFTquiet * lengthVecQuiet'/sum(lengthVecWhisk);
    plot(FFTquiet,'r')
    legend({'quiet', 'whisk'})
    
    figFileName = ['cell_id', keys{k}];
    
    %% find Vm of whisk and quiet periods. 
    f = @(c,x) squeeze(c{x}.Data)';
    snippetsVecWhisk = cell2mat(arrayfun(@(x) f(neuron.whiskSnippetsEphys, x), [1:length(neuron.whiskSnippetsEphys)], 'UniformOutput', 0));
    snippetsVecQuiet = cell2mat(arrayfun(@(x) f(neuron.quietSnippetsEphys, x), [1:length(neuron.quietSnippetsEphys)], 'UniformOutput', 0));
    
    nanmean(snippetsVecWhisk)
    nanvar(snippetsVecWhisk)
    
    nanmean(snippetsVecQuiet)
    nanvar(snippetsVecQuiet)
    g = @(x) neuron.whiskSnippetsEphys{x}.TimeInfo.End - neuron.whiskSnippetsEphys{x}.TimeInfo.Start;
    firingRate = length(cell2mat(neuron.whiskSnippetsSpike)) / sum(cellfun(g, num2cell(1:length(neuron.whiskSnippetsEphys))));
    
    hgsave([dirName, filesep, figFileName])
end


p = mfilename('fullpath');
dos(['copy ', p, '.m ', dirName, filesep, 'freeWhiskAnalysis.m']);

end


%%
function Snippets = getSnippets(sqlRecord, traceWindow)

% load .mat files
filesToLoad = textscan(sqlRecord.file, '%s', 'delimiter', ';');
filesToLoad = filesToLoad{1};
for k = 1:length(filesToLoad)
    load(filesToLoad{k}, '-mat');
end

ephysInterval = 1/header.ephys.ephys.sampleRate; % usually 40k Hz.
cameraInterval = whiskTs.TimeInfo.Increment; % usually 500 Hz.

ephysTrace = timeseries(data.ephys.trace_1, 'StartTime', ephysInterval, 'Interval', ephysInterval);
[WhiskPeriods, QuietPeriods] = classifyWhiskState(whiskTs);

Snippets.onsetSnippetsWhisker = arrayfun(@(k) whiskTs.resample(WhiskPeriods(k, 1) - traceWindow:cameraInterval:WhiskPeriods(k, 1) + traceWindow), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);
Snippets.onsetSnippetsEphys = arrayfun(@(k) squeeze(ephysTrace.resample(WhiskPeriods(k, 1) - traceWindow:ephysInterval:WhiskPeriods(k, 1) + traceWindow).Data), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);
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

% Snippets.onsetSnippetsWhisker = cell2mat(Snippets.onsetSnippetsWhisker);
Snippets.onsetSnippetsEphys = cell2mat(Snippets.onsetSnippetsEphys);
Snippets.whiskTimeVec = cameraInterval * [1:size(Snippets.onsetSnippetsWhisker, 1)];
Snippets.ephysTimeVec = ephysInterval * [1:size(Snippets.onsetSnippetsEphys, 1)];
Snippets.ephysSampleRate = header.ephys.ephys.sampleRate;
Snippets.cameraInterval = cameraInterval;

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

function s1 = combineTwoNeuronStructures(s1, s2)
    fields = fieldnames(s1);
    for k = 1:length(fields)
        if iscell(s1.(fields{k}))
            s1.(fields{k}) = [s1.(fields{k}), s2.(fields{k})];
        end
    end
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