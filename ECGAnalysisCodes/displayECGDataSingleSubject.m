function displayECGDataSingleSubject(subjectName,expDate,folderSourceString)

if ~exist('folderSourceString','var'); folderSourceString=[]; end

if isempty(folderSourceString)
    folderSourceString = fileparts(fileparts(pwd));
end

protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M1a'} {'M1b'} {'M1c'} {'G2'} {'EO2'} {'EC2'} {'M2a'} {'M2b'} {'M2c'}];
colorNames = [{[0.9 0 0]} {[0 0.9 0]} {[0 0 0.9]} {[0.9 0.9 0.9]}  {[0.7 0.7 0.7]} {[0.5 0.5 0.5]} {[0 0 0.3]} {[0.3 0 0]} {[0 0.3 0]} {[0.3 0.3 0.3]} {[0.2 0.2 0.2]} {[0.1 0.1 0.1]}];
numProtocols = length(protocolNameList);

filteringInfo = filterECGData;

% Get plots
hECGPlots = getPlotHandles(numProtocols,1,[0.05 0.05 0.68 0.85],0.001,0.001,1);

hRRPlot = axes('Units','normalized','Position',[0.8 0.55 0.18 0.35]);
hRRPlotManual = axes('Units','normalized','Position',[0.8 0.1 0.18 0.35]);

% Get Data
allECGRaw = cell(1,numProtocols);
allTime   = cell(1,numProtocols);
Fs        = zeros(1,numProtocols);

allRPeakTimes = cell(1,numProtocols);
allRPeakTimesManual = cell(1,numProtocols);

for i = 1:numProtocols

    tmpFile = fullfile(folderSourceString,...
        'data','segmentedDataLong',subjectName,'EEG',expDate,...
        protocolNameList{i},'segmentedData','LFP','elec66.mat');

    if exist(tmpFile,'file')

        tmp = load(tmpFile);
        ecgData = tmp.analogData;

        tmp = load(fullfile(folderSourceString,...
            'data','segmentedDataLong',subjectName,'EEG',expDate,...
            protocolNameList{i},'segmentedData','LFP','lfpInfo.mat'));

        timeVals = tmp.timeVals;
        timeVals = timeVals - timeVals(1);

        allECGRaw{i} = ecgData;
        allTime{i}   = timeVals;
        Fs(i)        = 1/mean(diff(timeVals));

        % rrFile = fullfile(pwd,'savedData',subjectName,'EEG',expDate,protocolNameList{i},'segmentedData','LFP','Rpeaks.mat');
        rrFile = fullfile(pwd,'savedRRData',[subjectName '_' protocolNameList{i} '.mat']);

        if exist(rrFile,'file')
            tmpRR = load(rrFile);
            allRPeakTimes{i} = seconds(tmpRR.data.R_loc{1});
        else
            allRPeakTimes{i} = [];
        end

%        rrFileManual = fullfile(pwd,'savedData',subjectName,'EEG',expDate,protocolNameList{i},'segmentedData','LFP','Rpeaks_Manual.mat');
        rrFileManual = fullfile(pwd,'savedRRData',[subjectName '_' protocolNameList{i} '_Manual.mat']);

        if exist(rrFileManual,'file')
            tmpRR = load(rrFileManual);
            allRPeakTimesManual{i} = seconds(tmpRR.data.R_loc{1});
        else
            allRPeakTimesManual{i} = [];
        end

    else
        disp([tmpFile 'not found']);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show RR intervals
RRIntervals = cell(1,numProtocols);
RRIntervalsManual = cell(1,numProtocols);

yRRRange = [0 1.2];
for i=1:numProtocols
    tmpRR = allRPeakTimes{i};
    RRIntervals{i} = diff(tmpRR);
    tmpRR = allRPeakTimesManual{i};
    RRIntervalsManual{i} = diff(tmpRR);
end

displaySettings.xTickLabels = protocolNameList;

displaySettings.plotAxes = hRRPlot;
displayViolinPlot(RRIntervals,colorNames,1,1,0,0,displaySettings);
title(hRRPlot,'Automatic','Color','r');
ylabel(hRRPlot,'Duration (s)');
ylim(hRRPlot,yRRRange);

displaySettings.plotAxes = hRRPlotManual;
displayViolinPlot(RRIntervalsManual,colorNames,1,1,0,0,displaySettings);
title(hRRPlotManual,'Manual','Color','g');
ylabel(hRRPlotManual,'Duration (s)');
ylim(hRRPlotManual,yRRRange);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UI Controls
hShowPeaks = uicontrol(...
    'Style','checkbox',...
    'String','Show R Peaks',...
    'Value',1,...
    'Units','normalized',...
    'Position',[0.05 0.94 0.1 0.04],...
    'Callback',@applyFilter);

uicontrol('Style','text',...
    'String','HPF',...
    'Units','normalized',...
    'Position',[0.12 0.94 0.04 0.03]);

hHPF = uicontrol('Style','edit',...
    'String',num2str(filteringInfo.HPF),...
    'Units','normalized',...
    'Position',[0.16 0.94 0.06 0.04]);

uicontrol('Style','text',...
    'String','LPF',...
    'Units','normalized',...
    'Position',[0.22 0.94 0.04 0.03]);

if isinf(filteringInfo.LPF)
    lpstr = 'Inf';
else
    lpstr = num2str(filteringInfo.LPF);
end

hLPF = uicontrol('Style','edit',...
    'String',lpstr,...
    'Units','normalized',...
    'Position',[0.26 0.94 0.06 0.04]);

uicontrol('Style','pushbutton',...
    'String','Apply',...
    'Units','normalized',...
    'Position',[0.34 0.94 0.08 0.04],...
    'Callback',@applyFilter);

uicontrol('Style','pushbutton',...
    'String','Next 30s',...
    'Units','normalized',...
    'Position',[0.5 0.94 0.08 0.04],...
    'Callback',@(~,~) changeTimeRange(30));

uicontrol('Style','pushbutton',...
    'String','Prev 30s',...
    'Units','normalized',...
    'Position',[0.6 0.94 0.08 0.04],...
    'Callback',@(~,~) changeTimeRange(-30));

tRange = [0 30]; % Initialize time
allECGFiltered = allECGRaw; % Initialize EEG
applyFilter; % Applies default filter settings and plots

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CALLBACKS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function changeTimeRange(deltaT)
        tRange = tRange+deltaT;
        rescaleAxes(tRange);
    end

    function applyFilter(~,~)

        filteringInfo.HPF = str2double(hHPF.String);

        tmp = str2double(hLPF.String);

        if isnan(tmp)
            filteringInfo.LPF = Inf;
        else
            filteringInfo.LPF = tmp;
        end

        for kk = 1:numProtocols

            data = allECGRaw{kk};

            HPF = filteringInfo.HPF;
            LPF = filteringInfo.LPF;

            if ~filteringInfo.applyFilter

                out = data;

            elseif HPF==0 && isinf(LPF)

                out = data;

            elseif HPF>0 && isinf(LPF)

                [b,a] = butter(filteringInfo.filterOrder,...
                    HPF/(Fs(kk)/2),'high');

                out = filtfilt(b,a,double(data));

            elseif HPF==0 && isfinite(LPF)

                [b,a] = butter(filteringInfo.filterOrder,...
                    LPF/(Fs(kk)/2),'low');

                out = filtfilt(b,a,double(data));

            else

                [b,a] = butter(filteringInfo.filterOrder,...
                    [HPF LPF]/(Fs(kk)/2),'bandpass');

                out = filtfilt(b,a,double(data));

            end

            allECGFiltered{kk} = out;
        end

        redrawPlots;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REDRAW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function redrawPlots

        for k = 1:numProtocols

            out = allECGFiltered{k};
            t   = allTime{k};

            cla(hECGPlots(k));
            plot(hECGPlots(k),t,out,'color',colorNames{k});
            hold(hECGPlots(k),'on')

            if hShowPeaks.Value

                peakTimes = allRPeakTimes{k};
                [peakTimes,peakY] = getRRPeakVals(peakTimes,t,out);
                plot(hECGPlots(k),peakTimes,peakY,'ro','MarkerFaceColor','r','MarkerSize',5);

                peakTimesManual = allRPeakTimesManual{k};
                [peakTimesManual,peakYManual] = getRRPeakVals(peakTimesManual,t,out);
                plot(hECGPlots(k),peakTimesManual,peakYManual,'g*','MarkerFaceColor','g','MarkerSize',5);
            end

            hold(hECGPlots(k),'off')
            ylabel(hECGPlots(k),protocolNameList{k})
        end
        % Set initial axis limits for the plots
        rescaleAxes(tRange);
    end

    function rescaleAxes(xLims)
        % Rescale axes
        yLims = getYLims(hECGPlots);
        for k = 1:numProtocols
            axis(hECGPlots(k), [xLims yLims]);
            
            if k<numProtocols
                set(hECGPlots(k), 'XTickLabel',[],'YTickLabel',[]);
            else
                xlabel(hECGPlots(k),'Time (s)');
            end
        end
    end
end

function [peakTimes,peakY] = getRRPeakVals(peakTimes,t,out)

if ~isempty(peakTimes)

    peakY = zeros(size(peakTimes));

    for pp = 1:length(peakTimes)

        [~,idxTmp] = min(abs(t-peakTimes(pp)));
        peakY(pp) = out(idxTmp);
    end
end
end

function yLims = getYLims(plotHandles)

[numRows,numCols] = size(plotHandles);
% Initialize
yMin = inf;
yMax = -inf;

for row=1:numRows
    for column=1:numCols
        % get positions
        ylim(plotHandles(row,column),'tight');
        tmpAxisVals = axis(plotHandles(row,column));
        if tmpAxisVals(3) < yMin
            yMin = tmpAxisVals(3);
        end
        if tmpAxisVals(4) > yMax
            yMax = tmpAxisVals(4);
        end
    end
end

yLims=[yMin yMax];
end