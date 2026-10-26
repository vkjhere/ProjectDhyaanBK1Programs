% protocols = {'M1a','M1b','M1c','M2a','M2b','M2c','G1','G2','EO1','EO2','EC1','EC2'};
protocols = {'EO1','EC1','M1a','M1b','M1c','M2a','M2b','M2c'};
numProtocols = length(protocols);

hRRIntervals = getPlotHandles(1,numProtocols,[0.05 0.5 0.9 0.4],0.01,0,1);
linkaxes(hRRIntervals);

hHRV = getPlotHandles(1,numProtocols,[0.05 0.05 0.9 0.4],0.01,0,1);
linkaxes(hHRV);

for i = 1:numProtocols
    protocolName = protocols{i};
    displayECGDataAllSubjects(hRRIntervals(i),hHRV(i),protocolName);
end
