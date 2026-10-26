% This code uses a software called R_DECO. 
% Moeyersons J, Amoni M, Van Huffel S, Willems R, Varon C. 2019. 
% R-DECO: an open-source Matlab based graphical user interface for the
% detection and correction of R-peaks.*PeerJ Computer Science* 5:e226
% [https://doi.org/10.7717/peerj-cs.226]

% Make sure that the location of R-DECO is in Matlab's path.
% Needs Statistics and Machine Learning Toolbox

function getRRTimeVals(subjectName, expDate, dataFolder, saveFolder)

protocols = {'M1a','M1b','M1c','M2a','M2b','M2c','G1','G2','EO1','EO2','EC1','EC2'};

% addpath(genpath('C:\Users\medin\Documents\material\R-DECO\R-DECO'));

Fs = 1000;

parameters = { ...
    300,...   % envelope size (ms)
    100,...   % average HR (bpm)
    1,...     % postprocessing 
    0,...     % ectopic correction (abnormal beats occuring unexpectedly early)
    1};       % inverted ECG

for p = 1:length(protocols)

    protocolName = protocols{p};

    disp(['   ' protocolName])

    ecgFile = fullfile( dataFolder, subjectName,'EEG',expDate,protocolName,...
        'segmentedData','LFP','elec66.mat');

    if ~exist(ecgFile,'file')

        disp('ECG file missing')
        continue

    end

    try

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% LOAD ECG
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        tmp = load(ecgFile);

        ecgData = double(tmp.analogData);
        ecgData = ecgData(:);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% BANDPASS FILTER (1-20 Hz)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        [b,a] = butter(4, [1 20]/(Fs/2), 'bandpass');

        ecgFiltered = filtfilt(b,a,ecgData);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% R-DECO DETECTION
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        [R_peak,RR_int,~,check] = peak_detection(parameters, ecgFiltered, Fs, 0);

        if ~check                                        

            disp('      detection failed')
            continue

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% FORMAT OUTPUT
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

        if iscell(R_peak)
            R_peak = R_peak{1};
        end

        if iscell(RR_int)
            RR_int = RR_int{1};
        end

        R_peak = double(R_peak(:));
        R_loc = duration( 0,0,(R_peak-1)/Fs,'Format','hh:mm:ss');

        data.R_loc  = {R_loc};
        data.RR_int = {RR_int};

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% SAVE
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % saveDir = fullfile(saveFolder,subjectName,'EEG',expDate,...
        %     protocolName,'segmentedData','LFP');
        % 
        % if ~exist(saveDir,'dir')
        %     mkdir(saveDir)
        % end
        % 
        % save(fullfile(saveDir,'Rpeaks.mat'),'data');
        % 
        % disp('      saved');

        saveFile = fullfile(saveFolder,[subjectName '_' protocolName '.mat']);
        save(saveFile,'data');

    catch ME

        disp(['      FAILED: ' ME.message])

    end
end
end