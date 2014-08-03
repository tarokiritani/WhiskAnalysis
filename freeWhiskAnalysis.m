function result = freeWhiskAnalysis(varargin)
strain = 'B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato'; % PV-Cre/ROSA-Cre-tdTomato, B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato, VIP-ires-Cre/ROSA-CreR-tdTomato, SOM-ires-Cre/ROSA-CreR-tdTomato
analysisType = 'free whisking';
mksqlite('open', 'C:\Users\kiritani\Documents\data\GitHub\experiments\db\development.sqlite3');
query = ['SELECT * FROM analyses INNER JOIN cells ON analyses.cell_id = cells.id INNER JOIN mice ON cells.mouse_id = mice.id INNER JOIN users ON users.id = mice.user_id WHERE species_strain = "', strain, '" AND analysis_type = "', analysisType,'" AND email = "taro.kiritani@epfl.ch"'];
queryResult = mksqlite(query);
mksqlite('close');

c = clock;

cellTypeMap = containers.Map({'PV-Cre/ROSA-Cre-tdTomato','B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato','VIP-ires-Cre/ROSA-CreR-tdTomato','SOM-ires-Cre/ROSA-CreR-tdTomato'}, {'PV', 'ETV', 'VIP', 'SOM'});
cellType = cellTypeMap(strain);
analysisType = strrep(analysisType, ' ', '');
dirName = ['C:\Users\kiritani\Documents\data\analysis\', analysisType,'\', cellType, date, '-',num2str(c(4)), num2str(c(5))];
mkdir(dirName);

%% whisk onset group analysis
neurons = containers.Map();
traceWindow = 1;
for n = 1:length(queryResult)
    neuron = getSnippets(queryResult(n), traceWindow);
    if neurons.isKey(int2str(queryResult(n).cell_id))
        neurons(int2str(queryResult(n).cell_id)) = combineTwoNeuronStructures(neurons(int2str(queryResult(n).cell_id)), neuron);
    else
        neuron.expNum = queryResult(n).experiment_number;
        neuron.cell_id = queryResult(n).cell_id;
        neurons(int2str(queryResult(n).cell_id)) = neuron;
    end
end

keys = neurons.keys;
Neurons = cell(1, length(keys));
for n = 1:length(keys)
    Neurons{n} = neurons(keys{n});
end

h = 2;
v = 4;

for k = 1:length(Neurons)
    n = Neurons{k};
    
    for m = 1:length(n.ephysTrace)
        figure;
        subplot(2, 1, 1)
        plot(n.ephysTrace{m})
        xlim([0 60])
        ylabel('mV')
        subplot(2, 1, 2)
        plot(n.whiskTrace{m})
        xlim([0 60])
        title(['cell ', n.expNum])
        figName = ['cell_id', n.expNum, '_', num2str(m)];
        hgsave([dirName, filesep, figName])
    end
    
    figure;
    subplot(h, v, 1)
    hold on
    arrayfun(@(x) plot(n.onsetSnippetsEphys{x}.Time - mean(n.onsetSnippetsEphys{x}.Time), n.onsetSnippetsEphys{x}.Data, 'b'), 1:length(n.onsetSnippetsEphys));
    meanOnsetSnippetsEphys = nanmean(cell2mat(arrayfun(@(x) n.onsetSnippetsEphys{x}.Data, 1:length(n.onsetSnippetsEphys), 'UniformOutput', 0)),2);
    plot(n.onsetSnippetsEphys{1}.Time - mean(n.onsetSnippetsEphys{1}.Time), meanOnsetSnippetsEphys, 'LineWidth', 5, 'Color', 'r');
    title(['cell ', n.expNum]) 
    xlim([-traceWindow traceWindow])
    xlabel('sec')
    ylabel('Membrane potential (mV)')
    subplot(h, v, 2)
    hold on
    arrayfun(@(x) plot(n.onsetSnippetsWhisker{x}.Time - mean(n.onsetSnippetsWhisker{x}.Time), n.onsetSnippetsWhisker{x}.Data), [1:length(n.onsetSnippetsWhisker)]);
    meanWhisk = nanmean(cell2mat(arrayfun(@(x) n.onsetSnippetsWhisker{x}.Data, [1:length(n.onsetSnippetsWhisker)], 'UniformOutput', 0)), 2);
    plot(n.onsetSnippetsWhisker{1}.Time - mean(n.onsetSnippetsWhisker{1}.Time), meanWhisk, 'LineWidth', 5, 'Color', 'r');
    xlim([-traceWindow traceWindow])
    xlabel('sec')
    ylabel('deg')
    subplot(h, v, 3)
    histVec = [];
    for nn = 1:length(n.onsetSnippetsSpike)
        for m = 1:length(n.onsetSnippetsSpike{nn})
            line([n.onsetSnippetsSpike{nn}(m), n.onsetSnippetsSpike{nn}(m)], [nn-1 nn]);
        end
        histVec = [histVec, n.onsetSnippetsSpike{nn}];
    end
    xlim([-traceWindow traceWindow])
    xlabel('sec')
    ylabel('trials')
    spRate = histc(histVec,[-1 0 1]) / nn; % firing rates -1 to 0 sec and 0 to 1 sec.
    subplot(h, v, 4);
    bar(spRate(1:2))
    set(gca, 'xticklabel',{'before','after'});
    ylabel('Firing frequency (Hz)')
    
    Fs = n.ephysSampleRate;  % sampling frequency
    coeffVals = cell(1, length(n.whiskSnippetsEphys));
%     maxlag = 0.1 / ephysInterval; % lag is 100 ms.

    FFTwhisk = snippets2FFTs(n.whiskSnippetsEphys, Fs); 
    spect = arrayfun(@(x) x.ts.resample(1:1:100).Data',  FFTwhisk, 'UniformOutput', 0);
    sl = arrayfun(@(x) x.signalLength, FFTwhisk);
    sl = sl/sum(sl);
    sl = repmat(sl, 1, 100);
    spect = nanmean(cell2mat(spect).*sl);    
    subplot(h, v, 5);plot([1:100], spect);
    hold on;
    xlabel('Hz')
    ylabel('mV^2/Hz')
    
    FFTquiet = snippets2FFTs(n.quietSnippetsEphys, Fs);
    spect = arrayfun(@(x) x.ts.resample(1:1:100).Data',  FFTquiet, 'UniformOutput', 0);
    sl = arrayfun(@(x) x.signalLength, FFTquiet);
    sl = sl/sum(sl);
    sl = repmat(sl, 1, 100);
    spect = nanmean(cell2mat(spect).*sl);    
    subplot(h, v, 5);plot([1:100], spect, 'r');
    legend({'whisk', 'quiet'})
    
    figFileName = ['cell_id', n.expNum];
    
    % find Vm of whisk and quiet periods. 
    f = @(c,x) squeeze(c{x}.Data)';
    snippetsVecWhisk = cell2mat(arrayfun(@(x) f(n.whiskSnippetsEphys, x), [1:length(n.whiskSnippetsEphys)], 'UniformOutput', 0));
    snippetsVecQuiet = cell2mat(arrayfun(@(x) f(n.quietSnippetsEphys, x), [1:length(n.quietSnippetsEphys)], 'UniformOutput', 0));
    
    Neurons{k}.whiskVm = nanmean(snippetsVecWhisk);
    Neurons{k}.whiskVmVar = nanvar(snippetsVecWhisk);
    
    Neurons{k}.quietVm = nanmean(snippetsVecQuiet);
    Neuons{k}.quietVmVar = nanvar(snippetsVecQuiet);
    
    subplot(h, v, 6)
    bins = -85:10:45;
    whiskVmCount = hist(snippetsVecWhisk, bins);
    whiskDist = whiskVmCount/sum(whiskVmCount)*100;
    barh(bins, whiskDist, 'barWidth', 1);
    xlabel('%');
    ylabel('Membrane potential (mV)');
    set(gca, 'YTick', -80:10:50)
    
    subplot(h, v, 7)
    quietVmCount = hist(snippetsVecQuiet, bins);
    quietDist = quietVmCount/sum(quietVmCount)*100;
    barh(bins, quietDist, 'barWidth', 1, 'FaceColor', 'r');
    xlabel('%');
    ylabel('Membrane potential (mV)');
    set(gca, 'YTick', -80:10:50)
    
    g1 = @(se, x) se{x}.TimeInfo.End - se{x}.TimeInfo.Start; % maybe this part is a bit difficult to read?
    Neurons{k}.quietFiringRate = length(cell2mat(n.whiskSnippetsSpike)) / sum(cellfun(@(x) g1(n.whiskSnippetsEphys, x), num2cell(1:length(n.whiskSnippetsEphys))));
    Neurons{k}.whiskFiringRate = length(cell2mat(n.quietSnippetsSpike)) / sum(cellfun(@(x) g1(n.quietSnippetsEphys, x), num2cell(1:length(n.quietSnippetsEphys))));
    
    hgsave([dirName, filesep, figFileName])
end

groupAnalysis = figure;
h = 2;
v = 3;
subplot(h, v, 1);
plot([1, 2], [cellfun(@(x) x.quietVm, Neurons)' cellfun(@(x) x.whiskVm, Neurons')], '-ro');
xlim([0.5 2.5])
set(gca, 'XTick',[1 2]);
set(gca, 'xticklabel',{'quiet','whisk'});
ylabel('Membrane potential (mV)');

subplot(h, v, 2);
plot([1, 2], [cellfun(@(x) x.quietFiringRate, Neurons)' cellfun(@(x) x.whiskFiringRate, Neurons)'], '-ro');
xlim([0.5 2.5])
set(gca, 'XTick',[1 2]);
set(gca, 'xticklabel',{'quiet','whisk'});
ylabel('Firing frequncy (Hz)');

hgsave([dirName, filesep, 'groupAnalysis'])

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
[WhiskPeriods, QuietPeriods] = classifyWhiskState(whiskTs, 'longWhiskingTime', true);

Snippets.onsetSnippetsWhisker = arrayfun(@(k) whiskTs.resample(WhiskPeriods(k, 1) - traceWindow:cameraInterval:WhiskPeriods(k, 1) + traceWindow), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);
Snippets.onsetSnippetsEphys = arrayfun(@(k) ephysTrace.resample(WhiskPeriods(k, 1) - traceWindow:ephysInterval:WhiskPeriods(k, 1) + traceWindow), [1:size(WhiskPeriods, 1)], 'UniformOutput', 0);
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

Snippets.spikeSnippets = spikeSnippets;

Snippets.ephysSampleRate = header.ephys.ephys.sampleRate;
Snippets.cameraInterval = cameraInterval;
Snippets.ephysTrace{1} = ephysTrace;
Snippets.whiskTrace{1} = whiskTs;

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
    
    fields = fieldnames(s2);
    for k = 1:length(fields)
        if iscell(s1.(fields{k}))
            try 
                s1.(fields{k}) = [s1.(fields{k}), s2.(fields{k})];
            catch
                s1.(fields{k}) = [s1.(fields{k}); s2.(fields{k})];
            end
        end
    end
end

function FFTs = snippets2FFTs(snippets, Fs)
    FFTs = struct('psdestx', [], 'signalLength', [], 'Fxx', [], 'ts', []);
    FFTs = repmat(FFTs, length(snippets), 1);

    for k = 1:length(snippets)
        % fft of snippets
        trace = snippets{k}.Data;
        trace = trace(~isnan(trace));
        L = length(trace);
        [psdestx, Fxx] = periodogram(trace, rectwin(L), L, Fs);
        FFTs(k).psdestx = psdestx;
        FFTs(k).Fxx = Fxx; 
        FFTs(k).signalLength = L;
        ts = timeseries(psdestx, Fxx);
        ts.Data(1) = nan;
        FFTs(k).ts = ts;
    end
end