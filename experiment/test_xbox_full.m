%% Load data
clear
%close all
aggregatePrev = 0;
aggregateCellsPrev = 0;
demoNames = {'age','sex','race','education','party','ideology'};
%demoNames = {'age','sex','state'};
demoNamesString = strjoin(sort(demoNames),'_');
totalDataFile = sprintf('../createdData/XboxCells/ratio_%0.3f_seed_%i_aggPrev_%i_demo_%s.mat',1,1,aggregatePrev,demoNamesString);
exitPollData = load('../survey-data-bcs-data-store/XboxPollDemo/exit_poll_2012.mat'); 
load('../survey-data-bcs-data-store/XboxPollDemo/pop_data.mat');

cellsByTime = load(totalDataFile,'curr_cells');
cellsByTime = cellsByTime.curr_cells;
numCells = cellsByTime{1}.numCells;

allSamples = load(totalDataFile,'curr_samples');
allSamples = allSamples.curr_samples;

%% Adjust params
adjustCells = 0;
adjustType = 2;
poststrat = 1;
modelAggregatePrev = 0;
if adjustCells == 1
    if adjustType == 0 || adjustType == 2
        totalParamFileName = sprintf('xbox_utils/meanPredictionModels/no_means_ratio_%0.3f_seed_%i_aggPrev_%i_modelAggPrev%i_demo_%s.mat',1,1,aggregatePrev,modelAggregatePrev,demoNamesString);
    elseif adjustType == 1
        totalParamFileName = sprintf('xbox_utils/meanPredictionModels/shared_no_inidividual_ratio_%0.3f_seed_%i_aggPrev_%i_demo_%s.mat',1,1,aggregatePrev,demoNamesString);
    end

    totalAdjustmentModel = load(totalParamFileName);
    cellsByTime = Cells.adjustCellsMult(cellsByTime,totalAdjustmentModel,adjustType);
end

%% aggregate cells
cellsByTime = aggregateCells(cellsByTime,aggregateCellsPrev);

%% Make basis
weightName = 'weight';

sigma2 = cellfun(@var, allSamples);
timeD = wmpdictionary(length(allSamples), 'LstCpt', {{'wpsym4', 5}});
%timeD = wmpdictionary(length(allSamples), 'LstCpt', {'dct'});    % choose dictionary;

timeD = timeD(:, 1:8);
timeK = 3;
%nn = NeuralNetworkAvg(timeD,timeK,sigma2);
load('../createdData/trainedNNs/xbox.mat')

%{
stateAdjMat = load('../survey-data-bcs-data-store/election/adjacency_noDC_noHI.mat','matrix');
stateAdjMat = stateAdjMat.matrix;
L = laplacian(stateAdjMat);
[U, S] = eig(L);
K = @(t)(U * diag(exp(-t * diag(S))) * U');
stateD = K(10) * eye(size(stateAdjMat,1));
stateK = 5;
%}

%% Make run parameters
ratios = [1];
seeds = 1;

solveType = 'cellMeans';

demosToAnalyze = {{'age'},{'age'},{'age'},{'age'},{'sex'},{'sex'},...
    {'race'},{'race'},{'race'},{'race'},{'education'},{'education'},{'education'},{'education'},...
    {'ideology'},{'ideology'},{'ideology'},{'party'},{'party'},{'party'}};
catToAnalyze = {{'18-29'},{'30-44'},{'45-64'},{'65+'},{'male'},{'female'},...
    {'white'},{'black'},{'hispanic'},{'other'}...
    {'didn''t graduate from HS'},{'high school graduate'},{'some college'},{'college graduate'}...
    {'liberal'},{'moderate'},{'conservative'},{'democrat'},{'other'},{'republican'}};
demosToAnalyze2 = {{'ideology','sex'},{'ideology','party'},{'sex','party'},...
    {'sex','ideology'},{'race','ideology'},{'race','party'},...
    {'race','party'},{'sex','party'},{'sex','party'},...
    {'party','education'},{'sex','age'},{'sex','education'},...
    {'race','age'},{'sex','age'},{'race','education'},...
    {'sex','education'},{'ideology','party'},{'sex','education'},...
    {'sex','party'},{'sex','ideology'},{'race','sex'},...
    {'race','education'},{'race','sex'},{'ideology','education'},...
    {'race','ideology'},{'sex','ideology'},{'race','party'},...
    {'race','ideology'}};
catToAnalyze2 = {{'conservative','male'},{'conservative','republican'},{'male','republican'},...
    {'female','conservative'},{'white','conservative'},{'white','republican'},...
    {'white','democrat'},{'female','republican'},{'female','democrat'}...
    {'democrat','college graduate'},{'male','45-64'},{'male','college graduate'},...
    {'white','30-44'},{'female','45-64'},{'white','some college'},...
    {'female','some college'},{'liberal','democrat'},{'female','college graduate'}...
    {'male','other'},{'male','moderate'},{'white','male'},...
    {'white','college graduate'},{'white','female'},{'moderate','college graduate'},...
    {'white','liberal'},{'female','moderate'},{'white','other'},...
    {'white','moderate'}};

%demosToAnalyze = {{'sex'},{'race'},{'age'},{'education'}};
%catToAnalyze = {{'male'},{'white'},{'18-29'},{'some college'}};
%demosToAnalyze = {{'all'}};
%catToAnalyze = {{'all'}};

assert(length(demosToAnalyze) == length(catToAnalyze))

adjustStateTime = 1;
adjustState = 0;

trueMeansDemo = containers.Map();

%% Initialize variables
methodNames = {'Avg','JS','MTAvg','OMP','DNN'};
allMeans = containers.Map();
new_samples = containers.Map();
metrics = containers.Map();
demoMeans = containers.Map();

for m = 1:length(methodNames)
    methodName = methodNames{m};
    metrics(methodName) = cell(length(seeds),length(ratios));
    methodDemoMeans = containers.Map();
    for d=1:length(demosToAnalyze)
        methodDemoMeans(strjoin(sort(demosToAnalyze{d}))) = containers.Map();
    end
    demoMeans(methodName) = methodDemoMeans;
end

%% Run methods for different ratios and seeds
for r=1:length(ratios)
    ratio = ratios(r)
    for s=1:length(seeds)
        %% Load data
        seed = seeds(s);
        if ratio == 1
            seed = 1;
        end
        currDataFileName = sprintf('../createdData/XboxCells/ratio_%0.3f_seed_%i_aggPrev_%i_demo_%s.mat',ratio,seed,aggregatePrev,demoNamesString);
        curr_cells = load(currDataFileName,'curr_cells');
        curr_cells = curr_cells.curr_cells;
        curr_samples = load(currDataFileName,'curr_samples');
        curr_samples = curr_samples.curr_samples;
        curr_means = cellfun(@mean,curr_samples);
        
        %% Load adjustment model
        if (adjustType == 0 || adjustType == 2) && adjustCells
            paramFileName = sprintf('xbox_utils/meanPredictionModels/no_means_ratio_%0.3f_seed_%i_aggPrev_%i_modelAggPrev%i_demo_%s.mat',ratio,seed,aggregatePrev,modelAggregatePrev,demoNamesString);
            adjustmentModel = load(paramFileName);
            assert(length(adjustmentModel.timeParams) == length(curr_cells))
        elseif adjustType == 1 && adjustCells
            paramFileName = sprintf('xbox_utils/meanPredictionModels/shared_no_inidividual_ratio_%0.3f_seed_%i_aggPrev_%i_demo_%s.mat',ratio,seed,aggregatePrev,demoNamesString);
            adjustmentModel = load(paramFileName);
            assert(length(adjustmentModel.params) == numCells)
        end

        %% Adjust cell estimates
        if adjustCells
            curr_cells = Cells.adjustCellsMult(curr_cells,adjustmentModel,adjustType);
        end

        %% cellMeans method
        if strcmpi(solveType,'cellMeans')
            % Get means for each cell. Use temporal relationship amongst cells
            
            %% Get estimates for specific category for each timepoint
            for d=1:length(demosToAnalyze)
                %% Get data split up into analyze demo cells
                demosToAnalyzeString = strjoin(sort(demosToAnalyze{d}));
                catName = strjoin(sort(catToAnalyze{d}));

                cellsHeader =  lower(curr_cells{1}.header);
                cellDemoPos = strcmpi(cellsHeader,demosToAnalyzeString);
                
                %% Initialize some variables
                for m = 1:length(methodNames)
                    methodDemoMeans = demoMeans(methodName);
                    catsMap = methodDemoMeans(demosToAnalyzeString);
                    catsMap(catName) = containers.Map();
                    methodDemoMeans(demosToAnalyzeString) = catsMap;
                    demoMeans(methodName) = methodDemoMeans;
                end
                
                %% Get true means
                catTrueMeans = containers.Map();
                trueMean = zeros(length(cellsByTime),1);
                %{
                for t=1:length(cellsByTime)
                    trueMean(t) = getCellGroupEst(cellsByTime{t},demosToAnalyze{d},catToAnalyze{d},poststrat,adjustCells);
                end
                %}
                catTrueMeans(catName) = trueMean;
                %{
                figure
                plot(trueMean,'k');
                hold on;
                %}
                trueMeansDemo(demosToAnalyzeString) = catTrueMeans;
                
                %% Get poststrat cell estimates for demographic
                categoryMeans = zeros(length(curr_cells),1);
                categorySamples = cell(length(curr_cells),1);
                categoryLen = zeros(length(curr_cells),1);
                categoryVar = zeros(length(curr_cells),1);

                % Precompute category values
                prevIdxsNotFilled = [];
                lastIdxFilled = -1;
                for t=1:length(curr_cells)
                    cells = curr_cells{t};

                    if strcmpi('all',demosToAnalyzeString)
                        estVal = cells.getPostStratEst();
                        cellIdxsTotal = true(numCells,1);
                        cellIdxs = true(numCells,1) & cells.populatedCells;
                        cellSamples = [cells.cellSamples{cellIdxs}];
                    else
                        [estVal, cellIdxs, cellSamples, cellIdxsTotal] = getCellGroupEst(cells,demosToAnalyze{d},catToAnalyze{d},poststrat,adjustCells);
                    end

                    if (max(cells.numInCell(cellIdxs)) == 0)
                        if lastIdxFilled > 0
                            categoryMeans(t) = categoryMeans(lastIdxFilled);
                            categorySamples{t} = categorySamples{lastIdxFilled};
                            categoryLen(t) = categoryLen(lastIdxFilled);
                            categoryVar(t) = categoryVar(lastIdxFilled);
                            continue;
                        else
                            prevIdxsNotFilled = [prevIdxsNotFilled t];
                            continue;
                        end
                    end

                    lastIdxFilled = t;

                    occupiedCellIDxs = cellIdxs;
                    occupiedCellIDxs(cells.numInCell == 0) = 0;
                    
                    categoryMeans(t) = estVal;
                    if categoryMeans(t) < 0.999 || categoryMeans(t) > 2.0001
                        error('Error: Estimatied value not between 1 and 2');
                    end
                    
                    categorySamples{t} = cellSamples;
                    categoryLen(t) = length(cellSamples);
                    if adjustCells == 1
                        diffRatio2 = length(find(cellIdxsTotal))/length(find(occupiedCellIDxs));
                        cellWeights = cells.cellWeights;
                        diffRatio = sum(cells.cellWeights(cellIdxsTotal))/sum(cells.cellWeights(occupiedCellIDxs));
                        %categoryLen(t) = categoryLen(t)*diffRatio;
                    end

                    if strcmpi('all',demosToAnalyzeString)
                        allEstVal = cellsByTime{t}.getPostStratEst();
                        allCellIdxs = true(numCells,1) & cellsByTime{t}.populatedCells;
                        allCellSamples = [cellsByTime{t}.cellSamples{allCellIdxs}];
                    else
                        [~, ~, allCellSamples] = getCellGroupEst(cellsByTime{t},demosToAnalyze{d},catToAnalyze{d},0,adjustCells);
                        [allEstVal, ~, ~] = getCellGroupEst(cellsByTime{t},demosToAnalyze{d},catToAnalyze{d},poststrat,adjustCells);
                    end
                    categoryVar(t) = var(allCellSamples);
                    %prob = allEstVal-1;
                    %categoryVar(t) = prob*(1-prob);
                    
                    if ~isempty(prevIdxsNotFilled)
                        for p=1:length(prevIdxsNotFilled)
                            prevIdx = prevIdxsNotFilled(p);
                            categoryMeans(prevIdx) = categoryMeans(t);
                            categorySamples{prevIdx} = categorySamples{t};
                            categoryLen(prevIdx) = categoryLen(t);
                            categoryVar(prevIdx) = categoryVar(t);
                        end
                        prevIdxsNotFilled = [];
                    end
                end
                
                methodMu_hs = containers.Map();
                for m = 1:length(methodNames)
                    methodMu_hs(methodNames{m}) = zeros(length(curr_cells),1);
                end

                %{
                if strcmpi('state',demosToAnalyzeString) && adjustState
                    cells_mu_hs_state = cell(numCatsAnalyze,1);
                    for cat=1:numCatsAnalyze
                        methodMu_hs = containers.Map();
                        for m = 1:length(methodNames)
                            methodMu_hs(methodNames{m}) = zeros(length(curr_cells),1);
                        end
                        cells_mu_hs_state{cat} = methodMu_hs;
                    end

                    %% Adjust category means by state for each timepoint
                    for t=1:length(curr_cells)
                        stateSamples = cell(numCatsAnalyze,1);
                        cellSigma = zeros(numCatsAnalyze,1);
                        cellMeans = zeros(numCatsAnalyze,1);
                        cellLen = zeros(numCatsAnalyze,1);
                        for cat=1:numCatsAnalyze
                            cellSigma(cat) = categoryVar{cat}(t);
                            stateSamples{cat} = categorySamples{cat}{t};
                            cellMeans(cat) = categoryMeans{cat}(t);
                            cellLen(cat) = categoryLen{cat}(t);
                        end
                        cellSigma(isnan(cellSigma)) = max(cellSigma);
                        
                        for m = 1:length(methodNames)
                            methodName = methodNames{m};
                            runner = Runner(stateSamples);
                            if strcmpi('avg',methodName)
                                runner.add_method(SampleAvg());
                            elseif strcmpi('csavg',methodName) || strcmpi('csavgShared',methodName)
                                runner.add_method(CSAvg(stateD, stateK, cellSigma));
                            elseif strcmpi('js',methodName)
                                runner.add_method(JamesSteinAvg(cellSigma));
                            elseif strcmpi('mt-avg',methodName)
                                runner.add_method(MTAvg(1, cellSigma));
                            end

                            runner.run_all(1,1,cellMeans,cellLen);
                            for cat=1:numCatsAnalyze
                                mu_hs = cells_mu_hs_state{cat};
                                if strcmpi(methodName,'csavgShared')
                                    run_mu_h = runner.mu_h('csavg');
                                else
                                    run_mu_h = runner.mu_h(methodName);
                                end
                                run_means = run_mu_h{1,1};

                                means = mu_hs(methodName);
                                means(t) = run_means(cat);

                                mu_hs(methodName) = means;
                                cells_mu_hs_state{cat} = mu_hs;
                            end
                        end
                    end
                    cells_mu_hs = cells_mu_hs_state;
                end
                %}

                if(~strcmpi('state',demosToAnalyzeString) || adjustStateTime == 1 || adjustState == 0)
                    %% Get coeffs for total means for bootstrap OMP
                    totalN = cellfun(@length,curr_samples);
                    totalSigma2 = cellfun(@var,allSamples);
                    if ismember('csavgShared',methodNames)
                        if poststrat
                            totalMeans = Cells.getPostStratEstMult(curr_cells);
                        else
                            totalMeans = Cells.getRawEstMult(curr_cells);
                        end
                        [mu_h,bootstrapAlpha,bootstrapSupp,Atotal] = ...
                            csAvgCompute(curr_samples,totalSigma2,totalMeans,totalN,timeD,timeK,0);
                    end
                    
                    %% Adjust means for each cell
                    cellSamples = categorySamples;
                    cellMeans = categoryMeans;
                    cellSigma = zeros(length(curr_cells),1);
                    for t=1:length(curr_cells)
                        cellSigma(t) = categoryVar(t);
                    end
                    cellSigma(isnan(cellSigma)) = max(cellSigma);

                    cellLen = categoryLen;

                    assert(min(cellLen) > 0);

                    %% Run methods
                    methodMu_hs = containers.Map();
                    for m = 1:length(methodNames)
                        runner = Runner(cellSamples);
                        methodName = methodNames{m};
                        if strcmpi(methodName,'Avg')
                            runner.add_method(SampleAvg());
                        elseif strcmpi(methodName,'OMP')
                            runner.add_method(CSAvg(timeD, timeK, cellSigma));
                        elseif strcmpi(methodName,'csavg-boost')
                            runner.add_method(CSAvgBoostrap(timeD, timeK, cellSigma));
                        elseif strcmpi(methodName,'JS')
                            runner.add_method(JamesSteinAvg(cellSigma));
                        elseif strcmpi(methodName,'MTAvg')
                            runner.add_method(MTAvg(1, cellSigma));
                        elseif strcmpi(methodName,'DNN')
                            runner.add_method(NeuralNetworkAvg(timeD,timeK,cellSigma,nn.neural_network, nn.shrinkage_nn));
                        else
                            continue;
                        end
                        if strcmpi('state',demosToAnalyzeString) && adjustState
                            methodCellMeans = methodMu_hs(methodName);
                        else
                            methodCellMeans = cellMeans;
                        end
                        runner.run_all(1,1,methodCellMeans,cellLen);
                        run_mean = runner.mu_h(methodName);
                        methodMu_hs(methodName) = run_mean{1,1};
                    end


                    %% CS avg shared
                    if ismember('csavgShared',methodNames)
                        methodName = 'csavgShared';
                        if strcmpi('state',demosToAnalyzeString) && adjustState
                            methodCellMeans = methodMu_hs(methodName);
                        else
                            methodCellMeans = cellMeans;
                        end

                        mu_h = ...
                            csAvgCompute(cellSamples,cellSigma,methodCellMeans,cellLen,timeD,timeK,1,bootstrapAlpha,bootstrapSupp,Atotal);
                        methodMu_hs('csavgShared') = mu_h;
                    end
                end
                %% Update cell values and record results
                for m = 1:length(methodNames)
                    %% Update cell values
                    methodName = methodNames{m};
                    methodDemoMeans = demoMeans(methodName);
                    catsMap = methodDemoMeans(demosToAnalyzeString);
                    catsMap(catName) = methodMu_hs(methodName);
                    methodDemoMeans(demosToAnalyzeString) = catsMap;
                    demoMeans(methodName) = methodDemoMeans;

                    %% Aggregate cells
                    methodDemoMeans = demoMeans(methodName);
                    catsMap = methodDemoMeans(demosToAnalyzeString);
                    catMean = catsMap(catName);
                    numAtTimepoint = cellfun(@length,categorySamples);

                    catMean = aggregateCells([],aggregateCellsPrev,catMean,numAtTimepoint);

                    catsMap(catName) = catMean;
                    methodDemoMeans(demosToAnalyzeString) = catsMap;
                    demoMeans(methodName) = methodDemoMeans;
                end
            end
            
            %% Get Metrics
            for m = 1:length(methodNames)
                methodName = methodNames{m};
                metrics = ...
                    record_metrics([],demoMeans(methodName),demosToAnalyze,catToAnalyze,trueMeansDemo,metrics,methodName,exitPollData,r,s);
            end

        elseif strcmpi(solveType,'wholeSampleMeans')
            cellsToAdjust = [];
            for c = 1:numCells
                numByTime = cellfun(@(x) x.numInCell(c),curr_cells);
                if min(numByTime) > 0
                    cellsToAdjust = [cellsToAdjust c];
                end
            end
            
            cellMeans = cell(length(cellsToAdjust),1);
            
            fprintf('There are %i cells to adjust\n',length(cellsToAdjust));
            
            %% Run methods
            for c=1:length(cellsToAdjust)
                cellToAdjust = cellsToAdjust(c);
                cellSamples = cell(length(curr_cells),1);
                cellSigma2 = cellfun(@(x) var(x.cellSamples{cellToAdjust}),cellsByTime);
                cellMean = cellfun(@(x) x.cellValues(cellToAdjust),curr_cells);
                for t=1:length(curr_cells)
                    cellSamples{t} = curr_cells{t}.cellSamples{cellToAdjust};
                    prob = cellsByTime{t}.cellValues(cellToAdjust)-1;
                    %cellSigma2(t) = prob*(1-prob);
                    
                end
                runner = Runner(cellSamples);
                for m = 1:length(methodNames)
                    methodName = methodNames{m};
                    if strcmpi(methodName,'avg')
                        runner.add_method(SampleAvg());
                    elseif strcmpi(methodName,'csavg')
                        runner.add_method(CSAvg(timeD, timeK, cellSigma2));
                    elseif strcmpi(methodName,'js')
                        runner.add_method(JamesSteinAvg(cellSigma2));
                    elseif strcmpi(methodName,'mt-avg')
                        runner.add_method(MTAvg(1, cellSigma2));
                    else
                        continue;
                    end
                end

                runner.run_all(1,1,cellMean);
                cellMeans{c} = runner.mu_h;
            end
            
            %% Record results
            for m = 1:length(methodNames)
                methodName = methodNames{m};
                

                %% Change means in cell
                for c=1:length(cellsToAdjust)
                    mu_hs = cellMeans{c};
                    mu_h = mu_hs(methodName);
                    mu = mu_h{1,1};
                    cellToAdjust = cellsToAdjust(c);
                    for t=1:length(curr_cells)
                        curr_cells{t}.cellValues(cellToAdjust) = mu(t);
                    end
                end

                %% adjust samples according to new mean
                %{
                new_mean = mu_h{1,1};
                
                if adjustCells
                    allParams = cell2mat(adjustmentModel.params);
                    for t=1:length(curr_cells)
                        timeMean = new_mean(t);
                        curr_cells{t}.cellValues(:) = adjustmentModel.predModel(allParams,(timeMean-1))+1;
                        curr_cells{t}.cellWeights = ...
                            curr_cells{t}.unNormalizedCellWeights./sum(curr_cells{t}.unNormalizedCellWeights);
                    end
                end
                %}
                
                %% Aggregate cells
                %curr_cells = aggregateCells(curr_cells,aggregateCellsPrev);
                % TODO must remember to change to original but also update
                % cell adjustments made by adjustment model
                
                %% Get metrics
                metrics = ...
                    record_metrics(curr_cells,[],demosToAnalyze,catToAnalyze,[],metrics,methodName,exitPollData,r,s);
                
                %% Reload cells
                %curr_cells = load(currDataFileName,'curr_cells');
                %curr_cells = curr_cells.curr_cells;
            end
        end
    end
end

figure;
plot_metrics(metrics,ratios);

%cPlot = 2;
%plot_results(methodNames,methodCategoryMeans{cPlot},trueCategoryMeans{cPlot},ratios);

%{
%% compare to with poststratified signal from all samples
cellsByTime = load(totalDataFile,'curr_cells');
cellsByTime = cellsByTime.curr_cells;
for t=1:length(cellsByTime)
    timeMean = cellsByTime{t}.totalMean;
    for c=1:numCells
        cellsByTime{t}.cellValues(c) = predModel(adjustmentModel.params{c},(timeMean-1))+1;
    end
end

rawEst = Cells.getRawEstMult(cellsByTime);
categoryAcc = plot_category_acc(cellsByTime{end},0,0,exitPollData);
fullRawAccs = [median(abs(categoryAcc)) mean(abs(categoryAcc))]

postStratEst = Cells.getPostStratEstMult(cellsByTime);
categoryAcc = plot_category_acc(cellsByTime{end},1,0,exitPollData);
fullPostAccs = [median(abs(categoryAcc)) mean(abs(categoryAcc))]


figure
subplot(211)
groupAcc = plot_group_acc(curr_cells{end},0,1);
title(sprintf('Difference for Raw Data. Med: %f, Mean: %f',median(abs(groupAcc)),mean(abs(groupAcc))))
subplot(212)
groupAcc = plot_group_acc(curr_cells{end},1,1);
title(sprintf('Difference for Poststratified Data Med: %f, Mean: %f',median(abs(groupAcc)),mean(abs(groupAcc))))
%}

%% Plot raw and postrat estimates accuracies categories
%{
figure
categoryAcc = plot_category_acc(curr_cells{end},0,1);
rawAccs = [median(abs(categoryAcc)) mean(abs(categoryAcc))]
figure
categoryAcc = plot_category_acc(curr_cells{end},1,1);
postAccs = [median(abs(categoryAcc)) mean(abs(categoryAcc))]


plot_results(methodNames,allMeans,rawEst,ratios);
plot_results(methodNames,postStratMeans,postStratEst,ratios);
%}