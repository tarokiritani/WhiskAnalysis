function whiskTxt2Mat
[FileName,PathName,FilterIndex] = uigetfile('C:\Users\kiritani\Documents\data\cells\*.txt', 'choose a whisker .txt file');
text = fileread(fullfile(PathName, FileName));
eval(text);
whiskTs = timeseries(angleArray, 'StartTime', 0.0005, 'Interval', 0.002);
uisave({'angleArray','r','basePoint', 'whiskTs'}, PathName)