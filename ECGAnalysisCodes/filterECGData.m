function filteringInfo = filterECGData

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FILTER ENABLE FLAG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filteringInfo.applyFilter = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CUTOFF FREQUENCIES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filteringInfo.HPF = 1;       % Hz
filteringInfo.LPF = 20;      % Hz

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FILTER DESIGN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filteringInfo.filterType  = 'butter';
filteringInfo.filterOrder = 4;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DESCRIPTION STRING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~filteringInfo.applyFilter

    filteringInfo.filterDescription = 'Filtering Disabled';

elseif filteringInfo.HPF==0 && isinf(filteringInfo.LPF)

    filteringInfo.filterDescription = 'No Filtering';

elseif filteringInfo.HPF>0 && isinf(filteringInfo.LPF)

    filteringInfo.filterDescription = ...
        sprintf('High-Pass %.2f Hz',filteringInfo.HPF);

elseif filteringInfo.HPF==0 && isfinite(filteringInfo.LPF)

    filteringInfo.filterDescription = ...
        sprintf('Low-Pass %.2f Hz',filteringInfo.LPF);

else

    filteringInfo.filterDescription = ...
        sprintf('Band-Pass %.2f - %.2f Hz',...
        filteringInfo.HPF,...
        filteringInfo.LPF);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% VALIDITY CHECKS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if filteringInfo.HPF < 0
    error('HPF must be >= 0');
end

if filteringInfo.HPF>0 && ...
        isfinite(filteringInfo.LPF) && ...
        filteringInfo.HPF>=filteringInfo.LPF

    error('HPF must be smaller than LPF');
end

end