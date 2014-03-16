function whiskTxt2Mat
[FileName,PathName,FilterIndex] = uigetfile('C:\Users\kiritani\Documents\data\cells\*.txt', 'choose a whisker .txt file');
fid = fopen(fullfile(PathName, FileName));
tline = fgetl(fid);
while ischar(tline)
    eval(tline);
    tline = fgetl(fid);
end
fclose(fid);
whiskTs = timeseries(angleArray, 'StartTime', 0.0005, 'Interval', 0.002);
uisave({'angleArray','r','basePoint', 'x1', 'y1', 'whiskTs'}, PathName)