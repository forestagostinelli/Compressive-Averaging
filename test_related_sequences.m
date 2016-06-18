clear
eduData = load('education_ratio_0.1.mat');
categoryMeans = eduData.categoryMeans;
categorySamples = eduData.categorySamples;
timeD = wmpdictionary(45, 'LstCpt', {{'wpsym4', 5}});
timeK = 3;

exitValsData = load('education_exit_vals.mat');
exitVals = exitValsData.exitVals;
newExitVals = exitVals;
newExitVals(1) = exitVals(4);
newExitVals(2) = exitVals(1);
newExitVals(3) = exitVals(2);
newExitVals(4) = exitVals(3);
exitVals = newExitVals;

seqLen = cellfun(@length,categoryMeans);
totalSeqLen  = sum(seqLen);

cellMeans = cell2mat(categoryMeans);
cellMeans = cellMeans';
cellSamples = {};
endPos = zeros(length(seqLen),1);
for s=1:length(categorySamples)
    endPos(s) = sum(seqLen(1:s));
    cellSamples = {cellSamples{:}, categorySamples{s}{:}};
end

cellSigma = cellfun(@var,cellSamples);
cellLen = cellfun(@length,cellSamples);
%{
keepIdxs = find(cellLen > 0);
cellLen = cellLen(keepIdxs);
cellSamples = cellSamples(keepIdxs);
cellSigma = cellSigma(keepIdxs);
cellMeans = cellMeans(keepIdxs);
%}

jsEndVals = zeros(1,length(categorySamples));
csavgEndVals = zeros(1,length(categorySamples));

%{
for s=1:length(categorySamples)
    js = JamesSteinAvg(cellfun(@var,categorySamples{s}));

    jsAvg = js.avg(categorySamples{s},categoryMeans{s},cellfun(@length,categorySamples{s}));
    jsEndVals(s) = jsAvg(end);
end
%}

for s=1:length(categorySamples)
    csavg = CSAvg(timeD, timeK, cellfun(@var,categorySamples{s}));

    csAvg = csavg.avg(categorySamples{s},categoryMeans{s},cellfun(@length,categorySamples{s}));
    csavgEndVals(s) = csAvg(end);
end

js = JamesSteinAvg(cellSigma);

jsAvg = js.avg(cellSamples,cellMeans,cellLen);
jsEndVals = jsAvg(endPos);

jsErr = mean(abs(100*(jsEndVals'-1) - 100*(exitVals-1)))

avgEndVals = cellMeans(endPos);
avgErr = mean(abs(100*(avgEndVals'-1) - 100*(exitVals-1)))


csAvgErr = mean(abs(100*(csavgEndVals'-1) - 100*(exitVals-1)))

