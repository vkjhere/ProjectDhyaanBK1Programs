% Save data in fieldtrip format

% Mandatory fixed options
folderSourceString = 'N:\Projects\ProjectDhyaan\BK1';
% folderSourceString = 'D:\OneDrive - Indian Institute of Science\Supratim\Projects\ProjectDhyaan\BK1'; % Segmented data which is used for all analysis is kept at {folderSourceString}\data\segmentedData
% folderSourceString = 'E:\OneDrive - Indian Institute of Science\VK Project Dhyaan' ;

goodSubjectList = getGoodSubjectsBK1; % subjects for which data is computed
[allSubjectNames,expDateList] = getDemographicDetails('BK1');

avgRefFlag = 1; % for average re-referenced data; 0 for unipolar referencing.
if avgRefFlag
    ftDataFolder = fullfile(folderSourceString,'data','ftDataAvgRef'); % avg re-referenced fieldtrip data is saved here
else
    ftDataFolder = fullfile(folderSourceString,'data','ftData'); % Unipolar referenced fieldtrip data is saved here
end
makeDirectory(ftDataFolder);

badEyeCondition = 'ep'; % use 'wo' when eye data is not used and 'ep' for eye position. Note that bad trials will be removed before saving in fieldtrip format
badTrialVersion = 'v8';

%%%%%%%%%%%%%%%%%%%%%%%% Get data for all protocols %%%%%%%%%%%%%%%%%%%%%%%
protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M1'} {'G2'} {'EO2'} {'EC2'} {'M2'}]; 

useTheseIndices = 1:length(goodSubjectList);

%%%%%%%%%%%%%%%%%%%%%%%%%% Save Fieldtrip data %%%%%%%%%%%%%%%%%%%%%%%%%%%%
saveFTDataFlag=0; % 1 only if you want to re-generate data in fieldtrip format
if saveFTDataFlag
    for i=1:length(useTheseIndices) %#ok<*UNRCH>
        subjectName = goodSubjectList{useTheseIndices(i)};
        disp(['Analyzing for subject ' subjectName]);
        expDate = expDateList{strcmp(subjectName,allSubjectNames)};

        saveFTData(subjectName,expDate,protocolNameList,folderSourceString,badEyeCondition,badTrialVersion,ftDataFolder, avgRefFlag);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%% Save Connectivity data %%%%%%%%%%%%%%%%%%%%%%%%%%%
connMethod = 'ppc'; % coh, csd, corr, plv, wpli, wpli_debiased, ppc, wppc, laggedCoh, 'icoh' (imag(coh)).
stRange = [0.25 1.25];
saveConnDataFlag=1;
if saveConnDataFlag
    for i=1:length(useTheseIndices) %#ok<*UNRCH>
        subjectName = goodSubjectList{useTheseIndices(i)};
        disp(['Analyzing for subject ' subjectName]);
        expDate = expDateList{strcmp(subjectName,allSubjectNames)};

        saveConnData(subjectName,protocolNameList,badEyeCondition,badTrialVersion,ftDataFolder,connMethod,stRange,avgRefFlag);
    end
end