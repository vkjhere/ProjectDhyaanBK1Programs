% This code takes long continuous data segments for both ECG and EEG (which
% is stored in segmentedDataLong by running runSegmentAndSaveDataLong in
% the preprocessing folder

function getHEPs(subjectName,expDate,dataFolder,saveFolder,manualStr)

if ~exist('manualStr','var');          manualStr='_Manual';             end

protocols = {'M1a','M1b','M1c','M2a','M2b','M2c','G1','G2','EO1','EO2','EC1','EC2'};

electrodeNums = [1:64 66];
numElectrodes = length(electrodeNums);

hEPLen = [-0.2 1]; % length of the hEP in seconds

for p = 1:length(protocols)

    protocolName = protocols{p};

    % Get the RR intervals
    savedRRFile = fullfile(pwd,'savedRRData',[subjectName '_' protocolName manualStr '.mat']);

    if exist(savedRRFile,'file')
        tmp = load(savedRRFile);
        rrTimes{1} = seconds(tmp.data.R_loc{1});

        tmp = load(fullfile(dataFolder,subjectName,'EEG',expDate,protocolName,'segmentedData','LFP','lfpInfo.mat'));
        timeVals = tmp.timeVals;
        t = timeVals - timeVals(1);

        hEPTimeLims = [t(1)-hEPLen(1) t(end)-hEPLen(2)]; % Take the entire time interval
        [~,numRPeaks,xsHEP] = getSTA(rrTimes,t,hEPTimeLims,t,hEPLen,0);

        hEP = zeros(numElectrodes,length(xsHEP));

        for e = 1: numElectrodes

            dataFile = fullfile(dataFolder,subjectName,'EEG',expDate,protocolName,'segmentedData','LFP',['elec' num2str(electrodeNums(e)) '.mat']);
            tmp = load(dataFile);

            data = tmp.analogData;
            tmpData = getSTA(rrTimes,data,hEPTimeLims,t,hEPLen,0);
            hEP(e,:) = tmpData{1} - mean(tmpData{1});
        end

        saveFile = fullfile(saveFolder,[subjectName '_' protocolName manualStr '.mat']);
        save(saveFile,'hEP','xsHEP','numRPeaks');
    end
end