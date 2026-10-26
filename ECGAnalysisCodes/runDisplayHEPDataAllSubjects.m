% GUI for displaying Heart Evoked Potential (HEP) data

function runDisplayHEPDataAllSubjects

fontSizeSmall = 10; fontSizeMedium = 12; fontSizeLarge = 16;
backgroundColor = 'w'; panelHeight = 0.125;
colormap jet

%%%%%%%%%%%%%%%%%%%%%%%%%%% Subject Choices %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel1 = uipanel('Title','Subjects','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.025 1-panelHeight 0.15 panelHeight]);

% Comparison - paired or unpaired
uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 2/3 0.5 1/3],'Style','text','String','Comparison','FontSize',fontSizeSmall);
comparisonList = [{'paired'} {'unpaired'}];
hComparison = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 2/3 0.5 1/3],'Style','popup','String',comparisonList,'FontSize',fontSizeSmall);

% Gender - all, male, female
uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 1/3 0.5 1/3],'Style','text','String','Gender','FontSize',fontSizeSmall);
genderList = [{'all'} {'male'} {'female'}];
hGender = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 1/3 0.5 1/3],'Style','popup','String',genderList,'FontSize',fontSizeSmall);

% Age - all, young, mid
uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 0 0.5 1/3],'Style','text','String','Age','FontSize',fontSizeSmall);
ageList = [{'all'} {'young'} {'mid'}];
hAge = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 0 0.5 1/3],'Style','popup','String',ageList,'FontSize',fontSizeSmall);

%%%%%%%%%%%%%%%%%%%%%%%% Protocol Details %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel2 = uipanel('Title','Protocol','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.175 1-panelHeight 0.15 panelHeight]);

% Protocol - matches the protocol list used in getHEPs.m
uicontrol('Parent',hPanel2,'Unit','Normalized','Position',[0 2/3 0.5 1/3],'Style','text','String','ProtocolName','FontSize',fontSizeSmall);
protocolNameList = {'M1a','M1b','M1c','M2a','M2b','M2c','G1','G2','EO1','EO2','EC1','EC2'};
hProtocol = uicontrol('Parent',hPanel2,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 2/3 0.5 1/3],'Style','popup','String',protocolNameList,'FontSize',fontSizeSmall);

% ManualStr - matches the manualStr suffix used when saving in getHEPs.m
uicontrol('Parent',hPanel2,'Unit','Normalized','Position',[0 1/3 0.5 1/3],'Style','text','String','R-peak Detection','FontSize',fontSizeSmall);
manualStrList1 = [{'Manual'} {'Automatic'}];
manualStrList2 = [{'_Manual'} {''}];
hManualStr = uicontrol('Parent',hPanel2,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 1/3 0.5 1/3],'Style','popup','String',manualStrList1,'FontSize',fontSizeSmall);


%%%%%%%%%%%%%%%%%%%%%%%%%%% Time Windows %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel4 = uipanel('Title','Time Windows (s)','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.325 1-panelHeight 0.15 panelHeight]);
timeWindowList0{1} = [0.200 0.300];
timeWindowList0{2} = [0.350 0.450];
timeWindowList0{3} = [0.455 0.600];

numTimeWindows = length(timeWindowList0);
hTimeWindowMin = cell(1,numTimeWindows);
hTimeWindowMax = cell(1,numTimeWindows);

for i=1:numTimeWindows
    uicontrol('Parent',hPanel4,'Unit','Normalized','Position',[0 1-i/numTimeWindows 0.5 1/numTimeWindows],'Style','text','String',['Window' num2str(i)],'FontSize',fontSizeSmall);
    hTimeWindowMin{i} = uicontrol('Parent',hPanel4,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.5 1-i/numTimeWindows 0.25 1/numTimeWindows], ...
        'Style','edit','String',num2str(timeWindowList0{i}(1)),'FontSize',fontSizeSmall);
    hTimeWindowMax{i} = uicontrol('Parent',hPanel4,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.75 1-i/numTimeWindows 0.25 1/numTimeWindows], ...
        'Style','edit','String',num2str(timeWindowList0{i}(2)),'FontSize',fontSizeSmall);
end

%%%%%%%%%%%%%%%%%%%%%%%%% Axis Ranges %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel5 = uipanel('Title','Axis Ranges','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.475 1-panelHeight 0.15 panelHeight]);
axisRangeList0{1} = [-0.2 1];  axisRangeName{1} = 'Time Lims (s)';
axisRangeList0{2} = [-5 10];  axisRangeName{2} = 'YLims (\muV)';
axisRangeList0{3} = [-4 3];    axisRangeName{3} = 'cLims (topo)';

numAxisRanges = length(axisRangeList0);
hAxisRangeMin = cell(1,numAxisRanges);
hAxisRangeMax = cell(1,numAxisRanges);

for i=1:numAxisRanges
    uicontrol('Parent',hPanel5,'Unit','Normalized','Position',[0 1-i/numAxisRanges 0.5 1/numAxisRanges],'Style','text','String',axisRangeName{i},'FontSize',fontSizeSmall);
    hAxisRangeMin{i} = uicontrol('Parent',hPanel5,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.5 1-i/numAxisRanges 0.25 1/numAxisRanges], ...
        'Style','edit','String',num2str(axisRangeList0{i}(1)),'FontSize',fontSizeSmall);
    hAxisRangeMax{i} = uicontrol('Parent',hPanel5,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.75 1-i/numAxisRanges 0.25 1/numAxisRanges], ...
        'Style','edit','String',num2str(axisRangeList0{i}(2)),'FontSize',fontSizeSmall);
end

%%%%%%%%%%%%%%%%%%%%%%%%% Cutoff Choices %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel6 = uipanel('Title','Cutoffs','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.625 1-panelHeight 0.15 panelHeight]);
cutoffList0 = [3 200]; cutoffNames = [{'Num Elecs'} {'Num RPeaks'}];

numCutoffRanges = length(cutoffList0);
hCutoffs = cell(1,numCutoffRanges);

for i=1:numCutoffRanges
    uicontrol('Parent',hPanel6,'Unit','Normalized','Position',[0 1-i/numCutoffRanges 0.5 1/numCutoffRanges],'Style','text','String',cutoffNames{i},'FontSize',fontSizeSmall);
    hCutoffs{i} = uicontrol('Parent',hPanel6,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.5 1-i/numCutoffRanges 0.5 1/numCutoffRanges], ...
        'Style','edit','String',num2str(cutoffList0(i)),'FontSize',fontSizeSmall);
end

%%%%%%%%%%%%%%%%%%%%%%%%% Plot Choices %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel7 = uipanel('Title','Plot','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.775 1-panelHeight 0.2 panelHeight]);

hUseMedianFlag = uicontrol('Parent',hPanel7,'Unit','Normalized','Position',[0 2/3 1 1/3],'Style','togglebutton','String','Use Median','FontSize',fontSizeMedium);
uicontrol('Parent',hPanel7,'Unit','Normalized','Position',[0 1/3 0.5 1/3],'Style','pushbutton','String','Rescale','FontSize',fontSizeMedium,'Callback',{@rescale_Callback});
uicontrol('Parent',hPanel7,'Unit','Normalized','Position',[0.5 1/3 0.5 1/3],'Style','pushbutton','String','Clear','FontSize',fontSizeMedium,'Callback',{@cla_Callback});
uicontrol('Parent',hPanel7,'Unit','Normalized','Position',[0 0 1 1/3],'Style','pushbutton','String','plot','FontSize',fontSizeMedium,'Callback',{@plot_Callback});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5 default ECG/HEP electrode groups (see getElectrodeGroups.m, analysisType='ecg')
electrodeGroupList = getElectrodeGroups('EEG','actiCap64_UOL',[],'ecg');
numGroups = length(electrodeGroupList);
hAllPlots.hHEP   = getPlotHandles(1,numGroups,[0.05 0.55 0.6 0.3],0.02,0.02,1);
hAllPlots.hAmp   = getPlotHandles(numTimeWindows,numGroups,[0.05 0.05 0.6 0.45],0.02,0.02,0);
hAllPlots.hTopo0 = getPlotHandles(1,2,[0.66 0.55 0.3 0.30],0.01,0.01,1);
hAllPlots.hTopo2 = getPlotHandles(numTimeWindows,3,[0.66 0.02 0.3 0.50],0.02,0.02,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot_Callback(~,~)

        %%%%%%%%%%%%%%%%%%%%% Get SubjectLists %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        comparisonStr=comparisonList{get(hComparison,'val')};
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

        % Sub-select Subjects based on Demographics
        [subjectNameList,~,~,ageListAllSub,genderListAllSub] = getDemographicDetails('BK1');
        % sub-select based on Gender
        genderStr=genderList{get(hGender,'Value')};
        maleSubjectNameList = subjectNameList(strcmpi(genderListAllSub, 'M'));
        femaleSubjectNameList = subjectNameList(strcmpi(genderListAllSub, 'F'));
        if  strcmp(genderStr,'male')
            subjectNameLists{1} = intersect(subjectNameLists{1},maleSubjectNameList,'stable');
            subjectNameLists{2} = intersect(subjectNameLists{2},maleSubjectNameList,'stable');
        elseif strcmp(genderStr,'female')
            subjectNameLists{1} = intersect(subjectNameLists{1},femaleSubjectNameList,'stable');
            subjectNameLists{2} = intersect(subjectNameLists{2},femaleSubjectNameList,'stable');
        end

        % sub-select based on Age
        ageStr=ageList{get(hAge,'Value')};
        youngSubjectNameList = subjectNameList(ageListAllSub<40);
        midSubjectNameList = subjectNameList(ageListAllSub>=40);

        if  strcmp(ageStr,'young')
            subjectNameLists{1} = intersect(subjectNameLists{1},youngSubjectNameList,'stable');
            subjectNameLists{2} = intersect(subjectNameLists{2},youngSubjectNameList,'stable');
        elseif strcmp(ageStr,'mid')
            subjectNameLists{1} = intersect(subjectNameLists{1},midSubjectNameList,'stable');
            subjectNameLists{2} = intersect(subjectNameLists{2},midSubjectNameList,'stable');
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        protocolName = protocolNameList{get(hProtocol,'val')};
        manualStr = manualStrList2{get(hManualStr,'val')};

        timeWindowList = cell(1,numTimeWindows);
        for ii=1:numTimeWindows
            timeWindowList{ii} = [str2double(get(hTimeWindowMin{ii},'String')) str2double(get(hTimeWindowMax{ii},'String'))];
        end

        axisRangeList = cell(1,numAxisRanges);
        for ii=1:numAxisRanges
            axisRangeList{ii} = [str2double(get(hAxisRangeMin{ii},'String')) str2double(get(hAxisRangeMax{ii},'String'))];
        end

        cutoffList = zeros(1,numCutoffRanges);
        for ii=1:numCutoffRanges
            cutoffList(ii) = str2double(get(hCutoffs{ii},'String'));
        end

        useMedianFlag = get(hUseMedianFlag,'val');

        displayHEPDataAllSubjects(subjectNameLists,protocolName,manualStr,timeWindowList,axisRangeList,cutoffList,useMedianFlag,hAllPlots,pairedDataFlag);
    end
    function cla_Callback(~,~)
        claGivenPlotHandle(hAllPlots.hHEP);
        claGivenPlotHandle(hAllPlots.hAmp);
        claGivenPlotHandle(hAllPlots.hTopo0);
        claGivenPlotHandle(hAllPlots.hTopo2);

        function claGivenPlotHandle(plotHandles)
            [numRows,numCols] = size(plotHandles);
            for ii=1:numRows
                for j=1:numCols
                    cla(plotHandles(ii,j));
                end
            end
        end
    end
    function rescale_Callback(~,~)
        axisLims = [str2double(get(hAxisRangeMin{1},'String')) str2double(get(hAxisRangeMax{1},'String')) str2double(get(hAxisRangeMin{2},'String')) str2double(get(hAxisRangeMax{2},'String'))];
        cLims = [str2double(get(hAxisRangeMin{3},'String')) str2double(get(hAxisRangeMax{3},'String'))];

        rescaleGivenPlotHandle(hAllPlots.hHEP,axisLims);
        rescaleZGivenPlotHandle(hAllPlots.hTopo2,cLims);

        function rescaleGivenPlotHandle(plotHandles,axisLims)
            [numRows,numCols] = size(plotHandles);
            for ii=1:numRows
                for j=1:numCols
                    axis(plotHandles(ii,j),axisLims);
                end
            end
        end
        function rescaleZGivenPlotHandle(plotHandles,cLims)
            [numRows,numCols] = size(plotHandles);
            for ii=1:numRows
                for j=1:numCols
                    clim(plotHandles(ii,j),cLims);
                end
            end
        end
    end

end


