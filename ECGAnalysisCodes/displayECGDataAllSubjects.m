function displayECGDataAllSubjects(hRR,hHRV,protocolName,folderSourceString,comparisonStr,manualStr)

if ~exist('folderSourceString','var'); folderSourceString='';           end
if ~exist('comparisonStr','var');      comparisonStr='paired';          end
if ~exist('manualStr','var');          manualStr='_Manual';             end

if isempty(folderSourceString)
    folderSourceString = pwd; % This should give the path where the BK1 folder is kept.
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get subject list %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(comparisonStr,'paired')
    pairedSubjectNameList = getPairedSubjectsBK1;            
    subjectNameLists{1} = pairedSubjectNameList(:,1);
    subjectNameLists{2} = pairedSubjectNameList(:,2);
    pairedDataFlag      = 1;
else
    [~, meditatorList, controlList] = getGoodSubjectsBK1;
    subjectNameLists{1} = meditatorList;
    subjectNameLists{2} = controlList;
    pairedDataFlag      = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hrRange = [50 120]; % Heart rate outside this range will not be considered
rrIntervalLims = [60/hrRange(2) 60/hrRange(1)];

meanRR = cell(1,2);
hrv = cell(1,2);

for i=1:2
    numSubjects = length(subjectNameLists{i});

    mData = zeros(1,numSubjects);
    sData = zeros(1,numSubjects);
    for j=1:numSubjects
        rrFileName = fullfile(folderSourceString,'savedRRData',[subjectNameLists{i}{j} '_' protocolName manualStr '.mat']);
        if exist(rrFileName,'file')
            tmp = load(rrFileName);
            rrIntervals = diff(seconds(tmp.data.R_loc{1}));
            goodRRIntervals = rrIntervals(intersect(find(rrIntervals>=rrIntervalLims(1)),find(rrIntervals<=rrIntervalLims(2))));
            mData(j) = mean(goodRRIntervals);
            sData(j) = std(goodRRIntervals);
        else
            mData(j) = NaN; % Assign NaN if the file does not exist
            sData(j) = NaN;  % Assign NaN for standard deviation as well
        end
    end

    meanRR{i} = mData;
    hrv{i} = sData;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Display %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
colorArray{1} = [0.8 0 0.8];      % Purple
colorArray{2} = [0.25 0.41 0.88]; % Cyan

displaySettings.fontSizeLarge = 10;
displaySettings.tickLengthMedium = [0.025 0];
displaySettings.xTickLabels = [{'Med'} {'Con'}];

showData = 1;
plotCentralTendency = 1;
showSignificance = 1;

displaySettings.plotAxes = hRR;
displaySettings.setYLim = rrIntervalLims;
displayViolinPlot(meanRR,colorArray,showData,plotCentralTendency,showSignificance,pairedDataFlag,displaySettings);
xlim(hRR,[0 3]); 
title(hRR,protocolName);

displaySettings.plotAxes = hHRV;
displaySettings.setYLim = [0 0.2];
displayViolinPlot(hrv,colorArray,showData,plotCentralTendency,showSignificance,pairedDataFlag,displaySettings);
xlim(hHRV,[0 3]);