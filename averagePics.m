function averagePics
% AVERAGEPICS averages helisocam pictueres of multiple channels found in
% multiple folders.

folders = uipickfiles('FilterSpec', 'C:\Users\kiritani\Documents\data\helioData');
ch0ImageStack = [];
ch1ImageStack = [];
for k = 1:length(folders)
    ch0Image =  dir(strcat(folders{k}, filesep, 'AVG*00.tif'));
    ch0ImageFile = [folders{k}, filesep, ch0Image.name];    
    try ch0ImageStack = ch0ImageStack + double(imread(ch0ImageFile)); catch ch0ImageStack = double(imread(ch0ImageFile));end
    ch1Image =  dir(strcat(folders{k}, filesep, 'AVG*01.tif'));
    ch1ImageFile = [folders{k}, filesep, ch1Image.name];
    try ch1ImageStack = ch1ImageStack + double(imread(ch1ImageFile)); catch ch1ImageStack = double(imread(ch1ImageFile));end
end
ch0ImageStack = ch0ImageStack/k;
ch1ImageStack = ch1ImageStack/k;
figure
imagesc(ch0ImageStack);
figure
imagesc(ch1ImageStack);
[FileName,PathName] = uiputfile;
imwrite(uint16(ch0ImageStack),[fullfile(PathName, FileName),'ch0.tif'],'tif')
imwrite(uint16(ch1ImageStack),[fullfile(PathName, FileName),'ch1.tif'],'tif')