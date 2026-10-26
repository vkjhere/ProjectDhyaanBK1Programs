% GUI for comparing breathing data between meditators and controls

function runDisplayRespDataAllSubjects()

clear; close all;
rmpath(genpath('E:\OneDrive - Indian Institute of Science\NEOLAB vkj\programs\SoftwareMAP\eeglab12_0_2_5b\functions\octavefunc'));
rmpath(genpath('E:\OneDrive - Indian Institute of Science\NEOLAB vkj\programs\SoftwareMAP\chronux_2_00\chronux'));
rehash toolboxcache;

fontSizeSmall  = 10;
fontSizeMedium = 12;
fontSizeLarge  = 14;
backgroundColor = 'w';

hFig = figure('Name','Respiration Analysis - Groups Comparison','NumberTitle','off',...
    'Color','w','Position',[50 50 1400 900]);

%% ==================== Subjects =======================

hPanel1 = uipanel('Title','Subjects','FontSize',fontSizeLarge,...
    'Unit','Normalized','Position',[0.02 0.85 0.25 0.13]);

uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 2/3 0.4 1/3],...
    'Style','text','String','Comparison','FontSize',fontSizeSmall);
comparisonList = {'paired','unpaired'};
hComparison = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor',backgroundColor,...
    'Position',[0.4 2/3 0.6 1/3],'Style','popup','String',comparisonList,'FontSize',fontSizeSmall);

uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 1/3 0.4 1/3],...
    'Style','text','String','Gender','FontSize',fontSizeSmall);
genderList = {'all','male','female'};
hGender = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor',backgroundColor,...
    'Position',[0.4 1/3 0.6 1/3],'Style','popup','String',genderList,'FontSize',fontSizeSmall);

%% ==================== Protocol ======================

hPanel2 = uipanel('Title','Protocol','FontSize',fontSizeLarge,...
    'Unit','Normalized','Position',[0.28 0.85 0.2 0.13]);

uicontrol('Parent',hPanel2,'Unit','Normalized','Position',[0 1/2 0.3 1/2],...
    'Style','text','String','Protocol','FontSize',fontSizeSmall);
protocolList = {'EO1','EC1','G1','M1','G2','EO2','EC2','M2'};
hProtocol = uicontrol('Parent',hPanel2,'Unit','Normalized','BackgroundColor',backgroundColor,...
    'Position',[0.3 1/2 0.7 1/2],'Style','popup','String',protocolList,'FontSize',fontSizeSmall);

%% ==================== Signal Processing ======================

hPanel3 = uipanel('Title','Signal Processing','FontSize',fontSizeLarge,...
    'Unit','Normalized','Position',[0.49 0.85 0.25 0.13]);

uicontrol('Parent',hPanel3,'Unit','Normalized','Position',[0 2/3 0.35 1/3],...
    'Style','text','String','HighPass (Hz)','FontSize',fontSizeSmall);
hHighPass = uicontrol('Parent',hPanel3,'Unit','Normalized','BackgroundColor',backgroundColor,...
    'Position',[0.35 2/3 0.3 1/3],'Style','edit','String','0.05','FontSize',fontSizeSmall);

uicontrol('Parent',hPanel3,'Unit','Normalized','Position',[0.65 2/3 0.35 1/3],...
    'Style','text','String','LowPass (Hz)','FontSize',fontSizeSmall);
hLowPass = uicontrol('Parent',hPanel3,'Unit','Normalized','BackgroundColor',backgroundColor,...
    'Position',[0.65 2/3 0.3 1/3],'Style','edit','String','2','FontSize',fontSizeSmall);

uicontrol('Parent',hPanel3,'Unit','Normalized','Position',[0 1/3 0.35 1/3],...
    'Style','text','String','MinPeakDist (s)','FontSize',fontSizeSmall);
hMinPeakDist = uicontrol('Parent',hPanel3,'Unit','Normalized','BackgroundColor',backgroundColor,...
    'Position',[0.35 1/3 0.3 1/3],'Style','edit','String','2','FontSize',fontSizeSmall);

uicontrol('Parent',hPanel3,'Unit','Normalized','Position',[0.65 1/3 0.35 1/3],...
    'Style','text','String','MinProminence','FontSize',fontSizeSmall);
hMinProminence = uicontrol('Parent',hPanel3,'Unit','Normalized','BackgroundColor',backgroundColor,...
    'Position',[0.65 1/3 0.3 1/3],'Style','edit','String','0.25','FontSize',fontSizeSmall);

%% ==================== Statistical Analysis ======================

hPanel4 = uipanel('Title','Statistical Analysis','FontSize',fontSizeLarge,...
    'Unit','Normalized','Position',[0.75 0.85 0.23 0.13]);

uicontrol('Parent',hPanel4,'Unit','Normalized','Position',[0 2/3 0.45 1/3],...
    'Style','text','String','Central Tendency','FontSize',fontSizeSmall);
centralTendencyList = {'mean', 'median'};
hCentralTendency = uicontrol('Parent',hPanel4,'Unit','Normalized','BackgroundColor',backgroundColor,...
    'Position',[0.45 2/3 0.55 1/3],'Style','popup','String',centralTendencyList,'FontSize',fontSizeSmall);

uicontrol('Parent',hPanel4,'Unit','Normalized','Position',[0 1/3 0.5 1/3],...
    'Style','pushbutton','String','Plot','FontSize',fontSizeMedium,'FontWeight','bold',...
    'BackgroundColor',[0 0.6 0],'ForegroundColor','w',...
    'Callback',{@analyze_Callback});

uicontrol('Parent',hPanel4,'Unit','Normalized','Position',[0.5 1/3 0.5 1/3],...
    'Style','pushbutton','String','CLEAR','FontSize',fontSizeMedium,...
    'Callback',{@clearAll_Callback});

%% ==================== Plot Axes =====================================

hAx1 = axes('Position',[0.08 0.45 0.25 0.35]);
hAx2 = axes('Position',[0.38 0.45 0.25 0.35]);
hAx3 = axes('Position',[0.68 0.45 0.25 0.35]);

% Statistics text box
hAx4 = axes('Position',[0.08 0.05 0.85 0.32]);
axis off;

%% ==================== Callbacks =====================================

    function analyze_Callback(~,~)

        comparisonStr  = comparisonList{get(hComparison,'Value')};
        genderStr      = genderList{get(hGender,'Value')};
        protocolName   = protocolList{get(hProtocol,'Value')};
        centralTendency = centralTendencyList{get(hCentralTendency,'Value')};

        highPassFreq  = str2double(get(hHighPass,'String'));
        lowPassFreq   = str2double(get(hLowPass,'String'));
        minPeakDist   = str2double(get(hMinPeakDist,'String'));
        minProminence = str2double(get(hMinProminence,'String'));

        if strcmp(comparisonStr,'paired')
            pairedSubjectNameList  = getPairedSubjectsBK1();
            subjectNameLists{1}    = pairedSubjectNameList(:,1);
            subjectNameLists{2}    = pairedSubjectNameList(:,2);
            pairedDataFlag         = 1;
        else
            [~, meditatorList, controlList] = getGoodSubjectsBK1();
            subjectNameLists{1}    = meditatorList;
            subjectNameLists{2}    = controlList;
            pairedDataFlag         = 0;
        end

        [subjectList, ~, ~, ~, genderList_all] = getDemographicDetails('BK1');

        if strcmp(genderStr,'male')
            maleSubjects           = subjectList(strcmpi(genderList_all,'M'));
            subjectNameLists{1}    = intersect(subjectNameLists{1}, maleSubjects,   'stable');
            subjectNameLists{2}    = intersect(subjectNameLists{2}, maleSubjects,   'stable');
        elseif strcmp(genderStr,'female')
            femaleSubjects         = subjectList(strcmpi(genderList_all,'F'));
            subjectNameLists{1}    = intersect(subjectNameLists{1}, femaleSubjects, 'stable');
            subjectNameLists{2}    = intersect(subjectNameLists{2}, femaleSubjects, 'stable');
        end

        [respMetrics, statsResults] = displayRespDataAllSubjects(subjectNameLists, protocolName,...
            highPassFreq, lowPassFreq, minPeakDist, minProminence, pairedDataFlag, centralTendency);

        plotResults(hAx1, hAx2, hAx3, hAx4, respMetrics, statsResults, protocolName, centralTendency, pairedDataFlag);

    end

    function clearAll_Callback(~,~)
   
        clearAxes(hAx1);
        clearAxes(hAx2);
        clearAxes(hAx3);
        clearAxes(hAx4);
        axis(hAx4,'off');
    end

end

%% ==================== clearAxes =====================================

function clearAxes(ax)
delete(allchild(ax));
title(ax,'');
xlabel(ax,'');
ylabel(ax,'');
grid(ax,'off');
set(ax, 'XLimMode','auto',  'YLimMode','auto', ...
        'XTickMode','auto', 'YTickMode','auto', ...
        'XTickLabelMode','auto', 'YTickLabelMode','auto');

end

%% ==================== plotResults ===================================

function plotResults(hAx1, hAx2, hAx3, hAx4, respMetrics, statsResults, protocolName, centralTendency, pairedDataFlag)

if nargin < 8 || isempty(centralTendency)
    centralTendency = 'median';
end
if nargin < 9 || isempty(pairedDataFlag)
    pairedDataFlag = 0;
end

meditatorBR = respMetrics(1).breathRate(:);
controlBR   = respMetrics(2).breathRate(:);

meditatorCV = respMetrics(1).cvIBI(:);
controlCV   = respMetrics(2).cvIBI(:);

meditatorBD = respMetrics(1).breathDepth(:);
controlBD   = respMetrics(2).breathDepth(:);

% --- Breath Rate ---
clearAxes(hAx1); axes(hAx1);
plotViolinWithCentralTendency(hAx1, {meditatorBR, controlBR}, centralTendency, ...
    {'Meditators','Controls'}, statsResults.BR_pval, pairedDataFlag);
ylabel('Breath Rate (breaths/min)');
title([protocolName ' - Breath Rate']);
grid on;

% --- CV IBI ---
clearAxes(hAx2); axes(hAx2);
plotViolinWithCentralTendency(hAx2, {meditatorCV, controlCV}, centralTendency, ...
    {'Meditators','Controls'}, statsResults.CV_pval, pairedDataFlag);
ylabel('CV (IBI)');
title([protocolName ' - Breath Variability']);
grid on;

% --- Breath Depth ---
clearAxes(hAx3); axes(hAx3);
plotViolinWithCentralTendency(hAx3, {meditatorBD, controlBD}, centralTendency, ...
    {'Meditators','Controls'}, statsResults.Depth_pval, pairedDataFlag);
ylabel('Breath Depth');
title([protocolName ' - Breath Depth']);
grid on;

% --- Summary of statistics  ---
clearAxes(hAx4);
axes(hAx4);
axis off;

stats_text = sprintf('Statistical Results - %s Analysis\n\n', upper(centralTendency));
stats_text = [stats_text sprintf('Breath Rate:   p = %.4f %s  |  Cohen''s d = %.3f  |  Med = %.2f  Con = %.2f  (%s)\n\n', ...
    statsResults.BR_pval,    statsResults.BR_sig,    statsResults.BR_cohens_d, ...
    statsResults.BR_med,     statsResults.BR_con,    statsResults.BR_testtype)];
stats_text = [stats_text sprintf('CV (IBI):      p = %.4f %s  |  Cohen''s d = %.3f  |  Med = %.3f  Con = %.3f  (%s)\n\n', ...
    statsResults.CV_pval,    statsResults.CV_sig,    statsResults.CV_cohens_d, ...
    statsResults.CV_med,     statsResults.CV_con,    statsResults.CV_testtype)];
stats_text = [stats_text sprintf('Breath Depth:  p = %.4f %s  |  Cohen''s d = %.3f  |  Med = %.2f  Con = %.2f  (%s)\n', ...
    statsResults.Depth_pval, statsResults.Depth_sig, statsResults.Depth_cohens_d, ...
    statsResults.Depth_med,  statsResults.Depth_con, statsResults.Depth_testtype)];

text(0.05, 0.5, stats_text, ...
    'FontSize', 10, ...
    'VerticalAlignment', 'middle', ...
    'Interpreter', 'none');

end

%% ==================== plotViolinWithCentralTendency =================

function plotViolinWithCentralTendency(ax, dataCell, centralTendency, labels, pval, pairedFlag)
% pval (p value): optional — when supplied, a significance bracket is drawn above
%        the violins.  Pass [] or omit to skip it
% pairedFlag: 1 = data1(i) and data2(i) belong to the same pair (NaN-padded
%        vectors of equal length); pairs with a NaN on either side will be dropped
%        together

if nargin < 5, pval = []; end
if nargin < 6 || isempty(pairedFlag), pairedFlag = 0; end

% ------ colours ----------------------------------------------------------
colorMed = [0.8  0.0  0.8 ];   % magenta  – meditators
colorCon = [0.25 0.41 0.88];   % blue     – controls

ctColors = {[1 0 1], [0.25 0.41 0.88]};  % magenta / blue for mean/median (CT) lines

% ------ clear axes completely (incl. hidden-handle objects) --------------
clearAxes(ax);

% ------ clean data -------------------------------------------------------
data1 = dataCell{1}(:);
data2 = dataCell{2}(:);

if pairedFlag && numel(data1) == numel(data2)
    % drop a pair if EITHER member is invalid, so index i stays the same pair
    okPair = isfinite(data1) & isfinite(data2);
    data1  = data1(okPair);
    data2  = data2(okPair);
else
    pairedFlag = 0;
    data1 = data1(isfinite(data1));
    data2 = data2(isfinite(data2));
end

if isempty(data1) || isempty(data2)
    text(ax, 0.5, 0.5, 'No valid data', 'HorizontalAlignment', 'center');
    return;
end

axes(ax);

% ------ violin plot ------------------------------------------------------
try
    violin({data1, data2}, ...
        'xlabel',    labels,              ...
        'facecolor', [colorMed; colorCon],...
        'edgecolor', 'k',                 ...
        'facealpha', 0.5,                 ...
        'mc',        '',                  ...  % suppress built-in mean line
        'medc',      '');                      % suppress built-in median line
catch ME
    fprintf('Violin plot failed: %s\nFalling back to boxplot.\n', ME.message);
    Y = [data1; data2];
    G = [ones(length(data1),1); 2*ones(length(data2),1)];
    boxplot(ax, Y, G, 'Labels', labels);
end

hold(ax, 'on');

% ------ scatter individual data points -----------------------------------
scatter(ax, ones(size(data1)), data1, 22, colorMed, 'filled', ...
    'MarkerFaceAlpha', 0.55, 'HandleVisibility', 'off');
scatter(ax, 2*ones(size(data2)), data2, 22, colorCon, 'filled', ...
    'MarkerFaceAlpha', 0.55, 'HandleVisibility', 'off');

% ------ paired connecting lines (paired mode only) -----------------------
if pairedFlag
    for i = 1:length(data1)
        plot(ax, [1 2], [data1(i) data2(i)], '-', ...
            'Color',     [0.72 0.72 0.72], ...
            'LineWidth', 0.75, ...
            'HandleVisibility', 'off');
    end
end

% ------ central tendency lines (magenta = med, blue = con) ---------------
groupData = {data1, data2};
for grp = 1:2
    d = groupData{grp};
    switch lower(centralTendency)
        case 'mean';    ctVal = mean(d,   'omitnan');
        otherwise;      ctVal = median(d, 'omitnan');   % default: median
    end
    plot(ax, [grp - 0.22, grp + 0.22], [ctVal, ctVal], '-', ...
        'Color',     ctColors{grp}, ...
        'LineWidth', 3.5, ...
        'HandleVisibility', 'off');
end

% ------ p-value bracket above the violins --------------------------------
if ~isempty(pval)

    yLims  = ylim(ax);
    yRange = diff(yLims);
    yTop   = yLims(2);

    % significance label
    if pval < 0.001
        sigStr = sprintf('p = %.4f ***', pval);
    elseif pval < 0.01
        sigStr = sprintf('p = %.4f **',  pval);
    elseif pval < 0.05
        sigStr = sprintf('p = %.4f *',   pval);
    else
        sigStr = sprintf('p = %.4f (ns)', pval);
    end

    % bracket coordinates
    yFoot    = yTop   + 0.02 * yRange;   % bottom of bracket verticals
    yBracket = yFoot  + 0.05 * yRange;   % top of bracket horizontals

    plot(ax, [1, 1, 2, 2], [yFoot, yBracket, yBracket, yFoot], ...
        'k-', 'LineWidth', 1.0, 'HandleVisibility', 'off');

    text(ax, 1.5, yBracket + 0.01 * yRange, sigStr, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment',   'bottom', ...
        'FontSize',   10, ...
        'FontWeight', 'bold');

    % expand y-axis so bracket is not clippedd
    ylim(ax, [yLims(1), yBracket + 0.12 * yRange]);
end

% ------ formatting -------------------------------------------------------
set(ax, 'XTick', [1 2], 'XTickLabel', labels, 'FontSize', 12);
box(ax, 'on');
legend(ax, 'off');
hold(ax, 'off');

end