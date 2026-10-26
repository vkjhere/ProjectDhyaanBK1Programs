% runSaveTFDataPhaseBinned
% Computes TF power separately for each respiratory phase bin for all
% subjects and protocols, then saves results locally.
% The save script only needs to be run once (or when new subjects are added).
% The display script (displayTFDataPhaseBinned) loads these saved files
% and does NOT need access to the full segmentedData folder.

clear; clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%folderSourceString = 'E:\OneDrive - Indian Institute of Science\VK Project Dhyaan';
folderSourceString = 'V:\Students\VinodKJ\VKProjectDhyaan\BK1';
saveFolderName     = 'savedTFDataPhaseBinned';

protocolNameList   = [{'EO1'} {'M1'} {'G1'} {'G2'} {'M2'}];

badEyeCondition    = 'ep';
badTrialVersion    = 'v8';

tapers             = [1 1];
freqRange          = [0 100];
winSize            = 0.25;
winStep            = 0.025;
movingwin          = [winSize winStep];
timeRange          = [-1 1.25];

electrodeList      = [14 16 17 18 19 44 47 48 49 52];  % occipital

numPhaseBins       = 6;
phaseBinEdges      = linspace(-180, 180, numPhaseBins+1);

cutoffNumTrials    = 30;

respSaveFolder     = fullfile(folderSourceString, ...
    'ProjectDhyaanBK1Programs-master\breathingProjectCodes', ...
    'savedPhaseData_6bins');

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Subject list %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

goodSubjectList            = getGoodSubjectsBK1;
[allSubjectNames,expDateList] = getDemographicDetails('BK1');
numSubjects = length(goodSubjectList);

fprintf('Processing %d subjects, %d protocols, %d phase bins\n', ...
    numSubjects, length(protocolNameList), numPhaseBins);

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Create save folder %%%%%%%%%%%%%%%%%%%%%%%%%%%

makeDirectory(saveFolderName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Load TF grid from first subject %%%%%%%%%%%%%%
% timeValsTF and freqValsTF are the same for all subjects.

firstSubject  = goodSubjectList{1};
firstDate     = expDateList{strcmp(firstSubject,allSubjectNames)};
firstProtocol = protocolNameList{1};

folderSegFirst = fullfile(folderSourceString,'data','segmentedData', ...
    firstSubject,'EEG',firstDate,firstProtocol,'segmentedData');
t              = load(fullfile(folderSegFirst,'LFP','lfpInfo.mat'),'timeVals');
timeValsEpoch  = t.timeVals;
EpochFs        = round(1/(timeValsEpoch(2)-timeValsEpoch(1)));
goodTimePosRef = find(timeValsEpoch>=timeRange(1) & timeValsEpoch<=timeRange(2));
numTimePoints  = length(goodTimePosRef);

params.tapers   = tapers;
params.pad      = -1;
params.Fs       = EpochFs;
params.fpass    = freqRange;
params.trialave = 1;

[~,timeValsTF0,freqValsTF] = mtspecgramc(randn(numTimePoints,2),movingwin,params);
timeValsTF = timeValsTF0 + timeRange(1);

fprintf('TF grid: %d time x %d freq\n',length(timeValsTF),length(freqValsTF));

numTF_time = length(timeValsTF);
numTF_freq = length(freqValsTF);

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Main loop: subjects %%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:numSubjects

    subjectName = goodSubjectList{i};
    expDate     = expDateList{strcmp(subjectName,allSubjectNames)};
    disp(['Analyzing subject: ' subjectName]);

    fileNameSave = fullfile(saveFolderName, ...
        [subjectName '_' badEyeCondition '_' badTrialVersion '_TF_phaseBinned.mat']);

%     if exist(fileNameSave,'file')
%         disp(['  Already saved — skipping.']);
%         continue;
%     end

    % Pre-allocate output cells for all protocols
    numProtocols    = length(protocolNameList);
    tfPowerBinned   = cell(1,numProtocols);
    numTrialsPerBin = cell(1,numProtocols);
    badElectrodes   = cell(1,numProtocols);
    numTrials       = zeros(1,numProtocols);

    %%%%%%%%%%%%%%%%%%%%%% Protocol loop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for p=1:numProtocols

        protocolName = protocolNameList{p};

        % Initialise to NaN (stays NaN if protocol is skipped)
        tfPowerBinned{p}   = nan(numPhaseBins,length(electrodeList),numTF_time,numTF_freq);
        numTrialsPerBin{p} = zeros(numPhaseBins,1);

        %%% Load resp phase file
        respFile = fullfile(respSaveFolder, ...
            [subjectName '_' protocolName '_filteredResp_and_phase.mat']);
        if ~exist(respFile,'file')
            disp(['  (' protocolName ') Resp file missing — skipping.']);
            badElectrodes{p} = [];
            continue;
        end
        r = load(respFile,'instantPhaseDeg','timeVals');
        instantPhaseDeg = r.instantPhaseDeg;
        respTimeVals    = r.timeVals;

        %%% Load stimulus onsets
        stimFile = fullfile(folderSourceString,'data','segmentedData', ...
            subjectName,'EEG',expDate,protocolName,'extractedData','goodStimCodeNums.mat');
        if ~exist(stimFile,'file')
            disp(['  (' protocolName ') Stim file missing — skipping.']);
            badElectrodes{p} = [];
            continue;
        end
        s = load(stimFile,'goodStimTimes');

        %%% Bad trials and electrodes
        [badTrials,badElec] = getBadTrialsAndElectrodes(subjectName,expDate, ...
            protocolName,folderSourceString,badEyeCondition,badTrialVersion);
        badElectrodes{p} = badElec;

        goodTrials    = setdiff(1:length(s.goodStimTimes),badTrials);
        numGoodTrials = length(goodTrials);
        numTrials(p)  = numGoodTrials;

        if numGoodTrials < cutoffNumTrials
            disp(['  (' protocolName ') Only ' num2str(numGoodTrials) ' good trials — skipping.']);
            continue;
        end

        goodStimOnsets = s.goodStimTimes(goodTrials);
        goodElectrodes = setdiff(electrodeList,badElec);
        numGoodElecs   = length(goodElectrodes);
        fprintf('  (%s) Good trials: %d | Good elecs: %d\n', ...
            protocolName,numGoodTrials,numGoodElecs);

        %%% Epoch timing for this protocol
        folderSegment = fullfile(folderSourceString,'data','segmentedData', ...
            subjectName,'EEG',expDate,protocolName,'segmentedData');
        t2 = load(fullfile(folderSegment,'LFP','lfpInfo.mat'),'timeVals');
        goodTimePos = find(t2.timeVals>=timeRange(1) & t2.timeVals<=timeRange(2));

        %%% Assign resp phase to each good trial
        trialPhase = zeros(1,numGoodTrials);
        for tr=1:numGoodTrials
            [~,idx]        = min(abs(respTimeVals - goodStimOnsets(tr)));
            trialPhase(tr) = instantPhaseDeg(idx);
        end
        trialPhase(trialPhase == -180) = 180;   % wrap to (-180,+180]

        %%% Bin trials by resp phase
        trialBinAssignment = zeros(1,numGoodTrials);
        for bin=1:numPhaseBins
            lo = phaseBinEdges(bin); hi = phaseBinEdges(bin+1);
            if bin < numPhaseBins
                mask = (trialPhase>=lo) & (trialPhase<hi);
            else
                mask = (trialPhase>=lo) & (trialPhase<=hi);
            end
            trialBinAssignment(mask) = bin;
            numTrialsPerBin{p}(bin)  = sum(mask);
        end
        fprintf('  (%s) Trials per bin: ',protocolName);
        fprintf('%d ',numTrialsPerBin{p}); fprintf('\n');

        %%% Load EEG epochs (good electrodes only)
        allEpochs = zeros(numGoodElecs,numGoodTrials,length(goodTimePos),'single');
        loadOK    = true;
        for ei=1:numGoodElecs
            elecFile = fullfile(folderSegment,'LFP', ...
                ['elec' num2str(goodElectrodes(ei)) '.mat']);
            if ~exist(elecFile,'file')
                disp(['  elec' num2str(goodElectrodes(ei)) ' missing — skipping protocol.']);
                loadOK = false; break;
            end
            e = load(elecFile,'analogData');
            allEpochs(ei,:,:) = e.analogData(goodTrials,goodTimePos);
        end
        if ~loadOK; continue; end

        %%% TF power per phase bin, per electrode
        for bin=1:numPhaseBins
            binIdx = find(trialBinAssignment==bin);
            if length(binIdx)<2; continue; end

            for ei=1:numGoodElecs
                epochData = squeeze(allEpochs(ei,binIdx,:))';   % time x nBinTrials
                [tfElec,~,~] = mtspecgramc(epochData,movingwin,params);
                elecPos = find(electrodeList==goodElectrodes(ei));
                tfPowerBinned{p}(bin,elecPos,:,:) = tfElec;
            end
        end

    end  % protocol loop

    %%% Save subject file
    save(fileNameSave, ...
        'tfPowerBinned','numTrialsPerBin','numTrials', ...
        'timeValsTF','freqValsTF','badElectrodes', ...
        'electrodeList','protocolNameList', ...
        'numPhaseBins','phaseBinEdges','timeRange', ...
        'subjectName','badEyeCondition','badTrialVersion');
    disp(['  Saved: ' fileNameSave]);

end  % subject loop

disp('=== runSaveTFDataPhaseBinned complete ===');

% 
% 
% % For each subject and each protocol (G1, G2, M2), computes TF power
% % separately for each respiratory phase bin and saves the result.
% %
% % Saved file per subject (in saveFolderName):
% %   <subjectName>_<badEyeCondition>_<badTrialVersion>_TF_phaseBinned.mat
% %
% % Saved variables:
% %   tfPowerBinned   : cell(1, numProtocols)
% %                     each cell: numPhaseBins x numElectrodes x numTF_time x numTF_freq
% %   numTrialsPerBin : cell(1, numProtocols)
% %                     each cell: numPhaseBins x 1  (trials per bin)
% %   timeValsTF      : 1 x numTF_time  (common across protocols)
% %   freqValsTF      : 1 x numTF_freq
% %   badElectrodes   : cell(1, numProtocols)  (from getBadTrialsAndElectrodes)
% %   electrodeList   : the occipital electrode list used
% %   protocolNameList: {'G1','G2','M2'}
% %   numPhaseBins    : scalar
% %   phaseBinEdges   : 1 x (numPhaseBins+1)
% %   timeRange       : epoch window used
% %
% % This file is everything the display script needs — no access to the
% % full segmentedData folder is required after this step.
% % =========================================================================
% 
% clear; clc;
% 
% %% ================= Parameters ===========================================
% 
% folderSourceString = 'E:\OneDrive - Indian Institute of Science\VK Project Dhyaan';
% saveFolderName     = 'savedTFDataPhaseBinned';
% 
% protocolNameList   = {'G1', 'G2', 'M2'};
% 
% badEyeCondition    = 'ep';
% badTrialVersion    = 'v8';
% 
% tapers             = [1 1];
% freqRange          = [0 80];
% winSize            = 0.25;
% winStep            = 0.025;
% movingwin          = [winSize winStep];
% timeRange          = [-1 1.25];
% 
% electrodeList      = [14 16 17 18 19 44 47 48 49 52];  % occipital
% 
% numPhaseBins       = 6;
% phaseBinEdges      = linspace(-180, 180, numPhaseBins + 1);
% 
% cutoffNumTrials    = 30;   % skip protocol for a subject if fewer good trials
% 
% respSaveFolder     = fullfile(folderSourceString, ...
%     'ProjectDhyaanBK1Programs-master\breathingProjectCodes', ...
%     'savedPhaseData_6bins');
% 
% %% ================= Subject list =========================================
% 
% goodSubjectList            = getGoodSubjectsBK1;
% [allSubjectNames, expDateList] = getDemographicDetails('BK1');
% 
% numSubjects = length(goodSubjectList);
% fprintf('Processing %d subjects, %d protocols, %d phase bins\n', ...
%     numSubjects, length(protocolNameList), numPhaseBins);
% 
% %% ================= Create save folder ===================================
% 
% if ~exist(saveFolderName, 'dir')
%     [ok, msg] = mkdir(saveFolderName);
%     if ~ok; error('Cannot create %s: %s', saveFolderName, msg); end
% end
% 
% %% ================= Load timing from first available subject =============
% % timeValsTF and freqValsTF are the same for all subjects (same setup).
% % Compute once using a dummy signal.
% 
% firstSubject = goodSubjectList{1};
% firstDate    = expDateList{strcmp(firstSubject, allSubjectNames)};
% firstProto   = protocolNameList{1};
% 
% folderSegFirst = fullfile(folderSourceString, 'data', 'segmentedData', ...
%     firstSubject, 'EEG', firstDate, firstProto, 'segmentedData');
% t             = load(fullfile(folderSegFirst, 'LFP', 'lfpInfo.mat'), 'timeVals');
% timeValsEpoch = t.timeVals;
% EpochFs       = round(1 / (timeValsEpoch(2) - timeValsEpoch(1)));
% goodTimePosRef = find(timeValsEpoch >= timeRange(1) & timeValsEpoch <= timeRange(2));
% numTimePoints  = length(goodTimePosRef);
% 
% params.tapers   = tapers;
% params.pad      = -1;
% params.Fs       = EpochFs;
% params.fpass    = freqRange;
% params.trialave = 1;
% 
% dummyData  = randn(numTimePoints, 2);
% [~, timeValsTF0, freqValsTF] = mtspecgramc(dummyData, movingwin, params);
% timeValsTF = timeValsTF0 + timeRange(1);
% 
% fprintf('TF grid: %d time x %d freq\n', length(timeValsTF), length(freqValsTF));
% 
% numTF_time = length(timeValsTF);
% numTF_freq = length(freqValsTF);
% 
% %% ================= Main loop: subjects ==================================
% 
% for si = 1:numSubjects
% 
%     subjectName = goodSubjectList{si};
%     expDate     = expDateList{strcmp(subjectName, allSubjectNames)};
%     fprintf('\n[%d/%d] %s\n', si, numSubjects, subjectName);
% 
%     saveFile = fullfile(saveFolderName, ...
%         [subjectName '_' badEyeCondition '_' badTrialVersion '_TF_phaseBinned.mat']);
% 
%     % Skip if already saved (comment out to recompute)
%     if exist(saveFile, 'file')
%         fprintf('  Already saved — skipping.\n');
%         continue;
%     end
% 
%     % Pre-allocate output cells
%     tfPowerBinned   = cell(1, length(protocolNameList));
%     numTrialsPerBin = cell(1, length(protocolNameList));
%     badElectrodes   = cell(1, length(protocolNameList));
%     numTrials       = zeros(1, length(protocolNameList));
% 
%     %% -------- Protocol loop -------------------------------------------
%     for pi = 1:length(protocolNameList)
% 
%         proto = protocolNameList{pi};
% 
%         % Initialise outputs for this protocol to NaN
%         tfPowerBinned{pi}   = nan(numPhaseBins, length(electrodeList), numTF_time, numTF_freq);
%         numTrialsPerBin{pi} = zeros(numPhaseBins, 1);
% 
%         %% Load resp phase file
%         respFile = fullfile(respSaveFolder, ...
%             [subjectName '_' proto '_filteredResp_and_phase.mat']);
%         if ~exist(respFile, 'file')
%             fprintf('  (%s) Resp file missing — skipping protocol.\n', proto);
%             badElectrodes{pi} = [];
%             continue;
%         end
%         r = load(respFile, 'instantPhaseDeg', 'timeVals');
%         instantPhaseDeg = r.instantPhaseDeg;
%         respTimeVals    = r.timeVals;
%         respFs          = round(1 / (respTimeVals(2) - respTimeVals(1)));
% 
%         %% Load stimulus onsets
%         stimFile = fullfile(folderSourceString, 'data', 'segmentedData', ...
%             subjectName, 'EEG', expDate, proto, 'extractedData', 'goodStimCodeNums.mat');
%         if ~exist(stimFile, 'file')
%             fprintf('  (%s) Stim file missing — skipping protocol.\n', proto);
%             badElectrodes{pi} = [];
%             continue;
%         end
%         s = load(stimFile, 'goodStimTimes');
% 
%         %% Bad trials and electrodes
%         [badTrials, badElec] = getBadTrialsAndElectrodes(subjectName, expDate, ...
%             proto, folderSourceString, badEyeCondition, badTrialVersion);
%         badElectrodes{pi} = badElec;
% 
%         goodTrials    = setdiff(1:length(s.goodStimTimes), badTrials);
%         numGoodTrials = length(goodTrials);
%         numTrials(pi) = numGoodTrials;
% 
%         if numGoodTrials < cutoffNumTrials
%             fprintf('  (%s) Only %d good trials — skipping protocol.\n', proto, numGoodTrials);
%             continue;
%         end
% 
%         goodStimOnsets = s.goodStimTimes(goodTrials);
%         goodElectrodes = setdiff(electrodeList, badElec);
%         numGoodElecs   = length(goodElectrodes);
%         fprintf('  (%s) Good trials: %d | Good elecs: %d\n', proto, numGoodTrials, numGoodElecs);
% 
%         %% Load epoch timing for this protocol (in case it differs from ref)
%         folderSegment = fullfile(folderSourceString, 'data', 'segmentedData', ...
%             subjectName, 'EEG', expDate, proto, 'segmentedData');
%         t2 = load(fullfile(folderSegment, 'LFP', 'lfpInfo.mat'), 'timeVals');
%         goodTimePos = find(t2.timeVals >= timeRange(1) & t2.timeVals <= timeRange(2));
% 
%         %% Assign resp phase to each good trial
%         trialPhase = zeros(1, numGoodTrials);
%         for tr = 1:numGoodTrials
%             [~, idx]       = min(abs(respTimeVals - goodStimOnsets(tr)));
%             trialPhase(tr) = instantPhaseDeg(idx);
%         end
%         trialPhase(trialPhase == -180) = 180;   % wrap to (-180, +180]
% 
%         %% Bin trials by resp phase
%         trialBinAssignment = zeros(1, numGoodTrials);
%         for bin = 1:numPhaseBins
%             lo = phaseBinEdges(bin); hi = phaseBinEdges(bin + 1);
%             if bin < numPhaseBins
%                 mask = (trialPhase >= lo) & (trialPhase < hi);
%             else
%                 mask = (trialPhase >= lo) & (trialPhase <= hi);
%             end
%             trialBinAssignment(mask) = bin;
%             numTrialsPerBin{pi}(bin) = sum(mask);
%         end
% 
%         %% Load EEG epochs for good electrodes only
%         numElec = length(electrodeList);
%         allEpochs = zeros(numGoodElecs, numGoodTrials, length(goodTimePos), 'single');
%         for ei = 1:numGoodElecs
%             elecFile = fullfile(folderSegment, 'LFP', ...
%                 ['elec' num2str(goodElectrodes(ei)) '.mat']);
%             if ~exist(elecFile, 'file')
%                 fprintf('  elec%d missing — skipping protocol.\n', goodElectrodes(ei));
%                 allEpochs = []; break;
%             end
%             e = load(elecFile, 'analogData');
%             allEpochs(ei, :, :) = e.analogData(goodTrials, goodTimePos);
%         end
%         if isempty(allEpochs); continue; end
% 
%         %% Compute TF per phase bin, per electrode
%         % Store for each electrode in electrodeList (NaN for bad ones)
%         for bin = 1:numPhaseBins
%             binIdx = find(trialBinAssignment == bin);
%             if length(binIdx) < 2; continue; end
% 
%             for ei = 1:numGoodElecs
%                 epochData = squeeze(allEpochs(ei, binIdx, :))';  % time x nBinTrials
%                 [tfElec, ~, ~] = mtspecgramc(epochData, movingwin, params);
%                 % Find position of this electrode in the full electrodeList
%                 elecPos = find(electrodeList == goodElectrodes(ei));
%                 tfPowerBinned{pi}(bin, elecPos, :, :) = tfElec;
%             end
%         end
% 
%         fprintf('  (%s) Done. Trials per bin: ', proto);
%         fprintf('%d ', numTrialsPerBin{pi}); fprintf('\n');
% 
%     end % protocol loop
% 
%     %% Save subject file
%     save(saveFile, ...
%         'tfPowerBinned', 'numTrialsPerBin', 'numTrials', ...
%         'timeValsTF', 'freqValsTF', 'badElectrodes', ...
%         'electrodeList', 'protocolNameList', ...
%         'numPhaseBins', 'phaseBinEdges', 'timeRange', ...
%         'subjectName', 'badEyeCondition', 'badTrialVersion');
% 
%     fprintf('  Saved: %s\n', saveFile);
% 
% end % subject loop
% 
% fprintf('\n=== runSaveTFDataPhaseBinned complete ===\n');
