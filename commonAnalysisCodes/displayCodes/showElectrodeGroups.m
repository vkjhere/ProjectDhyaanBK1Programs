function montageChanlocs = showElectrodeGroups(hPlots,capType,electrodeGroupList,groupNameList, displaySettings)

%%%%%%%%%%%%%%%%%%%%%% check the displaySettings %%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('displaySettings','var');                displaySettings=struct();              end
if ~isfield(displaySettings,'fontSizeEG');         displaySettings.fontSizeEG = 12;       end
if ~isfield(displaySettings,'headRad');            displaySettings.headRad = 0.6;         end
if ~isfield(displaySettings,'colormap');           displaySettings.colormap = 'jet';      end
if ~isfield(displaySettings,'refElectrodes');      displaySettings.refElectrodes = [];    end
%%%%%%%%%%%%%%%%%%%%%% Compare with Montage %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = load([capType 'Labels.mat']); montageLabels = x.montageLabels(:,2);
x = load([capType '.mat']);       montageChanlocs = x.chanlocs;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Topoplot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(hPlots(1), 'Color', 'none');
axes(hPlots(1));
electrodeSize = 4;
numElectrodes = length(montageLabels);

for i=1:numElectrodes
    montageChanlocs(i).labels = ' ';
end

numElectrodeGroups = length(electrodeGroupList);

if strcmp(displaySettings.colormap,'lines')
    electrodeGroupColorList = lines(numElectrodeGroups);
elseif strcmp(displaySettings.colormap,'cool')
    electrodeGroupColorList = flip(cool(numElectrodeGroups));
elseif strcmp(displaySettings.colormap,'winter')
    electrodeGroupColorList = winter(numElectrodeGroups);
else
    electrodeGroupColorList = jet(numElectrodeGroups);
    % since yellow and green in JET are not much visible agianst a light background.
    % Define target yellow and green RGB values to match
    targetYellow = [1 1 0];
    targetGreen  = [0 1 0];

    % Find the index of the color closest to yellow
    [~, yellowIdx] = min(sum((electrodeGroupColorList - targetYellow).^2, 2));
    % Replace with darker yellow
    electrodeGroupColorList(yellowIdx, :) = [0.8 0.8 0];

    % Find the index of the color closest to green
    [~, greenIdx] = min(sum((electrodeGroupColorList - targetGreen).^2, 2));
    % Replace with darker green
    electrodeGroupColorList(greenIdx, :) = [0 0.6 0];
    % decreasing saturation of 2nd group , light bluish
    electrodeGroupColorList(2, :) = [0 0.5 0.8];
end

hold on;
for i = 1:numElectrodeGroups
    topoplot( zeros(1,numElectrodes), montageChanlocs,'maplimits',[0 1], 'electrodes','off', 'style','map', ...   
        'emarker2',{electrodeGroupList{i}, 'o', electrodeGroupColorList(i,:), electrodeSize}, ...
        'plotrad',0.66,'headrad',displaySettings.headRad);
end
% Force white everywhere else
colormap(gca, [1 1 1]);     % single-color white colormap
colorbar('off');       
set(gcf, 'Color', 'w'); % white figure background
title('Electrode Groups', 'FontSize', 12);

    axes(hPlots(2))
    set(hPlots(2),'visible','off');
    for i=1:numElectrodeGroups
        text(0.9, 0.8-0.12*(i-1),[groupNameList{i} ' (N=' num2str(length(electrodeGroupList{i})) ')'],...
            'color',electrodeGroupColorList(i,:),'Units','normalized','Fontsize', displaySettings.fontSizeEG,...
            'Fontweight', 'bold', 'HorizontalAlignment','right');
    end
