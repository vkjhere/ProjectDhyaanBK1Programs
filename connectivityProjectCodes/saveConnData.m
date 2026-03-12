
function saveConnData(subjectName,protocolNameList,badEyeCondition,badTrialVersion,ftDataFolder,connMethod,stRange, avgRefFlag)

if ~exist('stRange','var');         stRange = [0.25 1.25];              end

numProtocols = length(protocolNameList);
for i=1:numProtocols
    protocolName = protocolNameList{i};
    saveConnDataSingleProtocol(subjectName,protocolName,badEyeCondition,badTrialVersion,ftDataFolder,connMethod,stRange, avgRefFlag);
end
end

function saveConnDataSingleProtocol(subjectName,protocolName,badEyeCondition,badTrialVersion,ftDataFolder,connMethod,stRange, avgRefFlag)
if avgRefFlag
    savedDataFolder = 'savedDataAvgRef'; % local project directory
else
    savedDataFolder = 'savedData'; % local project directory
end
makeDirectory(savedDataFolder);
savedDataFolder = fullfile(savedDataFolder,subjectName);
makeDirectory(savedDataFolder);

% Analysis file - this is where the final analyzed data is saved
analysisDetailsFileConn = fullfile(savedDataFolder,[protocolName '_' badEyeCondition '_' badTrialVersion '_' connMethod '.mat']);

% ftData - data in fieldtrip format is saved in ftData
ftDataFileName = fullfile(ftDataFolder,subjectName,[protocolName '_' badEyeCondition '_' badTrialVersion '.mat']);
tmpData = load(ftDataFileName);
numGoodTrials = tmpData.numGoodTrials;
% -------------------------------------------------------------------------
% Since M1 and M2 have 3 times as many trials, lets randomly select ~ N/3 trials.
if strcmp(protocolName, 'M1') || strcmp(protocolName, 'M2')
    % Total number of trials
    N = numel(tmpData.data.trial);
    nSelect = floor(N/3);

    if nSelect < 1
        error('Not enough trials to select one-third of them.');
    end

    rng(1);                     % fixing indices for reproducibility
    idx = randperm(N, nSelect);      

    % Keep only selected trials
    tmpData.data.trial = tmpData.data.trial(idx);
    tmpData.data.time  = tmpData.data.time(idx);
    if isfield(tmpData.data, 'sampleinfo')
        tmpData.data.sampleinfo = tmpData.data.sampleinfo(idx,:);
    end
    tmpData.data.numTrials = round(tmpData.data.numTrials/3);
    numGoodTrials          = round(numGoodTrials/3);
end
% -------------------------------------------------------------------------
if numGoodTrials>0
    data = tmpData.data;

    cfg        = [];
    cfg.toilim = [(-diff(stRange) + 1/data.fsample) 0]; % just to have data of same length in Pre and Post
    dataPre    = ft_redefinetrial(cfg,data);

    cfg        = [];
    cfg.toilim = [(stRange(1) + 1/data.fsample) stRange(2)];
    dataPost   = ft_redefinetrial(cfg,data);

    [connPre,freqPre]   = getConnIndividualSubject(dataPre,connMethod);
    [connPost,freqPost] = getConnIndividualSubject(dataPost,connMethod);
else
    connPre=[]; connPost=[]; freqPre=[]; freqPost=[];
end
save(analysisDetailsFileConn,'connPre','connPost','freqPre','freqPost','numGoodTrials');

end

function [conn, freqVals] = getConnIndividualSubject(data, connMethod)

%%%%%%%%%%%%%%%%%%%%%%%% CONNECTIVITY METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 'coh'          : Coherence magnitude. ft_connectivity_corr applies abs()
%                  internally (cfg.complex='abs' default). Output: [0,1].
%
% 'icoh'         : Imaginary coherence. Same pipeline as 'coh' but with
%                  cfg.complex='imag'. Output is signed real — no abs().
%                  Insensitive to zero-lag volume conduction.
%
% 'plv'          : Phase Locking Value. ft_connectivity_corr applies abs()
%                  internally. Output: [0,1].
%
% 'wpli'         : Weighted Phase Lag Index. ft_connectivity_wpli returns
%                  signed values [-1,1]. abs() applied here to get strength.
%
% 'wpli_debiased': Debiased wPLI (estimates squared wPLI). Same as wpli
%                  re: abs(). Less biased with low trial counts.
%
% 'ppc'          : Pairwise Phase Consistency. Real-valued, unbiased
%                  estimate of PLV^2. Output: [0,1]. No abs() needed.
%
% 'laggedCoh'    : Lagged Coherence (as done by Lehmann et al. 2012 / Pascual-Marqui
%                  2007). Computed directly from Fourier coefficients via
%                  computeLaggedCoherence() - since FieldTrip's built-in version
%                  is incompatible with mtmfft (requires a time axis).
%                  Output: [0,1]. Insensitive to zero-lag volume conduction.
% -----------------------------------------------------------------------

switch connMethod

    case 'icoh'
        % Imaginary coherence: cfg.method='coh' + cfg.complex='imag'
        % Output is signed real - should do not apply abs()
        temp     = getConnThisCondition(data, 'icoh');
        conn     = temp.cohspctrm;
        freqVals = temp.freq;

    case {'wpli', 'wpli_debiased'}
        % ft_connectivity_wpli returns signed values [-1, 1]
        % FieldTrip doc explicitly say: "still have to take absolute value"
        temp     = getConnThisCondition(data, connMethod);
        conn     = abs(temp.([connMethod 'spctrm']));
        freqVals = temp.freq;

    case 'ppc'
        % Real-valued output in [0,1] — no abs() needed
        temp     = getConnThisCondition(data, connMethod);
        conn     = temp.ppcspctrm;
        freqVals = temp.freq;

    case {'coh', 'plv'}
        % ft_connectivity_corr applies abs() internally (cfg.complex='abs' default)
        temp     = getConnThisCondition(data, connMethod);
        conn     = temp.([connMethod 'spctrm']);
        freqVals = temp.freq;

    case 'laggedCoh'
        % FieldTrip's built-in 'laggedcoherence' requires a time axis (mtmconvol/wavelet)
        % and is therefore incompatible with our mtmfft epoched-trial pipeline.
        % We use the Lagged Coh formula directly instead.
        [conn, freqVals] = computeLaggedCoherence(data);

    otherwise
        % fallback for any other FieldTrip method
        temp     = getConnThisCondition(data, connMethod);
        conn     = abs(temp.([connMethod 'spctrm']));
        freqVals = temp.freq;
end

if isfield(data, 'badElecs') && ~isempty(data.badElecs)
    badElecs           = data.badElecs;
    conn(badElecs,:,:) = NaN;
    conn(:,badElecs,:) = NaN;
end
end

function conn_stat = getConnThisCondition(data, method)

cfg              = [];
cfg.method       = 'mtmfft';
cfg.taper        = 'dpss';
cfg.tapsmofrq    = 1;
cfg.foilim       = [0 200];

switch method

    case 'coh'
        cfg.output  = 'powandcsd';
        freqData    = ft_freqanalysis(cfg, data);
        freqData    = ft_checkdata(freqData, 'cmbrepresentation', 'full');
        cfg2        = [];
        cfg2.method = 'coh';
        % cfg2.complex defaults to 'abs' inside ft_connectivityanalysis

    case 'icoh'
        cfg.output   = 'powandcsd';
        freqData     = ft_freqanalysis(cfg, data);
        freqData     = ft_checkdata(freqData, 'cmbrepresentation', 'full');
        cfg2         = [];
        cfg2.method  = 'coh';
        cfg2.complex = 'imag';  % signed imaginary part - no abs()

    case {'wpli', 'wpli_debiased', 'plv', 'ppc', 'wppc'}
        cfg.output     = 'fourier';
        cfg.keeptrials = 'yes';
        freqData       = ft_freqanalysis(cfg, data);
        cfg2           = [];
        cfg2.method    = method;

    otherwise
        cfg.output     = 'fourier';
        cfg.keeptrials = 'yes';
        freqData       = ft_freqanalysis(cfg, data);
        cfg2           = [];
        cfg2.method    = method;
end

conn_stat = ft_connectivityanalysis(cfg2, freqData);
end

function [laggedCoh, freqVals] = computeLaggedCoherence(data)
% As per Lehmann et al. (2012) NeuroImage 60:1602-1612 and Pascual-Marqui, 2007, 
% Lagged coherence is given by:
%
%         |Im( mean_t[F_x * conj(F_y)] )|
% LC_xy = ---------------------------------------------------------------
%         sqrt( mean_t[|F_x|^2] * mean_t[|F_y|^2] - Re( mean_t[F_x * conj(F_y)] )^2 )
%
% Notes:
%   - psd_outer - real(csd_f).^2 >= 0 by Cauchy-Schwarz; max(...,0)
%     guards against tiny negative values from floating point errors.
%   - Threshold 1e-10 (not eps) is used for EEG noise floor practicality.
%   - Output is clamped to [0,1] as per theoretical bounds.

cfg             = [];
cfg.method      = 'mtmfft';
cfg.taper       = 'dpss';
cfg.tapsmofrq   = 1;
cfg.output      = 'fourier';
cfg.keeptrials  = 'yes';
cfg.foilim      = [0 200];
freqData        = ft_freqanalysis(cfg, data);

F        = freqData.fourierspctrm;  % [nTrials x nElecs x nFreqs], complex
freqVals = freqData.freq;

nTrials = size(F,1);
nChans  = size(F,2);
nFreqs  = size(F,3);

% --- accumulate cross- and auto-spectra across trials ---
CSD = zeros(nChans, nChans, nFreqs, 'like', 1+1i);
PSD = zeros(nChans, nFreqs);

for t = 1:nTrials
    Ft  = squeeze(F(t,:,:));        % [nChans x nFreqs]
    for f = 1:nFreqs
        fvec       = Ft(:,f);       % [nChans x 1]
        CSD(:,:,f) = CSD(:,:,f) + fvec * fvec';  % ' = conjugate transpose
    end
    PSD = PSD + abs(Ft).^2;
end

CSD = CSD ./ nTrials;
PSD = PSD ./ nTrials;

% --- apply Lagged coherence formula ---
laggedCoh = zeros(nChans, nChans, nFreqs);

for f = 1:nFreqs
    csd_f     = CSD(:,:,f);
    psd_f     = PSD(:,f);

    num       = abs(imag(csd_f));
    psd_outer = psd_f * psd_f';
    denom     = sqrt(max(psd_outer - real(csd_f).^2, 0));

    lc_f                 = num ./ denom;
    lc_f(denom < 1e-10)  = NaN;            % to avoid unreliably huge values
    lc_f                 = min(lc_f, 1);     % clamp to theoretical bound [0,1]
    lc_f(1:nChans+1:end) = NaN;            % diagonal (self-connectivity) undefined

    laggedCoh(:,:,f) = lc_f;
end
end