% Copy manual RR files to new location

clear; clc

protocols = {'M1a','M1b','M1c','M2a','M2b','M2c','G1','G2','EO1','EO2','EC1','EC2'};
numProtocols = length(protocols);

[allSubjectNames,expDateList] = getDemographicDetails('BK1');
[goodSubjectList,~,~] = getGoodSubjectsBK1;

folderSourceString = fileparts(fileparts(pwd)); % This should give the path where the BK1 folder is kept.
dataFolder = fullfile(folderSourceString,'data');
saveFolderName = 'savedRRData'; % save locally within the folder
makeDirectory(saveFolderName);

useTheseIndices = 1:length(goodSubjectList);

for i = 1:length(useTheseIndices)

    subjectName = goodSubjectList{useTheseIndices(i)};
    disp(['Processing subject: ' subjectName]);

    expDate = expDateList{strcmp(subjectName,allSubjectNames)};

    for j = 1:numProtocols
        protocolName = protocols{j};
        inputFile = fullfile('savedData',subjectName,'EEG',expDate,protocolName,'segmentedData','LFP','Rpeaks_Manual.mat');
        outputFile = fullfile('savedRRData',[subjectName '_' protocolName '_Manual.mat']);

        if exist(inputFile,'file')
            copyfile(inputFile,outputFile);
        else
            disp([inputFile ' does not exist']);
        end
    end
end