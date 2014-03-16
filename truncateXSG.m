function truncateXSG

[fileName, pathName,filterIndex] = uigetfile('C:\Users\kiritani\Documents\data\cells\*.xsg', 'choose an .xsg file');
load(fullfile(pathName, fileName), '-mat');

trace_length = inputdlg('how long is the trace?');
trace_length = str2double(trace_length);

data.ephys.trace_1 = data.ephys.trace_1(1:trace_length*header.ephys.ephys.sampleRate);
header.ephys.ephys.traceLength = trace_length;

save(fullfile(pathName, ['truncated_', fileName]), 'data', 'header');