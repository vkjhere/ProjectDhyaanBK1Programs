% Analyze respiration data for a subject during a given protocol
% ======================================================
% Remove Octave/conflicting toolbox paths. Since this code uses 'findpeaks', remove chronux's findpeaks
rmpath(genpath('E:\OneDrive - Indian Institute of Science\NEOLAB vkj\programs\SoftwareMAP\eeglab12_0_2_5b\functions\octavefunc'));
rmpath(genpath('E:\OneDrive - Indian Institute of Science\NEOLAB vkj\programs\SoftwareMAP\chronux_2_00\chronux'));
rehash toolboxcache;

clear; clc; close all;

%% ================= Parameters =====================================

Fs = 1000;                         % sampling rate
protocolName = 'M1' ;
subjectName = '013AR';

%folderSourceString ='E:\OneDrive - Indian Institute of Science\VK Project Dhyaan';
folderSourceString = 'V:\Students\VinodKJ\VKProjectDhyaan\BK1';

[subjectNameList,expDateList] = getDemographicDetails('BK1');
subjectIdx = find(strcmpi(subjectNameList,subjectName));
exptDate = expDateList{subjectIdx};

respFile = fullfile(folderSourceString, 'data','segmentedDataLong',subjectName,'EEG',exptDate,protocolName,'segmentedData','LFP','elec69.mat');

saveFilteredDataFlag = 0; % save filtered resp signal and inst. phase for the given subject
% OR you can just run 'showAndSaveBasicRespDataGUI' for all subjects and
% all protocols
% Create 6 phase bins of resp signal: 0-60, 60-120, 120-180, 180-240, 240-300, 300-360 degrees
folderName = 'savedPhaseData_6bins' ;

saveFolder = fullfile(folderSourceString,'ProjectDhyaanBK1Programs-master\breathingprojectCodes', folderName);
saveFile = fullfile(saveFolder, [subjectName '_' protocolName '_filteredResp_and_phase.mat']);


highPassFreq = 0.05;               % Hz
lowPassFreq  = 2;                  % Hz

minPeakDistance = 1;               % sec
minProminence   = 0.25;            % z-score units

slideWinLength  = 30;               % sec : width of the moving-average
% window applied to the instantaneous (breath-to-breath) rate trace
gridFs          = 1;                % Hz : uniform time grid used only
% for smoothing/plotting the breath rate trace


%% ================= load breathing data ===========================================

load(respFile,'analogData');
respSignal = double(analogData(:));
N = length(respSignal);
timeVals = (0:N-1)/Fs;

fprintf('\n');
fprintf('Samples      : %d\n',N);
fprintf('Duration     : %.2f min\n',N/Fs/60);
fprintf('\n');

%% ================= filter ==============================================

[b,a] = butter(2,[highPassFreq lowPassFreq]/(Fs/2),'bandpass');

respFiltered = filtfilt(b,a,respSignal);

% z-score normalise
respFiltered = (respFiltered - mean(respFiltered)) ./ std(respFiltered);

%% ================= Instantaneous Phase (Hilbert Transform) ==============

% Compute analytic signal using Hilbert transform
analyticalSignal = hilbert(respFiltered);

% Extract instantaneous phase
instantPhase = angle(analyticalSignal);

% Convert from radians to degrees for easier interpretation
instantPhaseDeg = rad2deg(instantPhase);

%% ================= Phase Binning (6 bins) ==============================

% Create 6 phase bins: 0-60, 60-120, 120-180, 180-240, 240-300, 300-360 degrees
numPhaseBins = 6; % or 4 ; 
phaseBinEdges = linspace(-180, 180, numPhaseBins + 1);  % -180 to 180 in 6 bins
phaseBinLabels = cell(numPhaseBins, 1);
timeValsPhaseBinned = cell(numPhaseBins, 1);

for bin = 1:numPhaseBins
    % Define bin edges
    lowerEdge = phaseBinEdges(bin);
    upperEdge = phaseBinEdges(bin + 1);

    % Create label for this bin
    phaseBinLabels{bin} = sprintf('%.0f-%.0f deg', lowerEdge, upperEdge);

    % Find indices where phase falls in this bin
    if bin < numPhaseBins
        % For bins 1-5: include lower edge, exclude upper edge
        binMask = (instantPhaseDeg >= lowerEdge) & (instantPhaseDeg < upperEdge);
    else
        % For the last bin: include both edges to capture exactly 180 deg
        binMask = (instantPhaseDeg >= lowerEdge) & (instantPhaseDeg <= upperEdge);
    end

    % Collect timeVals for this bin
    timeValsPhaseBinned{bin} = timeVals(binMask);

    fprintf('Phase bin %d (%s): %d samples (%.2f%%)\n', bin, phaseBinLabels{bin}, ...
        sum(binMask), 100*sum(binMask)/length(timeVals));
end

%% ================= detecting peaks ========================================

[pks,peakLocs] = findpeaks(respFiltered,'MinPeakDistance',round(minPeakDistance*Fs),...
    'MinPeakProminence',minProminence);

[troughVals,troughLocs] = findpeaks(-respFiltered,'MinPeakDistance',round(minPeakDistance*Fs),...
    'MinPeakProminence',minProminence);

troughVals = -troughVals;

fprintf('Detected peaks   : %d\n',length(peakLocs));
fprintf('Detected troughs : %d\n',length(troughLocs));

%% ================= breath rate =========================================

IBI = diff(peakLocs)/Fs; % inter breath interval

meanIBI = mean(IBI);

breathRate_FromPeaks = 60/meanIBI; % ( in minutes : BPM : breaths per minute)

cvIBI = std(IBI)/meanIBI;

% Convert IBI to time (midpoint between consecutive peaks)
IBITime = (peakLocs(1:end-1) + peakLocs(2:end)) / 2 / Fs;

%% ================= breath depth ========================================

depthVals = [];

for i = 1:length(peakLocs)-1

    idx = find(troughLocs > peakLocs(i) & troughLocs < peakLocs(i+1), 1,'first');

    if ~isempty(idx)

        depthVals(end+1) = abs(respFiltered(peakLocs(i)) - respFiltered(troughLocs(idx)));

    end
end

breathDepth = mean(depthVals);

%% ================= Sliding window instantaneous rate (placed at the midpoint) ===================
% This is irregularly spaced in time (breath durations vary), so it is
% resampled onto a uniform grid before a fixed-DURATION moving-average
% window can be applied : this gives a smooth rate-over-time trace. 

instRate     = 60 ./ IBI;                                         % BPM, one value per breath interval
instRateTime = (peakLocs(1:end-1) + peakLocs(2:end)) / 2 / Fs;     % sec, midpoint of each interval

gridTime     = instRateTime(1) : 1/gridFs : instRateTime(end);
instRateGrid = interp1(instRateTime, instRate, gridTime, 'linear');

slideWinSamples = round(slideWinLength * gridFs);
slideRate       = movmean(instRateGrid, slideWinSamples, 'omitnan');

fprintf('Sliding rate (mean)  : %.2f BPM\n', mean(slideRate,'omitnan'));
fprintf('Sliding rate (range) : %.2f - %.2f BPM\n', min(slideRate), max(slideRate));

%% ================= RESULTS =======================================

fprintf('\n');
fprintf('--------------- RESULTS ------------------\n');
fprintf('Breath Rate (Peaks) : %.2f BPM\n',breathRate_FromPeaks);
fprintf('Mean IBI            : %.2f sec\n',meanIBI);
fprintf('CV(IBI)             : %.3f\n',cvIBI);
fprintf('Breath Depth        : %.3f\n',breathDepth);
fprintf('Sliding Rate Range  : %.2f - %.2f BPM\n',min(slideRate),max(slideRate));
fprintf('-------------------------------------------\n');

%% ================= FIGURE  ============================================

figure('Color','w','Position',[100 100 1400 1000]);
sgtitle([subjectName ' during ' protocolName]);

% Define common time axis limit
timeAxisLims = [0, max(timeVals)];

%% -----------------------------------------------------------------------

subplot(6,1,1)

plot(timeVals,respSignal,'k')

xlabel('Time (s)')
ylabel('Raw')
xlim(timeAxisLims);
title('Raw Respiration Signal')

%% -----------------------------------------------------------------------

subplot(6,1,2)

plot(timeVals,respFiltered,'b')

xlabel('Time (s)')
ylabel('Filtered')
xlim(timeAxisLims);
title('Filtered Respiration Signal')

%% -----------------------------------------------------------------------

subplot(6,1,3)

plot(timeVals, instantPhaseDeg, 'g', 'LineWidth', 1)

xlabel('Time (s)')
ylabel('Phase (deg)')
ylim([-180, 180])
xlim(timeAxisLims);
yticks([-180 -90 0 90 180])
title('Instantaneous Phase (Hilbert Transform)')
grid on

%% -----------------------------------------------------------------------

subplot(6,1,4)

plot(timeVals,respFiltered,'k')
hold on

plot(peakLocs/Fs,...
    respFiltered(peakLocs),'rv','MarkerFaceColor','r')

plot(troughLocs/Fs,...
    respFiltered(troughLocs),'bv','MarkerFaceColor','b')

xlabel('Time (s)')
ylabel('Respiration')
xlim(timeAxisLims);
title('Detected Peaks and Troughs')
legend({'Signal','Peaks','Troughs'})

%% -----------------------------------------------------------------------

subplot(6,1,5)

plot(IBITime, IBI, 'k.-','LineWidth',1.5,'MarkerSize',10)

xlabel('Time (s)')
ylabel('IBI (s)')
xlim(timeAxisLims);
title(sprintf('IBI (Mean = %.2f s, CV = %.3f)',meanIBI,cvIBI))

%% -----------------------------------------------------------------------

subplot(6,1,6)

plot(instRateTime, instRate, '.', 'Color',[0.7 0.7 0.7],'MarkerSize',10)
hold on
plot(gridTime, slideRate, 'm-', 'LineWidth',2)
yline(breathRate_FromPeaks,'k--','LineWidth',1)

xlabel('Time (s)')
ylabel('Rate (BPM)')
xlim(timeAxisLims);
title(sprintf('Sliding-Window Instantaneous Rate (%ds window, range %.1f-%.1f BPM)', ...
    slideWinLength, min(slideRate), max(slideRate)))

legend({'Breath-to-breath','Smoothed (sliding window)','Overall mean'}, ...
    'Location','best')

%% ================= SAVE FILTERED DATA AND PHASE ==========================

% Save filtered respiration, instantaneous phase, and phase-binned time values
if saveFilteredDataFlag
    if ~exist(saveFolder, 'dir')
        mkdir(saveFolder);
    end

    save(saveFile, 'respFiltered', 'instantPhase', 'instantPhaseDeg', 'timeVals', 'Fs', ...
        'protocolName', 'subjectName', 'timeValsPhaseBinned', 'phaseBinLabels', 'phaseBinEdges');

    fprintf('\n====== data saved ======\n');
    fprintf('File: %s\n\n', saveFile);
    fprintf('Variables saved:\n');
    fprintf('  - respFiltered: filtered respiration signal\n');
    fprintf('  - instantPhase: phase in radians\n');
    fprintf('  - instantPhaseDeg: phase in degrees\n');
    fprintf('  - timeVals: full time vector\n');
    fprintf('  - timeValsPhaseBinned: cell array (6x1) with timeVals for each phase bin\n');
    fprintf('  - phaseBinLabels: cell array with labels for each bin\n');
    fprintf('  - phaseBinEdges: edges of phase bins\n');
    fprintf('  - Fs: sampling frequency\n');
    fprintf('  - protocolName, subjectName: metadata\n');
    fprintf('\nPhase bins:\n');
    for bin = 1:numPhaseBins
        fprintf('  Bin %d: %s - %d timepoints\n', bin, phaseBinLabels{bin}, length(timeValsPhaseBinned{bin}));
    end


end