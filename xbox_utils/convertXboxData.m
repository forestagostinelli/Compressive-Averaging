% Load excel file and save as .mat file
clear

fprintf('Loading Data\n')
load('../survey-data-bcs-data-store/XboxPollDemo/XboxPollDemoMassage.mat')
load('../survey-data-bcs-data-store/XboxPoll/XboxPollMassage.mat')

fprintf('Parsing xbox data\n')

%% Only keep responses who gave 2 party response
keepIdxs = strcmpi(xboxData{5},'mitt romney') | strcmpi(xboxData{5},'barack obama');
numColumns = length(xboxData);
for i=1:numColumns
    xboxData{i} = xboxData{i}(keepIdxs);
end

%% Keep only users with demographic info
keepIdxs = ismember(xboxData{2},xboxDemographics{2});
for i=1:numColumns
    xboxData{i} = xboxData{i}(keepIdxs);
end

%% Keep users that responded before first debate
idxs = xboxData{4} < datetime(2012,10,3);
userIdsBeforeDate = xboxData{2}(idxs);
keepIdxs = ismember(xboxData{2},userIdsBeforeDate);
for i=1:numColumns
    xboxData{i} = xboxData{i}(keepIdxs);
end

%% Update demographics to only have valid IDs
keepIdxs = ismember(xboxDemographics{2},xboxData{2});
numDemoColumns = length(xboxDemographics);
for i=1:numDemoColumns
    xboxDemographics{i} = xboxDemographics{i}(keepIdxs);
end

%% Convert responses to numbers
numSamples = length(xboxData{2});
responses = zeros(numSamples,1);
responses(strcmpi(xboxData{5},'mitt romney')) = 1;
responses(strcmpi(xboxData{5},'barack obama')) = 2;

%% Sort data by date
fprintf('Sorting data by date\n')
datetimeUniqueDates = unique(xboxData{4});
uniqDateNum = length(datetimeUniqueDates);

samples = cell(uniqDateNum,1);
samplesID = cell(uniqDateNum,1);
samplesDemo = cell(uniqDateNum,1);
for d=1:uniqDateNum
    idxs = datetimeUniqueDates(d) == xboxData{4};
    samples{d} = responses(idxs);
    samplesID{d} = xboxData{2}(idxs);
    samplesDemo{d} = cell(length(samplesID{d}),11);
    for i=1:length(samplesID{d})
        demoIdx = find(xboxDemographics{2} ==  samplesID{d}(i));
        samplesDemo{d}(i,:) = ...
            {1, xboxDemographics{3}{demoIdx}, xboxDemographics{5}{demoIdx}, ...
            xboxDemographics{4}{demoIdx}, xboxDemographics{6}{demoIdx}, xboxDemographics{11}{demoIdx}, ...
            xboxDemographics{10}{demoIdx}, xboxDemographics{9}{demoIdx}, 1  ...
            xboxDemographics{7}{demoIdx}, 1};
    end
end

%% Sort data by state
fprintf('Sorting data by state\n')
samplesByState = cell(uniqDateNum,1);
uniqueStates = unique(xboxDemographics{3});
uniqStateNum = length(uniqueStates);
for d=1:uniqDateNum
    samplesByState{d} = cell(uniqStateNum,1);
end

% Convert state to full name and sort
for s=1:uniqStateNum
    uniqueStates{s} = StateLookup(uniqueStates{s});
end
for s=1:length(xboxDemographics{3})
    xboxDemographics{3}{s} = StateLookup(xboxDemographics{3}{s});
end

assert(length(unique(uniqueStates)) == uniqStateNum);
uniqueStates = sort(uniqueStates);
electionData = load('../survey-data-bcs-data-store/election/2012.mat');
assert(length(uniqueStates) == length(electionData.STATE));
for s=1:uniqStateNum
    assert(strcmp(uniqueStates{s},electionData.STATE{s}'),'%s is not equal to %s',uniqueStates{s},electionData.STATE{s});
end

for s=1:uniqStateNum
    stateName = uniqueStates{s};
    demoStateIdxs = strcmpi(xboxDemographics{3},stateName);
    usersInState = xboxDemographics{2}(demoStateIdxs);
    for d=1:uniqDateNum
        idxs = xboxData{4} == datetimeUniqueDates(d) & ismember(xboxData{2},usersInState);
        assert(~isempty(idxs));
        samplesByState{d}{s} = responses(idxs);
    end
end

%% Save Data
save('../survey-data-bcs-data-store/XboxPoll/XboxData.mat','samples','samplesByState','datetimeUniqueDates','samplesID','samplesDemo')