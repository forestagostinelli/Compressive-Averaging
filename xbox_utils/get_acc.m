function [acc,estVal,exitVal] = get_acc(cells,demoNames,catNames,poststrat,exitPollData)
    %% Initialize
    isCell = strcmpi(class(cells),'Cells');

    exit_poll = exitPollData.exit_poll;
    exitHeader = lower(exitPollData.header);
    
    numExitPoll = size(exit_poll,1);
    presCol = strcmpi(exitHeader,'vote');
    exitWeightCol = strcmpi(exitHeader,'weight');

    %% Get cell estimate
    if isCell
        estVal = getCellGroupEst(cells,demoNames,catNames,poststrat);
    else
        demoNamesString = strjoin(sort(demoNames));
        catNamesString = strjoin(sort(catNames));
        catMap = cells(demoNamesString);
        catMeans = catMap(catNamesString);
        estVal = catMeans(end);
    end
    
    %% Get exit poll estimate
    pplIdx = ones(numExitPoll,1);
    for d=1:length(demoNames)
        demoPos = strcmpi(exitHeader,demoNames{d});
        pplIdx = pplIdx & strcmpi(exit_poll(:,demoPos),catNames(d));
    end
    assert(sum(pplIdx) > 0,'No people found with demographic info in exit poll data');

    exitWeights = [exit_poll{pplIdx,exitWeightCol}];
    exitWeights = exitWeights/sum(exitWeights);
    exitVal = sum([exit_poll{pplIdx,presCol}].*exitWeights);
    %exitVal = mean([exit_poll{pplIdx,presCol}]);

    %% Get accuracy
    acc = 100*(estVal-1) - 100*(exitVal-1);
end

