function result = activeTouchAnalysis(varargin)
strain = 'B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato'; % PV-Cre/ROSA-Cre-tdTomato, B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato, 
analysisType = 'active touch';
mksqlite('open', 'C:\Users\kiritani\Documents\data\GitHub\experiments\db\development.sqlite3');
query = ['SELECT * FROM analyses INNER JOIN cells ON analyses.cell_id = cells.id INNER JOIN mice ON cells.mouse_id = mice.id WHERE species_strain = "', strain, '" AND analysis_type = "', analysisType,'"'];
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
    M = mapExpFiles(queryResult(n).files);
    atr = activeTouchRecording(M('xsgFile'), M('spikeFile'), M('whiskFile'), M('activeTouchFile'));
    
    
    neuron = getSnippets(queryResult(n), traceWindow);
    if neurons.isKey(int2str(queryResult(n).cell_id))
        neurons(int2str(queryResult(n).cell_id)) = combineTwoNeuronStructures(neuron, neurons(int2str(queryResult(n).cell_id)));
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
    figure;
    subplot(h, v, 1)
    hold on
    arrayfun(@(x) plot(n.onsetSnippetsEphys{x}.Time - mean(n.onsetSnippetsEphys{x}.Time), n.onsetSnippetsEphys{x}), 1:length(n.onsetSnippets));
    meanOnsetSnippetsEphys = nanmean(cell2mat(arrayfun(@(x) n.onsetSnippetsEphys{x}.Data, 1:length(n.onsetSnippetsEphys), 'UniformOutput', 0)),2);
    plot(n.onsetSnippetsEphys{1}.Time - mean(n.onsetSnippetsEphys{1}.Time), meanOnsetSnippetsEphys, 'LineWidth', 5, 'Color', 'r');
    title(['cell ', n.expNum]) 
    xlim([-traceWindow traceWindow])
    xlabel('sec')
    ylabel('Membrane potential (mV)')
    subplot(h, v, 2)
    plot(n.whiskTimeVec, n.onsetSnippetsWhisker');
    hold on
    plot(n.whiskTimeVec, mean(n.onsetSnippetsWhisker, 2), 'LineWidth', 5);
    subplot(223)
    plot(n.ephysTimeVec, n.onsetSnippetsSpike)
    hold on
    plot(n.ephysTimeVec, nanmean(n.onsetSnippetsSpike, 2), 'LineWidth', 5)
    
    figFileName = ['mouse_id ',num2str(queryResult(k).mouse_id), ' experiment_number ', queryResult(k).experiment_number, ' cell_id ', num2str(queryResult(n).cell_id), '_',num2str(n)];
    hgsave([dirName, filesep,figFileName])
end

end

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

onsets = find(diff(onOffTiming) == 1); % this works only when the timing is found from the movie.
onsets = whiskTs.Time(onsets);
Snippets.onsets = onsets;

% Does whiskTs exist?
Snippets.onsetSnippetsWhisker = arrayfun(@(k) whiskTs.resample(onsets(k) - traceWindow:cameraInterval:onsets(k) + traceWindow).Data, [1:length(onsets)]);
Snippets.onsetSnippetsEphys = arrayfun(@(k) ephysTrace.resample(onsets(k) - traceWindow:ephysInterval:onsets(k) + traceWindow).Data, [1:length(onsets)]);
Snippets.onsetSnippetsSpike = arrayfun(@(k) intersect(peakTiming(peakTiming > onsets(k) - traceWindow), peakTiming(peakTiming < onsets(k) + traceWindow))-onsets(k), [1:length(onsets)]);

end

