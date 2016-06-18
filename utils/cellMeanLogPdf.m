function [logpdf] = cellMeanLogPdf(params,predModel,timeMeans,cellSlopePos,cellInterceptPos,allVoteObama,allTotals,keepExamples)
    logpdf = 0;
    assert(size(cellSlopePos,2) == size(cellInterceptPos,2));
    numCells = size(cellSlopePos,2);
    
    %% Likelihood
    numAllExamples = length(allVoteObama);
    
    cellSlopes = sum(params(cellSlopePos),1);
    cellIntercepts = sum(params(cellInterceptPos),1);
    
    allParams = [cellIntercepts' cellSlopes'];
    allPreds = predModel(allParams,timeMeans);
    
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

