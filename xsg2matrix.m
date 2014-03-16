function xsg2matrix
% FUNCTION XSG2MATRIX converts .xsg files made by Ephus to .mat files
% containing only matrices insetead of structures. This enables igor to
% read .xsg data.
% written by Taro Kiritani, taro.kiritani@epfl.ch

[FileName, PathName, FilterIndex] = uigetfile('*.xsg','Select the .xsg files','MultiSelect', 'on');
 
if iscell(FileName)
    fileNum = length(FileName);
else
    fileNum = 1;
end

for k = 1:fileNum
    try
        f = FileName{k};
    catch
        f = FileName;
    end
        
    xsgContent = load(fullfile(PathName, f), '-mat');
    clear ephysTrace_1 acquirerTrace_1 acquirerTrace_2 acquirerTrace_3 acquirerTrace_4 acquirerTrace_5
    
    try
        ephysTrace_1 = xsgContent.data.ephys.trace_1;
    end
    
    try
        acquirerTrace_1 = xsgContent.data.acquirer.trace_1;
    end
    
    try
        acquirerTrace_2 = xsgContent.data.acquirer.trace_2;
    end
    
    try
        acquirerTrace_3 = xsgContent.data.acquirer.trace_3;
    end
    
    try
        acquirerTrace_4 = xsgContent.data.acquirer.trace_4;
    end
    
    try
        acquirerTrace_5 = xsgContent.data.acquirer.trace_5;
    end
    
    destFile = strrep(fullfile(PathName, f), '.xsg', 'Mat.mat');
    vars = whos('*Trace*');
    for n = 1:length(vars)
        if n == 1
            save(destFile, vars(n).name);
        elseif n > 1
            save(destFile, vars(n).name, '-append');
        end
    end
end