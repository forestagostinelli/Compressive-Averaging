function plot_results(methodNames,methodMeans,trueMeans,ratios)
    %% Compared accuracy to ground truth signal
    figure;
    runner = Runner({});
    runner.truth = trueMeans;
    runner.ratios = ratios;
    for m=1:length(methodNames)
        methodName = methodNames{m};
        methodMean = methodMeans(methodName);
        [runner.score(methodName), runner.score_std(methodName)] = runner.metric(methodMean, runner.truth);
    end
    subplot(221);
    runner.plot_score();
    
    %% Plot ground truth and estimated signals
    subplot(222);
    xbox = 1;
    xaxis = 1:length(trueMeans);
    trueMeansAdj = trueMeans;
    if xbox == 1
        trueMeansAdj = 100*(trueMeansAdj-1);
    end
    
    legendInfo = cell(length(methodNames)+1,1);
    plot(xaxis,trueMeansAdj,'-o');
    legendInfo{1} = 'True Means';
    hold on;
    for m=1:length(methodNames)
        methodName = methodNames{m};
        legendInfo{1+m} = methodName;
        methodMean = methodMeans(methodName);
        mu = methodMean{end,end};
        if xbox == 1
            mu = 100*(mu-1);
        end
        plot(xaxis,mu);
        hold on;
    end
    legend(legendInfo);
    if xbox == 1
        fiftyMark = 50*ones(length(xaxis),1);
        fiftyTwoMark = 51.96*ones(length(xaxis),1);
        plot(xaxis,fiftyMark,xaxis,fiftyTwoMark,'--');
    end
    hold off;
    
    %% Compare last day to actual voter percent
    %{
    subplot(223)
    trueMeansScore = twoPartyElectionError(100*(trueMeans(end)-1),[]);
    xaxis = ratios;
    trueMeansScoreMark = trueMeansScore*ones(length(xaxis),1);
    plot(xaxis,trueMeansScoreMark,'-o');
    legendInfo = cell(length(methodNames)+1,1);
    legendInfo{1} = 'True Means';
    hold on;
    for m=1:length(methodNames)
        methodName = methodNames{m};
        legendInfo{1+m} = methodName;
        methodMean = methodMeans(methodName);
        ratioErr = zeros(size(methodMean,2),1);
        for r=1:length(ratios)
            finalVals = zeros(size(methodMean,1),1);
            for s=1:size(methodMean,1)
                finalVals(s) = methodMean{s,r}(end);
            end
            ratioErr(r) = twoPartyElectionError(100*(finalVals-1),[]);
        end
        plot(xaxis,ratioErr,'-x')
        hold on;
    end
    legend(legendInfo);
    xlabel('Ratio');
    ylabel('Mean Absolute Error')
    hold off;
    %}
end