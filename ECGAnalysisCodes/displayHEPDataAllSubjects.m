% displayHEPDataAllSubjects
%
% It uses HEP data saved by runGetHEPs.m

function [hepDataToReturn,ampDataToReturn,goodSubjectNameListsToReturn,topoplotDataToReturn,xsHEP] = displayHEPDataAllSubjects(subjectNameLists,protocolName,manualStr,timeWindowList,axisRangeList,cutoffList,useMedianFlag,hAllPlots,pairedDataFlag,displayDataFlag)

if ~exist('protocolName','var');              protocolName='G1';        end
if ~exist('manualStr','var');                 manualStr='_Manual';      end

if ~exist('timeWindowList','var')
    timeWindowList{1} = [0.200 0.300];
    timeWindowList{2} = [0.350 0.450];
    timeWindowList{3} = [0.455 0.595];
end
if ~exist('axisRangeList','var')
    axisRangeList{1} = [-0.2 1];   % time lims (s)
    axisRangeList{2} = [-15 15];   % yLims (uV)
    axisRangeList{3} = [-5 5];     % cLims (topo, uV)
end
if ~exist('cutoffList','var')
    cutoffList = [3 200]; % [numElecs numRPeaks]
end
cutoffNumElectrodes = cutoffList(1);
cutoffNumRPeaks     = cutoffList(2);

if ~exist('useMedianFlag','var');   useMedianFlag = 0;   end
if ~exist('hAllPlots','var');       hAllPlots = [];      end
if ~exist('pairedDataFlag','var');  pairedDataFlag = 0;  end
if ~exist('displayDataFlag','var'); displayDataFlag = 1; end

numTimeWindows = length(timeWindowList);
timeWindowColors = copper(numTimeWindows);

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Display options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
displaySettings.fontSizeLarge = 10;
displaySettings.tickLengthMedium = [0.025 0];
displaySettings.colorNames(1,:) = [0.8 0 0.8];      % Purple  - Meditators
displaySettings.colorNames(2,:) = [0.25 0.41 0.88]; % Cyan    - Controls
titleStr{1} = 'Meditators';
titleStr{2} = 'Controls';

timeLims  = axisRangeList{1};
yLimsHEP  = axisRangeList{2};
cLimsTopo = axisRangeList{3};

%%%%%%%%%%%%%%%%%%%%%%%% Get electrode groups %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gridType = 'EEG';
capType  = 'actiCap64_UOL';
hEPSaveFolderName = 'savedHEPData';

[electrodeGroupList,groupNameList] = getElectrodeGroups(gridType,capType,[],'ecg');
numGroups = length(electrodeGroupList);

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Generate plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if displayDataFlag
    if isempty(hAllPlots)
        hAllPlots.hHEP   = getPlotHandles(1,numGroups,[0.05 0.55 0.6 0.3],0.02,0.02,1);
        hAllPlots.hAmp   = getPlotHandles(numTimeWindows,numGroups,[0.05 0.05 0.6 0.45],0.02,0.02,0);
        hAllPlots.hTopo0 = getPlotHandles(1,2,[0.66 0.55 0.3 0.30],0.01,0.01,1);
        hAllPlots.hTopo2 = getPlotHandles(numTimeWindows,3,[0.66 0.02 0.3 0.50],0.02,0.02,1);
    else
        hHEP   = hAllPlots.hHEP;
        hAmp   = hAllPlots.hAmp;
        hTopo0 = hAllPlots.hTopo0;
        hTopo2 = hAllPlots.hTopo2;
    end
    montageChanlocs = showElectrodeGroups(hTopo0(1,:),capType,electrodeGroupList,groupNameList);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
goodSubjectNameLists = getGoodSubjectNameListHEP(subjectNameLists,protocolName,manualStr,cutoffNumRPeaks,pairedDataFlag,hEPSaveFolderName);
[hepData,numRPeaksAll,xsHEP] = getHEPDataAllSubjects(goodSubjectNameLists,protocolName,manualStr,hEPSaveFolderName);

%%%%%%%%%%%%%%%%%%%%%%% Get time-window sample positions %%%%%%%%%%%%%%%%%%
timePosList = cell(1,numTimeWindows);
for i = 1:numTimeWindows
    timePosList{i} = intersect(find(xsHEP>=timeWindowList{i}(1)),find(xsHEP<timeWindowList{i}(2)));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% Show Topoplots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numElectrodes = size(hepData{1},1);
comparisonData = zeros(numTimeWindows,2,numElectrodes);

topoplotDataToReturn = cell(2,numTimeWindows);
for i = 1:2
    x = hepData{i}; % numElectrodes x numTimePoints x numSubjects

    for j = 1:numTimeWindows
        % mean HEP amplitude within the time window, for every electrode & subject
        data3D = squeeze(mean(x(:,timePosList{j},:),2)); % numElectrodes x numSubjects

        if useMedianFlag
            data = median(data3D,2,'omitnan');
        else
            data = mean(data3D,2,'omitnan');
        end
        comparisonData(j,i,:) = data;

        topoplotDataToReturn{i,j} = data;
        if displayDataFlag
            axes(hTopo2(j,i)); %#ok<*LAXES>
            topoplot(data,montageChanlocs,'electrodes','on','maplimits',cLimsTopo,'plotrad',0.6,'headrad',0.6); colorbar;
            if j==1
                title(titleStr{i},'color',displaySettings.colorNames(i,:));
            end
            if i==1
                ylabel(['[' num2str(timeWindowList{j}(1)) ' ' num2str(timeWindowList{j}(2)) '] s']);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%% Plot the difference of topoplots %%%%%%%%%%%%%%%%%%%
if displayDataFlag
    for i = 1:numTimeWindows
        axes(hTopo2(i,3));
        data = -diff(squeeze(comparisonData(i,:,:)));
        topoplot(data,montageChanlocs,'electrodes','on','maplimits',cLimsTopo,'plotrad',0.6,'headrad',0.6); colorbar;
        if i==1
            title('Med - Con');
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%% Plot HEP waveforms and amplitude %%%%%%%%%%%%%%%%%%%
hepDataToReturn = cell(1,numGroups);
ampDataToReturn = cell(numGroups,numTimeWindows);
goodSubjectNameListsToReturn = cell(numGroups,2);

for i = 1:numGroups

    %%%%%%%%%%%%% Find bad subjects based on cutoff %%%%%%%%%%%%%
    badSubjectPosList = cell(1,2);
    for j = 1:2
        gData = hepData{j}(electrodeGroupList{i},:,:); % groupElecs x time x subjects
        numGoodElecs = length(electrodeGroupList{i}) - sum(isnan(squeeze(gData(:,1,:))),1);
        badSubjectPosList{j} = find(numGoodElecs<cutoffNumElectrodes);
    end

    meanHEPData  = cell(1,2);
    for j = 1:2
        gData = hepData{j}(electrodeGroupList{i},:,:);
        gData(:,:,badSubjectPosList{j}) = NaN;

        % average across electrodes within the group : numSubjects x numTimePoints
        meanHEPData{j} = squeeze(mean(gData,1,'omitnan'))';

        goodSubjectNameListTMP = goodSubjectNameLists{j};
        goodSubjectNameListTMP(badSubjectPosList{j}) = [];
        goodSubjectNameListsToReturn{i,j} = goodSubjectNameListTMP;

        if displayDataFlag
            text(timeLims(1)+0.05,yLimsHEP(2)-0.15*yLimsHEP(2)*j,[titleStr{j} '(' num2str(size(meanHEPData{j},1)) ')'],'color',displaySettings.colorNames(j,:),'parent',hHEP(i));
        end
    end

    hepDataToReturn{i} = meanHEPData;
    if displayDataFlag
        displayAndcompareData(hHEP(i),meanHEPData,xsHEP,displaySettings,yLimsHEP,1,useMedianFlag,~pairedDataFlag);
        title(hHEP(i),groupNameList{i});
        xlim(hHEP(i),timeLims);
        line([0 0],yLimsHEP,'color','k','linestyle','--','parent',hHEP(i)); % R-peak 
    end

    % Violin plots for mean HEP amplitude per time window
    for j = 1:numTimeWindows
        tmpAmp = cell(1,2);
        for k = 1:2
            tmpAmp{k} = mean(meanHEPData{k}(:,timePosList{j}),2,'omitnan');
        end

        ampDataToReturn{i,j} = tmpAmp;

        if displayDataFlag
            displaySettings.plotAxes = hAmp(j,i);
            if ~useMedianFlag
                displaySettings.parametricTest = 1;
                displaySettings.medianFlag = 0;
            else
                displaySettings.parametricTest = 0;
                displaySettings.medianFlag = 1;
            end

            if i==numGroups && j==1
                displaySettings.showYTicks=1;
                displaySettings.showXTicks=1;
            else
                displaySettings.showYTicks=0;
                displaySettings.showXTicks=0;
            end

            displayViolinPlot(tmpAmp,[{displaySettings.colorNames(1,:)} {displaySettings.colorNames(2,:)}],1,1,1,pairedDataFlag,displaySettings);

            if i==1
                ylabel(hAmp(j,i),['[' num2str(timeWindowList{j}(1)) '-' num2str(timeWindowList{j}(2)) ' s]'],'color',timeWindowColors(j,:));
            end

            % indicate time windows with verticle lines
            line([timeWindowList{j}(1) timeWindowList{j}(1)],yLimsHEP,'color',timeWindowColors(j,:),'parent',hHEP(i));
            line([timeWindowList{j}(2) timeWindowList{j}(2)],yLimsHEP,'color',timeWindowColors(j,:),'parent',hHEP(i));
        end
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function goodSubjectNameLists = getGoodSubjectNameListHEP(subjectNameLists,protocolName,manualStr,cutoffNumRPeaks,pairedDataFlag,hepSaveFolderName)

% For unpaired case, a subject is rejected if their data is missing or has
% too few R-peaks. For paired case, the whole pair is rejected if either
% subject is bad.

badSubjectIndex = cell(1,2);

for i = 1:2
    numSubjects = length(subjectNameLists{i});
    badSubjectIndexTMP = zeros(1,numSubjects);

    for j = 1:numSubjects
        subjectName = subjectNameLists{i}{j};
        saveFile = fullfile(hepSaveFolderName,[subjectName '_' protocolName manualStr '.mat']);

        if ~exist(saveFile,'file')
            disp(['File not found for subject: ' subjectName]);
            badSubjectIndexTMP(j) = 1;
        else
            tmpData = load(saveFile);
            if ~isfield(tmpData,'numRPeaks') || tmpData.numRPeaks < cutoffNumRPeaks
                disp(['Not enough R-peaks for subject: ' subjectName]);
                badSubjectIndexTMP(j) = 1;
            end
        end
    end
    badSubjectIndex{i} = badSubjectIndexTMP;
end

%%%%%%%%%%%%%%%%%%%%%%%%% Now find good subjects %%%%%%%%%%%%%%%%%%%%%%%%%%
goodSubjectNameLists = cell(1,2);

if ~pairedDataFlag
    for i = 1:2
        subjectNameListTMP = subjectNameLists{i};
        badPos = find(badSubjectIndex{i});
        subjectNameListTMP(badPos) = [];
        goodSubjectNameLists{i} = subjectNameListTMP;
    end
else
    badPos = find(sum(cell2mat(badSubjectIndex')));
    for i = 1:2
        subjectNameListTMP = subjectNameLists{i};
        subjectNameListTMP(badPos) = [];
        goodSubjectNameLists{i} = subjectNameListTMP;
    end
end
end

function [hepData,numRPeaksAll,xsHEP] = getHEPDataAllSubjects(subjectNameLists,protocolName,manualStr,hepSaveFolderName)

hepData = cell(1,2);
numRPeaksAll = cell(1,2);
xsHEP = [];

for i = 1:2
    hepDataTMP = [];
    numRPeaksTMP = [];

    for j = 1:length(subjectNameLists{i})
        subjectName = subjectNameLists{i}{j};
        saveFile = fullfile(hepSaveFolderName,[subjectName '_' protocolName manualStr '.mat']);

        tmpData = load(saveFile);
        xsHEP = tmpData.xsHEP; % identical across subjects/protocol

        hepDataTMP = cat(3,hepDataTMP,tmpData.hEP); % electrodes x time x subjects
        numRPeaksTMP = cat(1,numRPeaksTMP,tmpData.numRPeaks);
    end
    hepData{i} = hepDataTMP;
    numRPeaksAll{i} = numRPeaksTMP;
end
end