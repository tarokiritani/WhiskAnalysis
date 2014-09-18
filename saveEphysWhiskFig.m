function saveEphysWhiskFig

[FileName,PathName,FilterIndex] = uigetfile('C:\Users\kiritani\Documents\data\cells\*.xsg');
load(fullfile(PathName, FileName), '-mat');
ephysInterval = 1/header.ephys.ephys.sampleRate; % usually 40k Hz.
figure;
subplot(211)
plot([ephysInterval:ephysInterval:header.ephys.ephys.traceLength], data.ephys.trace_1)
ylabel('mV')
hold on;

[FileName,PathName,FilterIndex] = uigetfile('C:\Users\kiritani\Documents\data\cells\*.mat');
load(fullfile(PathName, FileName), '-mat');
subplot(212)
plot(whiskTs-whiskTs.mean, 'g')
ylabel('deg')
title(FileName)
hgsave([PathName, filesep, ['ephysWhisk', strrep(FileName, '.mat', '.fig')]]) 