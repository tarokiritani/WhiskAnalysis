function result = poissonCurrentAnalysis(varargin)
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

neurons = containers.Map();
for n = 1:length(queryResult)
    M = mapExpFiles(sqlRecord(n).file);
    pir = poissonInjectionRecording(M('xsgFile'), M('spikeFile'), M('whiskFile'), M('cInjectionFile'));
    figure;
    subplot(311)
    plot(pir.getEphysTrace);
    subplot(312)
    plot(pir.getWhiskTrace);
    subplot(313)
    plot(pir.getCurrentInjection);
    
    figure;
    subplot(221)
    hold on;
    arrayfun(@(x) plot(pir.getOnsetSnippets{x}, 'b'), 1:length(pir.getOnsetSnippets));
    subplot(222)
    hold on;
    arrayfun(@(x) plot(pir.getOffsetSnippets{x}, 'b'), 1:length(pir.getOffsetSnippets));
    
end

