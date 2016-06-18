function [metrics] = record_metrics(curr_cells,methodMeans,demosToAnalyze,catToAnalyze,trueMeans,metrics,methodName,exitPollData,r,s)
    methodMetrics = metrics(methodName);
    curr_Metrics = containers.Map();
    
    %% Category accuracy
    if strcmpi('all',demosToAnalyze{1})
        if (isempty(curr_cells))
            [~,postErrorCountry] = twoPartyElectionError(methodMeans,1,0,1);
        else
            [~,postErrorCountry] = twoPartyElectionError(curr_cells{end},1,0,1);
        end
        curr_Metrics('Total Country Error') = postErrorCountry;
    else
        if (isempty(curr_cells))
            numGroups = length(demosToAnalyze);
            categoryAcc = zeros(numGroups,1);
            for g=1:numGroups
                categoryAcc(g) = get_acc(methodMeans,demosToAnalyze{g},catToAnalyze{g},1,exitPollData);
            end
        else
            numGroups = length(demosToAnalyze);
            categoryAcc = zeros(numGroups,1);
            for g=1:numGroups
                categoryAcc(g) = get_acc(curr_cells{end},demosToAnalyze{g},catToAnalyze{g},1,exitPollData);
            end
        end

        %curr_rawMetrics('Median Category Absolute Difference') = median(abs(rawCategoryAcc));
        %curr_rawMetrics('Mean Category Absolute Difference') = mean(abs(rawCategoryAcc));
        curr_Metrics('Median Absolute Difference') = median(abs(categoryAcc));
        curr_Metrics('Mean Absolute Difference') = mean(abs(categoryAcc));

        %% Compare to ground truth signal
        %{
        sqrtMse = 0;
        demoNames = keys(trueMeans);
        numSeen = 0;
        for d=1:length(demoNames)
            catMeans = trueMeans(demoNames{d});
            estCatMeans = methodMeans(demoNames{d});
            catNames = keys(catMeans);
            for cat=1:length(catNames)
                trueMean = catMeans(catNames{cat});
                estMean = estCatMeans(catNames{cat});
                sqrtMse = sqrtMse + sqrt(mean((trueMean - estMean).^2));
                numSeen = numSeen + 1;
            end
        end
        sqrtMse = sqrtMse/numSeen;
        curr_Metrics('Sqrt of MSE') = sqrtMse;
        %}

        %% State Accuracy
        if (~isempty(methodMeans))
            if ismember('state',lower(keys(methodMeans)))
                postErrorPerState = twoPartyElectionError(methodMeans,1,0);

                curr_Metrics('Median State Absolute Difference') = median(abs(postErrorPerState));
                curr_Metrics('Mean State Absolute Difference') = mean(abs(postErrorPerState));
            end
        end
    end
    
    methodMetrics{s,r} = curr_Metrics;
    metrics(methodName) = methodMetrics;
end

