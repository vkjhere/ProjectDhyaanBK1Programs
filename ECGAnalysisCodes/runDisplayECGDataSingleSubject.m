clear; close all

[allSubjectNames,expDateList] =getDemographicDetails('BK1');
[goodSubjectList, meditatorList, controlList] = getGoodSubjectsBK1;
folderSourceString = fileparts(fileparts(pwd)); % This should give the path where the BK1 folder is kept.

% Save data for all subjects
saveFolderName = 'ECGResultsSingleSubject';
saveFileFlag = 0;

useTheseIndices = 1:length(goodSubjectList);

for i=1:length(useTheseIndices)
    if saveFileFlag
        fh=figure(1); clf(fh);
        fh.WindowState = 'maximized';
    end

    subjectName = goodSubjectList{useTheseIndices(i)};
    disp(['Analyzing for the subject ' subjectName]);
    expDate = expDateList{strcmp(subjectName,allSubjectNames)};
    displayECGDataSingleSubject(subjectName,expDate,folderSourceString);
    pause;

    if saveFileFlag
        makeDirectory(saveFolderName);
        fileNameTif = fullfile(saveFolderName,[subjectName '.tif']);
        print(fh,fileNameTif,'-dtiff','-r300');
    end
end