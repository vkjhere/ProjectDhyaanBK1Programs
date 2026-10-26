% Analyze respiration data for all subjects in each group, called by
% runDisplayRespDataAllSubjects

function [respMetrics, statsResults] = displayRespDataAllSubjects(subjectNameLists, protocolName,...
    highPassFreq, lowPassFreq, minPeakDist, minProminence, pairedDataFlag, centralTendency)

% ======================================================
% % Remove Octave/conflicting toolbox paths. Since this code uses 'findpeaks', remove chronux's findpeaks
% rmpath(genpath('E:\OneDrive - Indian Institute of Science\NEOLAB vkj\programs\SoftwareMAP\eeglab12_0_2_5b\functions\octavefunc'));
% rmpath(genpath('E:\OneDrive - Indian Institute of Science\NEOLAB vkj\programs\SoftwareMAP\chronux_2_00\chronux'));
% rehash toolboxcache;

%folderSourceString = 'E:\OneDrive - Indian Institute of Science\VK Project Dhyaan';
folderSourceString = 'V:\Students\VinodKJ\VKProjectDhyaan\BK1';

if ~exist('pairedDataFlag','var')
    pairedDataFlag = 0;
end

if ~exist('centralTendency','var')
    centralTendency = 'median'; % 'median' or 'mean'
end

% Get demographic info
[allSubjectNames, expDateList] = getDemographicDetails('BK1');

Fs = 1000; % Sampling rate
minPeaksRequired = 8; % need at least 8 breaths for stable CV

% Initialize
respMetrics = struct();
respMetrics(1).breathRate = [];
respMetrics(1).cvIBI = [];
respMetrics(1).breathDepth = [];

respMetrics(2).breathRate = [];
respMetrics(2).cvIBI = [];
respMetrics(2).breathDepth = [];

groupNames = {'Meditators', 'Controls'};

fprintf('\n --- ANALYZING %s ----- \n', protocolName);

% Analyze each group
for groupIdx = 1:2
    
    subjectList = subjectNameLists{groupIdx};
    numSubjects = length(subjectList);
    
    fprintf('\nProcessing %s (n=%d)...\n', groupNames{groupIdx}, numSubjects);
    
    respMetrics(groupIdx).breathRate  = nan(1, numSubjects);
    respMetrics(groupIdx).cvIBI       = nan(1, numSubjects);
    respMetrics(groupIdx).breathDepth = nan(1, numSubjects);
    
    validCount = 0;
    
    for subIdx = 1:numSubjects
        
        subjectName = subjectList{subIdx};
        
        % Get experiment date
        subjIdx = find(strcmpi(allSubjectNames, subjectName));
        if isempty(subjIdx)
            warning(['Subject ' subjectName ' not found']);
            continue;
        end
        exptDate = expDateList{subjIdx};
        
        % Load data
        respSignal = loadRespData(folderSourceString, subjectName, exptDate, protocolName);
        
        if isempty(respSignal)
            continue;
        end
        
        % Preprocess
        respFiltered = preprocessRespSignal(respSignal, highPassFreq, lowPassFreq, Fs);
        
        % Detect peaks and troughs
        [peakLocs, troughLocs] = detectPeaksAndTroughs(respFiltered, minPeakDist, minProminence, Fs, subjectName);
        
        % Irequire at least 8 peaks for stable CV estimate
        if length(peakLocs) < minPeaksRequired
            fprintf('  %s: SKIPPED (only %d peaks detected, need >= %d)\n', subjectName, length(peakLocs), minPeaksRequired);
            continue;
        end
        
        % Compute metrics
        [breathRate, cvIBI, breathDepth] = computeMetrics(respFiltered, peakLocs, troughLocs, Fs);
        
        % Store at the subject's own index (NOT end+1) to preserve pairing
        respMetrics(groupIdx).breathRate(subIdx)  = breathRate;
        respMetrics(groupIdx).cvIBI(subIdx)       = cvIBI;
        respMetrics(groupIdx).breathDepth(subIdx) = breathDepth;
        
        validCount = validCount + 1;
        fprintf('  %s: BR=%.1f, CV=%.3f, Depth=%.3f\n', subjectName, breathRate, cvIBI, breathDepth);
        
    end
    
    fprintf('  Valid subjects: %d/%d\n', validCount, numSubjects);
    
end

% Statistical comparison
fprintf('\n========== STATISTICS (%s) ==========\n', upper(centralTendency));
statsResults = performStatisticalTests(respMetrics, pairedDataFlag, centralTendency);

end

% =====================================================================

function respSignal = loadRespData(folderSourceString, subjectName, exptDate, protocolName)

respSignal = [];
respFile = fullfile(folderSourceString, 'data','segmentedDataLong',subjectName,'EEG',exptDate,protocolName,'segmentedData','LFP','elec69.mat');

if exist(respFile, 'file')
    try
        load(respFile, 'analogData');
        respSignal = double(analogData(:));
    catch
        warning(['Failed to load ' subjectName ' - ' protocolName]);
    end
end

end

function respFiltered = preprocessRespSignal(respSignal, highPassFreq, lowPassFreq, Fs)

[b,a] = butter(2, [highPassFreq lowPassFreq]/(Fs/2), 'bandpass');
respFiltered = filtfilt(b, a, respSignal);
respFiltered = (respFiltered - mean(respFiltered)) / std(respFiltered);

end

function [peakLocs, troughLocs] = detectPeaksAndTroughs(respSignal, minPeakDist, minProminence, Fs, subjectName)

try
    [~, peakLocs] = findpeaks(respSignal, 'MinPeakDistance', round(minPeakDist*Fs),...
        'MinPeakProminence', minProminence);
    [~, troughLocs] = findpeaks(-respSignal, 'MinPeakDistance', round(minPeakDist*Fs),...
        'MinPeakProminence', minProminence);
catch ME
    % Fallback with warning if prominence-based detection fails
    warning(['Subject ' subjectName ': MinPeakProminence dropped due to error: ' ME.message]);
    [~, peakLocs] = findpeaks(respSignal, 'MinPeakDistance', round(minPeakDist*Fs));
    [~, troughLocs] = findpeaks(-respSignal, 'MinPeakDistance', round(minPeakDist*Fs));
end

peakLocs = peakLocs(:);
troughLocs = troughLocs(:);

end

function [breathRate, cvIBI, breathDepth] = computeMetrics(respSignal, peakLocs, troughLocs, Fs)

% Breath rate
IBI = diff(peakLocs) / Fs;
meanIBI = mean(IBI);
breathRate = 60 / meanIBI;
cvIBI = std(IBI) / meanIBI;

% Breath depth (with abs() for safety, matching single-subject script)
depthVals = [];
for i = 1:length(peakLocs)-1
    idx = find(troughLocs > peakLocs(i) & troughLocs < peakLocs(i+1), 1, 'first');
    if ~isempty(idx)
        depthVals(end+1) = abs(respSignal(peakLocs(i)) - respSignal(troughLocs(idx)));
    end
end
breathDepth = mean(depthVals);

end


function statsResults = performStatisticalTests(respMetrics, pairedDataFlag, centralTendency)

metrics = {'breathRate', 'cvIBI', 'breathDepth'};
metricLabels = {'BR', 'CV', 'Depth'};
fieldPrefixes = {'BR', 'CV', 'Depth'};

statsResults = struct();

for i = 1:3
    
    metric = metrics{i};
    
    med_data = respMetrics(1).(metric)(:);
    con_data = respMetrics(2).(metric)(:);

    % Clean data
    % ================================================================

    if pairedDataFlag
        
        % remove pairs where either subject is invalid
        validIdx = isfinite(med_data) & isfinite(con_data);
        
        med_data = med_data(validIdx);
        con_data = con_data(validIdx);
        
    else
        
        med_data = med_data(isfinite(med_data));
        con_data = con_data(isfinite(con_data));
        
    end

    % Statistical tests
    % ================================================================

    if pairedDataFlag && length(med_data)==length(con_data)

        % ===================== PAIRED ================================
        
        if strcmpi(centralTendency,'mean')

            % paired t-test
            [~,p,~,stats] = ttest(med_data,con_data);

            testType = 'Paired t-test';


            % paired effect size (Cohen dz)
            diffVals = med_data - con_data;

            cohens_d = mean(diffVals) ./ std(diffVals);


        else

            % Wilcoxon signed-rank
            [p,~,stats] = signrank(med_data,con_data);

            testType = 'Wilcoxon signed-rank';


            % robust paired effect estimate
            cohens_d = median(med_data-con_data);

        end


    else

        % ===================== UNPAIRED ==============================

        if strcmpi(centralTendency,'mean')


            % independent t-test
            [~,p,~,stats] = ttest2(med_data,con_data);

            testType = 'Independent t-test';


            % Cohen d
            pooledSTD = sqrt( ...
                ((length(med_data)-1)*std(med_data)^2 + ...
                (length(con_data)-1)*std(con_data)^2) ./ ...
                (length(med_data)+length(con_data)-2));


            cohens_d = ...
                (mean(med_data)-mean(con_data)) ./ pooledSTD;


        else


            % Mann Whitney / Wilcoxon rank sum
            [p,~,stats] = ranksum(med_data,con_data);

            testType = 'Mann-Whitney';


            % median difference
            cohens_d = median(med_data)-median(con_data);


        end

    end

    % Central tendency values for display
    % ================================================================

    if strcmpi(centralTendency,'median')

        med_ct = median(med_data,'omitnan');
        con_ct = median(con_data,'omitnan');

    else

        med_ct = mean(med_data,'omitnan');
        con_ct = mean(con_data,'omitnan');

    end


    % Significance marker
    % ================================================================

    if p < 0.001
        sig = '***';
    elseif p < 0.01
        sig = '**';
    elseif p < 0.05
        sig = '*';
    else
        sig = 'ns';
    end

    % Print
    % ================================================================

    fprintf('%s (%s): Med=%.3f vs Con=%.3f, p=%.4f %s, effect=%.3f (%s)\n',...
        metricLabels{i},...
        centralTendency,...
        med_ct,...
        con_ct,...
        p,...
        sig,...
        cohens_d,...
        testType);

    % Store results (same names as before)
    % ================================================================

    prefix = fieldPrefixes{i};

    statsResults.(sprintf('%s_pval',prefix)) = p;

    statsResults.(sprintf('%s_sig',prefix)) = sig;

    statsResults.(sprintf('%s_cohens_d',prefix)) = cohens_d;

    statsResults.(sprintf('%s_med',prefix)) = med_ct;

    statsResults.(sprintf('%s_con',prefix)) = con_ct;

    statsResults.(sprintf('%s_testtype',prefix)) = testType;


end

end