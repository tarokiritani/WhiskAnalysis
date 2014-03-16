function result = activeTouchAnalysis(varargin)
strain = 'B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato'; % PV-Cre/ROSA-Cre-tdTomato, B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato, 
mksqlite('open', 'C:\Users\kiritani\Documents\data\GitHub\experiments\db\development.sqlite3');
query = ['SELECT * FROM analyses INNER JOIN cells ON analyses.cell_id = cells.id INNER JOIN mice ON cells.mouse_id = mice.id WHERE species_strain = "', strain, '" AND analysis_type = "active touch"'];
queryResult = mksqlite(query);
mksqlite('close');

c = clock;
if strcmp(strain, 'PV-Cre/ROSA-Cre-tdTomato')
    cellType = 'PV';
elseif strcmp (strain, 'B6(Cg)-Etv1<tm1.1(cre/ERT2)Zjh>/J/ROSA-CreRtomato')
    cellType = 'ETV';
elseif strcmp (strain, 'RBP')
    cellType = 'RBP4';
end
dirName = ['C:\Users\kiritani\Documents\data\analysis\activeTouch\', cellType, date, '-',num2str(c(4)), num2str(c(5))];
mkdir(dirName);

for n = 1:length(queryResult)
    [onsetSnippetsWhisker, whiskTimeVec, onsetSnippetsEphys, ephysTimeVec, onsetSnippetsSpike, onsets] = touchOnset(queryResult(n));
    
    % this part cam be in whiskOnset.
    figure;
    subplot(221)
    plot(ephysTimeVec, onsetSnippetsEphys');
    hold on
    plot(ephysTimeVec, mean(onsetSnippetsEphys, 2), 'LineWidth', 5);
    subplot(222)
    plot(whiskTimeVec, onsetSnippetsWhisker');
    hold on
    plot(whiskTimeVec, mean(onsetSnippetsWhisker, 2), 'LineWidth', 5);
    subplot(223)
    plot(ephysTimeVec, onsetSnippetsSpike)
    hold on
    plot(ephysTimeVec, nanmean(onsetSnippetsSpike, 2), 'LineWidth', 5)
    
    figFileName = ['mouse_id ',num2str(queryResult(n).mouse_id), ' experiment_number ', queryResult(n).experiment_number, ' cell_id ', num2str(queryResult(n).cell_id), '_',num2str(n)];
    hgsave([dirName, filesep,figFileName])
end

end

function [onsetSnippetsWhisker, whiskTimeVec, onsetSnippetsEphys, ephysTimeVec, onsetSnippetsSpike, onsets] = touchOnset(sqlRecord)

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
onsetSnippetsWhisker = cell(1, length(onsets));
onsetSnippetsEphys = cell(1, length(onsets));
onsetSnippetsSpike = cell(1, length(onsets));

traceWindow = 1;
for k = 1:length(onsets)
    onsetSnippetsWhisker{k} = squeeze(whiskTs.resample(onsets(k) - traceWindow:cameraInterval:onsets(k) + traceWindow).Data);
    onsetSnippetsEphys{k} = squeeze(ephysTrace.resample(onsets(k) - traceWindow:ephysInterval:onsets(k) + traceWindow).Data);
    onsetSnippetsSpike{k} = squeeze(spikeTs.resample(onsets(k) - traceWindow:ephysInterval:onsets(k) + traceWindow).Data);
end

onsetSnippetsWhisker = cell2mat(onsetSnippetsWhisker);
onsetSnippetsEphys = cell2mat(onsetSnippetsEphys);
onsetSnippetsSpike = cell2mat(onsetSnippetsSpike);
whiskTimeVec = cameraInterval * [1:size(onsetSnippetsWhisker, 1)];
ephysTimeVec = ephysInterval * [1:size(onsetSnippetsEphys, 1)];
end

