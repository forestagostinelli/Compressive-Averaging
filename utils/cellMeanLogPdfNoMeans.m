function [logpdf] = cellMeanLogPdfNoMeans(params,predModel,obamaFrac,cellSlopePos,cellInterceptPos,allVoteObama,allTotals,keepExamples)
    assert(size(cellSlopePos,2) == size(cellInterceptPos,2));    
    logpdf = 0;

    %% Likelihood
    cellSlopes = sum(params(cellSlopePos),1);
    cellIntercepts = sum(params(cellInterceptPos),1);

    allParams = [cellIntercepts' cellSlopes'];
    allPreds = predModel(allParams,obamaFrac');
    
    allPreds = allPreds';
    allPreds = allPreds(:);
    keepExamples = keepExamples';
    keepExamples = keepExamples(:);
    allPreds = allPreds(keepExamples);
        
    binomialPDF = max(binopdf(allVoteObama,allTotals,allPreds),realmin('double'));
    logpdf = logpdf + sum(log(binomialPDF));
        
    %% Priors
    logpdf = logpdf + sum(log(normpdf(params,0,1)));
end

