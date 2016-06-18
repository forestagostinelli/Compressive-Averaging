function plot_metrics(metrics,ratios)
    methodNames = keys(metrics);
    methodNames = sortMethods(methodNames);
    methodMetrics = metrics(methodNames{1});
    metricNames = keys(methodMetrics{1,1});
    numMetrics = length(metricNames);

    
    for i=1:numMetrics
       subplot(1,numMetrics,i);
       metricName = metricNames{i};
       for m=1:length(methodNames)
           methodName = methodNames{m};
           methodMetrics = metrics(methodName);
           methodMetricVals = zeros(length(ratios),1);
           for r=1:length(ratios)
               ratio = ratios(r);
               seedNum = size(methodMetrics,1);
               if ratio == 1
                   seedNum = 1;
               end
               for s=1:seedNum
                   vals = methodMetrics{s,r};
                   methodMetricVals(r) = methodMetricVals(r) + vals(metricName);
               end
               methodMetricVals(r) = methodMetricVals(r)/seedNum;
           end
           lineType = getLineStyle(methodName);
           
           h = plot(100*ratios,methodMetricVals,lineType);
           set(gca,'FontSize',25,'fontWeight','bold');
           set(h, 'LineWidth', 4);
           ylim([0 100])
           hold on;
       end
       hold off;
       title(metricName)
       xlabel('Percentage of Samples')
       ylabel(metricName)
       legend(methodNames)
    end
end

