% showAndSaveBasicRespDataGUI.m
% GUI to analyze basic respiration data and save files (filtered resp 0.05-2 Hz and instant phase signals) for:
% 1. a single subject during a given protocol 
% 2. a single subject during all protocols OR
% 3. all subjects during all protocols


function showAndSaveBasicRespDataGUI
%% Remove Octave/conflicting toolbox paths. Since this code uses 'findpeaks', remove chronux's findpeaks
rmpath(genpath('E:\OneDrive - Indian Institute of Science\NEOLAB vkj\programs\SoftwareMAP\eeglab12_0_2_5b\functions\octavefunc'));
rmpath(genpath('E:\OneDrive - Indian Institute of Science\NEOLAB vkj\programs\SoftwareMAP\chronux_2_00\chronux'));
rehash toolboxcache;

clear; clc; close all;

%% =================  Parameters =====================================

%folderSourceString = 'E:\OneDrive - Indian Institute of Science\VK Project Dhyaan';
folderSourceString = 'V:\Students\VinodKJ\VKProjectDhyaan\BK1';

% Get subject list
[allSubjectList, expDateList] = getDemographicDetails('BK1');

% Define available protocols
protocolList = {'EO1', 'EC1', 'G1', 'M1', 'G2', 'EC2', 'EO2', 'M2'};

% Analysis parameters (fixed)
Fs              = 1000;
highPassFreq    = 0.05;
lowPassFreq     = 2;
minPeakDistance = 1;
minProminence   = 0.25;
slideWinLength  = 30;
gridFs          = 1;

saveFilteredDataFlag = 0; % to save the files

%% ================= Create GUI ============================================

hFig = figure('Name', 'Respiration Analysis', 'NumberTitle', 'off', ...
    'Position', [400 250 520 510], 'Color', 'w', 'MenuBar', 'none', 'ToolBar', 'none');

% Title
uicontrol('Style', 'text', 'String', 'Respiration Signal Analysis', ...
    'Position', [50 460 420 35], 'FontSize', 14, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'BackgroundColor', 'w');

% Subject Name
uicontrol('Style', 'text', 'String', 'Subject Name:', ...
    'Position', [50 420 150 20], 'HorizontalAlignment', 'left', 'BackgroundColor', 'w');
hSubjectDropdown = uicontrol('Style', 'popupmenu', 'String', allSubjectList, ...
    'Position', [50 390 200 30], 'FontSize', 10, 'Value', 1);

% Protocol Name
uicontrol('Style', 'text', 'String', 'Protocol Name:', ...
    'Position', [50 355 150 20], 'HorizontalAlignment', 'left', 'BackgroundColor', 'w');
hProtocolDropdown = uicontrol('Style', 'popupmenu', 'String', protocolList, ...
    'Position', [50 325 200 30], 'FontSize', 10, 'Value', 1);

% --- Num Phase Bins ---
uicontrol('Style', 'text', 'String', 'Num Phase Bins:', ...
    'Position', [50 290 150 22], 'HorizontalAlignment', 'left', ...
    'BackgroundColor', 'w', 'FontSize', 10, 'FontWeight', 'bold');
hNumBinsEdit = uicontrol('Style', 'edit', 'String', '6', ...
    'Position', [200 290 60 26], 'FontSize', 11, 'FontWeight', 'bold', ...
    'BackgroundColor', [1 1 0.85], ...   % light yellow to stand out
    'TooltipString', 'Number of equal-width respiratory phase bins (e.g. 4 or 6)');

% Save folder label ... 4 or 6.. (dynamic)
uicontrol('Style', 'text', 'String', 'Save subfolder:', ...
    'Position', [50 258 120 20], 'HorizontalAlignment', 'left', 'BackgroundColor', 'w', 'FontSize', 9);
hSaveFolderLabel = uicontrol('Style', 'text', ...
    'String', getSaveFolderName(6), ...
    'Position', [170 255 320 22], 'HorizontalAlignment', 'left', ...
    'BackgroundColor', 'w', 'FontSize', 8, 'ForegroundColor', [0.2 0.2 0.7]);

% Update label when bins value changes
set(hNumBinsEdit, 'Callback', @(src,~) set(hSaveFolderLabel, 'String', ...
    getSaveFolderName(str2double(get(src,'String')))));

% Status Text Box
hStatusBox = uicontrol('Style', 'text', 'String', 'Ready', ...
    'Position', [50 20 420 145], 'HorizontalAlignment', 'left', ...
    'BackgroundColor', [0.95 0.95 0.95], 'FontSize', 8, ...
    'FontName', 'Courier New');

% --- Buttons ---
% Run Single Subject
uicontrol('Style', 'pushbutton', 'String', 'Run Single', ...
    'Position', [50 210 110 40], 'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2 0.6 0.2], 'ForegroundColor', 'w', ...
    'Callback', @runSingleSubject_Callback);

% All Subjects (selected protocol)
uicontrol('Style', 'pushbutton', 'String', 'All Subjects', ...
    'Position', [165 210 110 40], 'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2 0.2 0.6], 'ForegroundColor', 'w', ...
    'Callback', @runAllSubjects_Callback);

% All Subjects + All Protocols
uicontrol('Style', 'pushbutton', 'String', 'All Subj+Prot', ...
    'Position', [280 210 110 40], 'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.4 0.2 0.4], 'ForegroundColor', 'w', ...
    'Callback', @runAllSubjectsAllProtocols_Callback);

% Clear Plots
uicontrol('Style', 'pushbutton', 'String', 'Clear Plots', ...
    'Position', [395 210 90 40], 'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.6 0.2 0.2], 'ForegroundColor', 'w', ...
    'Callback', @clearPlots_Callback);

%% ================= build save folder name =======================

function name = getSaveFolderName(nBins)
    if isnan(nBins) || nBins < 2
        name = '(invalid nBins)';
    else
        name = sprintf('savedPhaseData_%dbins', round(nBins));
    end
end

function [nBins, saveFolder] = getNumBinsAndFolder()
    nBins = round(str2double(get(hNumBinsEdit, 'String')));
    if isnan(nBins) || nBins < 2
        error('Num Phase Bins must be an integer >= 2.');
    end
    folderName  = getSaveFolderName(nBins);
    saveFolder  = fullfile(folderSourceString, ...
        'ProjectDhyaanBK1Programs-master\breathingProjectCodes', folderName);
end

%% ================= Callback Functions ====================================

function runSingleSubject_Callback(~, ~)
    subjectIdx   = get(hSubjectDropdown,  'Value');
    subjectName  = allSubjectList{subjectIdx};
    protocolIdx  = get(hProtocolDropdown, 'Value');
    protocolName = protocolList{protocolIdx};

    try
        [nBins, saveFolder] = getNumBinsAndFolder();
        set(hStatusBox, 'String', sprintf('Processing %s - %s  (%d bins)...', ...
            subjectName, protocolName, nBins));
        drawnow;

        analyzeRespiration(subjectName, protocolName, folderSourceString, ...
            expDateList, Fs, highPassFreq, lowPassFreq, minPeakDistance, ...
            minProminence, slideWinLength, gridFs, nBins, ...
            saveFolder, saveFilteredDataFlag, true);

        set(hStatusBox, 'String', sprintf('COMPLETED: %s - %s  (%d bins)', ...
            subjectName, protocolName, nBins));
    catch ME
        set(hStatusBox, 'String', sprintf('ERROR: %s\n%s', subjectName, ME.message));
        fprintf('Error: %s\n', ME.message);
    end
end

function runAllSubjects_Callback(~, ~)
    protocolIdx  = get(hProtocolDropdown, 'Value');
    protocolName = protocolList{protocolIdx};
    numSubjects  = length(allSubjectList);

    try
        [nBins, saveFolder] = getNumBinsAndFolder();
    catch ME
        set(hStatusBox, 'String', ['ERROR: ' ME.message]); return;
    end

    set(hStatusBox, 'String', sprintf('Running %d subjects | %s | %d bins...\nPlease wait...', ...
        numSubjects, protocolName, nBins));
    drawnow;

    successCount = 0; failureCount = 0; failedSubjects = {};

    for subIdx = 1:numSubjects
        subjectName = allSubjectList{subIdx};
        try
            analyzeRespiration(subjectName, protocolName, folderSourceString, ...
                expDateList, Fs, highPassFreq, lowPassFreq, minPeakDistance, ...
                minProminence, slideWinLength, gridFs, nBins, ...
                saveFolder, saveFilteredDataFlag, false);
            successCount = successCount + 1;
            fprintf('✓ [%d/%d] %s\n', subIdx, numSubjects, subjectName);
        catch ME
            failureCount = failureCount + 1;
            failedSubjects{end+1} = sprintf('%s (%s)', subjectName, ME.message); %#ok<AGROW>
            fprintf('✗ [%d/%d] %s — %s\n', subIdx, numSubjects, subjectName, ME.message);
        end
    end

    delete(findobj('Type','figure','-not','Name','Respiration Analysis'));
    set(hStatusBox, 'String', buildSummary(protocolName, nBins, successCount, numSubjects, failureCount, failedSubjects));
    fprintf('\n=== BATCH COMPLETE (%s, %d bins) ===\nSuccess: %d/%d | Failed: %d\n\n', ...
        protocolName, nBins, successCount, numSubjects, failureCount);
end

function runAllSubjectsAllProtocols_Callback(~, ~)
    numSubjects  = length(allSubjectList);
    numProtocols = length(protocolList);
    totalRuns    = numSubjects * numProtocols;

    try
        [nBins, saveFolder] = getNumBinsAndFolder();
    catch ME
        set(hStatusBox, 'String', ['ERROR: ' ME.message]); return;
    end

    set(hStatusBox, 'String', sprintf('Running %d subjects × %d protocols | %d bins...\n%d total runs — please wait...', ...
        numSubjects, numProtocols, nBins, totalRuns));
    drawnow;

    successCount = 0; failureCount = 0; failedRuns = {};
    runCounter   = 0;

    for subIdx = 1:numSubjects
        subjectName = allSubjectList{subIdx};
        for protIdx = 1:numProtocols
            protocolName = protocolList{protIdx};
            runCounter   = runCounter + 1;
            try
                analyzeRespiration(subjectName, protocolName, folderSourceString, ...
                    expDateList, Fs, highPassFreq, lowPassFreq, minPeakDistance, ...
                    minProminence, slideWinLength, gridFs, nBins, ...
                    saveFolder, saveFilteredDataFlag, false);
                successCount = successCount + 1;
                fprintf('✓ [%d/%d] %s | %s\n', runCounter, totalRuns, subjectName, protocolName);
            catch ME
                failureCount = failureCount + 1;
                failedRuns{end+1} = sprintf('%s|%s: %s', subjectName, protocolName, ME.message); %#ok<AGROW>
                fprintf('✗ [%d/%d] %s | %s — %s\n', runCounter, totalRuns, subjectName, protocolName, ME.message);
            end
        end
    end

    delete(findobj('Type','figure','-not','Name','Respiration Analysis'));
    set(hStatusBox, 'String', buildSummary('ALL PROTOCOLS', nBins, successCount, totalRuns, failureCount, failedRuns));
    fprintf('\n=== FULL BATCH COMPLETE (%d bins) ===\nSuccess: %d/%d | Failed: %d\n\n', ...
        nBins, successCount, totalRuns, failureCount);
end

function clearPlots_Callback(~, ~)
    delete(findobj('Type','figure','-not','Name','Respiration Analysis'));
end

%% ================= Summary stringg ================================

function msg = buildSummary(label, nBins, successCount, totalRuns, failureCount, failedList)
    msg = sprintf('%s | %d bins\nSuccess: %d/%d  |  Failed: %d', ...
        label, nBins, successCount, totalRuns, failureCount);
    if failureCount > 0
        msg = [msg, sprintf('\n\nFailed (%d):\n', failureCount)];
        for i = 1:min(3, length(failedList))
            msg = [msg, failedList{i}, newline]; %#ok<AGROW>
        end
        if failureCount > 3
            msg = [msg, sprintf('... and %d more (see Command Window)', failureCount-3)];
        end
    end
end

%% ================= Main Analysis Function ================================

end  % analyseRespDataForSingleSubject_GUI

function analyzeRespiration(subjectName, protocolName, folderSourceString, ...
    expDateList, Fs, highPassFreq, lowPassFreq, minPeakDistance, ...
    minProminence, slideWinLength, gridFs, numPhaseBins, ...
    saveFolder, saveFilteredDataFlag, showFigure)

if nargin < 15; showFigure = false; end

% Get experiment date
[subjectNameList, ~] = getDemographicDetails('BK1');
subjectIdx = find(strcmpi(subjectNameList, subjectName));
if isempty(subjectIdx)
    error('Subject %s not found in demographic details.', subjectName);
end
exptDate = expDateList{subjectIdx};

respFile = fullfile(folderSourceString, 'data', 'segmentedDataLong', ...
    subjectName, 'EEG', exptDate, protocolName, 'segmentedData', 'LFP', 'elec69.mat');
if ~exist(respFile, 'file')
    error('File not found: %s', respFile);
end

%% Load
load(respFile, 'analogData');
respSignal = double(analogData(:));
N          = length(respSignal);
timeVals   = (0:N-1) / Fs;
fprintf('\n=== %s | %s ===\nSamples: %d | Duration: %.2f min\n', ...
    subjectName, protocolName, N, N/Fs/60);

%% Filter + z-score
[b, a]       = butter(2, [highPassFreq lowPassFreq]/(Fs/2), 'bandpass');
respFiltered = filtfilt(b, a, respSignal);
respFiltered = (respFiltered - mean(respFiltered)) / std(respFiltered);

%% Instantaneous phase (Hilbert)
analyticalSignal = hilbert(respFiltered);
instantPhase     = angle(analyticalSignal);
instantPhaseDeg  = rad2deg(instantPhase);

%% Phase binning — uses numPhaseBins from argument
phaseBinEdges       = linspace(-180, 180, numPhaseBins + 1);
phaseBinLabels      = cell(numPhaseBins, 1);
timeValsPhaseBinned = cell(numPhaseBins, 1);

for bin = 1:numPhaseBins
    lo = phaseBinEdges(bin);
    hi = phaseBinEdges(bin + 1);
    phaseBinLabels{bin} = sprintf('%.0f-%.0f deg', lo, hi);
    if bin < numPhaseBins
        binMask = (instantPhaseDeg >= lo) & (instantPhaseDeg < hi);
    else
        binMask = (instantPhaseDeg >= lo) & (instantPhaseDeg <= hi);
    end
    timeValsPhaseBinned{bin} = timeVals(binMask);
    fprintf('  Bin %d (%s): %d samples (%.1f%%)\n', bin, phaseBinLabels{bin}, ...
        sum(binMask), 100*sum(binMask)/N);
end

%% Peak / trough detection
[~, peakLocs]       = findpeaks(respFiltered, ...
    'MinPeakDistance',  round(minPeakDistance*Fs), ...
    'MinPeakProminence', minProminence);
[troughValsNeg, troughLocs] = findpeaks(-respFiltered, ...
    'MinPeakDistance',  round(minPeakDistance*Fs), ...
    'MinPeakProminence', minProminence);
troughVals = -troughValsNeg;

%% Breath rate & depth
IBI      = diff(peakLocs) / Fs;
meanIBI  = mean(IBI);
breathRate_FromPeaks = 60 / meanIBI;
cvIBI    = std(IBI) / meanIBI;
IBITime  = (peakLocs(1:end-1) + peakLocs(2:end)) / 2 / Fs;

depthVals = [];
for i = 1:length(peakLocs)-1
    idx = find(troughLocs > peakLocs(i) & troughLocs < peakLocs(i+1), 1, 'first');
    if ~isempty(idx)
        depthVals(end+1) = abs(respFiltered(peakLocs(i)) - respFiltered(troughLocs(idx))); %#ok<AGROW>
    end
end
breathDepth = mean(depthVals);

%% Sliding window rate
instRate     = 60 ./ IBI;
instRateTime = IBITime;
gridTime     = instRateTime(1) : 1/gridFs : instRateTime(end);
instRateGrid = interp1(instRateTime, instRate, gridTime, 'linear');
slideRate    = movmean(instRateGrid, round(slideWinLength*gridFs), 'omitnan');

fprintf('Breath rate: %.2f BPM | IBI: %.2f s | CV: %.3f | Depth: %.3f\n', ...
    breathRate_FromPeaks, meanIBI, cvIBI, breathDepth);

%% Save
if saveFilteredDataFlag
    if ~exist(saveFolder, 'dir')
        [ok, msg] = mkdir(saveFolder);
        if ~ok; error('Cannot create folder: %s', msg); end
    end
    saveFile = fullfile(saveFolder, [subjectName '_' protocolName '_filteredResp_and_phase.mat']);
    save(saveFile, 'respFiltered', 'instantPhase', 'instantPhaseDeg', 'timeVals', ...
        'Fs', 'protocolName', 'subjectName', 'numPhaseBins', ...
        'timeValsPhaseBinned', 'phaseBinLabels', 'phaseBinEdges');
    fprintf('Saved: %s\n', saveFile);
end

%% Diagnostic figure
if showFigure
    timeAxisLims = [0, max(timeVals)];
    hf = figure('Color','w','Position',[100 50 1400 950], ...
        'Name', sprintf('%s | %s | %d bins', subjectName, protocolName, numPhaseBins), ...
        'WindowState','maximized');
    sgtitle(sprintf('%s  |  %s  |  %d phase bins', subjectName, protocolName, numPhaseBins), ...
        'FontSize', 14, 'FontWeight','bold');

    subplot(6,1,1);
    plot(timeVals, respSignal, 'k','LineWidth',0.8); xlim(timeAxisLims);
    ylabel('Raw'); title('Raw Respiration Signal'); grid on;

    subplot(6,1,2);
    plot(timeVals, respFiltered, 'b','LineWidth',0.8); hold on;
    plot(peakLocs/Fs, respFiltered(peakLocs), 'rv','MarkerFaceColor','r','MarkerSize',5);
    plot(troughLocs/Fs, respFiltered(troughLocs), 'bv','MarkerFaceColor','b','MarkerSize',5);
    xlim(timeAxisLims); ylabel('Filtered');
    title(sprintf('Filtered  (%.1f BPM)', breathRate_FromPeaks)); grid on;

    subplot(6,1,3);
    plot(timeVals, instantPhaseDeg, 'g','LineWidth',0.8);
    xlim(timeAxisLims); ylim([-180 180]); yticks([-180 -90 0 90 180]);
    ylabel('Phase (°)'); title('Instantaneous Phase'); grid on;

    subplot(6,1,4);
    cols = lines(numPhaseBins);
    hold on;
    for bin = 1:numPhaseBins
        lo = phaseBinEdges(bin); hi = phaseBinEdges(bin+1);
        if bin < numPhaseBins
            mask = (instantPhaseDeg >= lo) & (instantPhaseDeg < hi);
        else
            mask = (instantPhaseDeg >= lo) & (instantPhaseDeg <= hi);
        end
        plot(timeVals(mask), instantPhaseDeg(mask), '.', 'Color', cols(bin,:), 'MarkerSize', 2);
    end
    xlim(timeAxisLims); ylim([-180 180]); yticks([-180 -90 0 90 180]);
    ylabel('Phase (°)'); title(sprintf('Phase by bin (%d bins)', numPhaseBins)); grid on;

    subplot(6,1,5);
    plot(IBITime, IBI, 'k.-','LineWidth',1.2,'MarkerSize',8); xlim(timeAxisLims);
    ylabel('IBI (s)'); title(sprintf('IBI  (mean=%.2f s, CV=%.3f)', meanIBI, cvIBI)); grid on;

    subplot(6,1,6);
    plot(instRateTime, instRate, '.','Color',[0.7 0.7 0.7],'MarkerSize',8); hold on;
    plot(gridTime, slideRate, 'm-','LineWidth',2);
    yline(breathRate_FromPeaks,'k--','LineWidth',1);
    xlim(timeAxisLims); ylabel('Rate (BPM)');
    title(sprintf('Sliding rate (%ds window, %.1f–%.1f BPM)', ...
        slideWinLength, min(slideRate), max(slideRate)));
    legend({'Breath-to-breath','Smoothed','Mean'},'Location','best'); grid on;
end

end  % analyze respirationn