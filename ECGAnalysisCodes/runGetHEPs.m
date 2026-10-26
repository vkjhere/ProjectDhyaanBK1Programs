clear; clc

[allSubjectNames,expDateList] = getDemographicDetails('BK1');
[goodSubjectList,~,~] = getGoodSubjectsBK1;
problamaticSubjects  = {'053DR'};
goodSubjectList = setdiff(goodSubjectList,problamaticSubjects,'stable');

folderSourceString = fileparts(fileparts(pwd)); % This should give the path where the BK1 folder is kept.
dataFolder = fullfile(folderSourceString,'data');
saveFolderName = 'savedHEPData'; % save locally within the folder
makeDirectory(saveFolderName);

useTheseIndices = 1:length(goodSubjectList);

for i = 1:length(useTheseIndices)

    subjectName = goodSubjectList{useTheseIndices(i)};

    disp(['Processing subject: ' subjectName]);

    expDate = expDateList{strcmp(subjectName,allSubjectNames)};
    getHEPs(subjectName,expDate,fullfile(folderSourceString,'data','segmentedDataLong'),saveFolderName);
end

disp('Finished');