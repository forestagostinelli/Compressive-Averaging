clear

demoNames = {'age','sex','race','education','party','ideology','state'};
demoNamesString = strjoin(sort(demoNames),'_');
weightName = 'weight';
aggregatePrev = 0;
modelAggregatePrev = 0;

unNormalizedCellWeights = [];
cellCategories = [];

ratios = [0.2 0.3];
seeds = 7:10;

predModel = @(b,x) 1./(1+exp(-(b(:,1) + b(:,2).*x)));

for r=1:length(ratios)
    ratio = ratios(r)
    if ratio == 1
        seeds = 1;
    end
    if ratio == 0.3
        seeds = 6:10;
    end
    for s=1:length(seeds)
        seed = seeds(s)
        %% Load data
        currDataFileName = sprintf('../createdData/XboxCells/ratio_%0.3f_seed_%i_aggPrev_%i_demo_%s.mat',ratio,seed,aggregatePrev,demoNamesString);
        curr_cells = load(currDataFileName,'curr_cells');
        curr_cells = curr_cells.curr_cells;

        curr_samples = load(currDataFileName,'curr_samples');
        curr_samples = curr_samples.curr_samples;

        numCells = curr_cells{1}.numCells;
        
        timeParams = cell(length(curr_cells),1);

        %% Get all unique categories
        uniqueCategoriesPerDemo = cell(length(demoNames),1);
        for d=1:length(demoNames)
            for c=1:numCells
                categoryName = curr_cells{1}.cellCategories{d,c};
                if isempty(uniqueCategoriesPerDemo{d})
                    uniqueCategoriesPerDemo{d} = categoryName;
                else
                    demoCategories = uniqueCategoriesPerDemo(d);
                    if (iscell(demoCategories{:}))
                        demoCategories = demoCategories{:};
                    end
                    uniqueCategoriesPerDemo(d) = {unique([demoCategories categoryName])};
                end
            end
        end
        numUniqueCategories = sum(cellfun(@length,uniqueCategoriesPerDemo));
        
        statePos = find(ismember(curr_cells{1}.header,'state'));
        %% Get the data
        for t=1:length(curr_cells)
            %t
            %% Initialize parameters
            params = cell(numCells,1);
            cellsVoteObama = cell(numCells,1);
            cellsTotal = cell(numCells,1);

            initParams = zeros(numUniqueCategories + 2,1);
            cellInterceptPos = zeros(length(demoNames) + 1,numCells);
            cellSlopePos = zeros(1,numCells);
            
            keepExamples = false(numCells,1);
            
            obamaFrac = zeros(1,numCells);

            for c=1:numCells
                totalSamples = 0;
                voteObama = 0;
                
                obamaFrac(c) = obama2008(curr_cells{1}.cellCategories{statePos,c});

                for currT=(t):-1:max(1,t-modelAggregatePrev)
                    isPopulated = curr_cells{currT}.populatedCells(c);
                    if isPopulated
                        keepExamples(c) = keepExamples(c) | (curr_cells{currT}.numInCell(c) > 0);
                        totalSamples = totalSamples + curr_cells{currT}.numInCell(c);
                        voteObama = voteObama + length(find(curr_cells{currT}.cellSamples{c} == 2));
                    end
                end
                
                if keepExamples(c)
                    cellsVoteObama{c} = voteObama;
                    cellsTotal{c} = totalSamples;
                else
                    cellsVoteObama{c} = [];
                    cellsTotal{c} = [];
                end
                
                %% Shared based on category params
                groupStart = 0;
                for d=1:length(demoNames)
                    demoCategory = curr_cells{t}.cellCategories{d,c};
                    categoryPos = find(ismember(uniqueCategoriesPerDemo{d},demoCategory));
                    assert(length(categoryPos) == 1,'Each cell should have exactly one category match for each demographic.');
                    cellInterceptPos(d,c) = groupStart + categoryPos;
                    groupStart = groupStart + length(uniqueCategoriesPerDemo{d});
                end
                
                %% Shared by all
                cellInterceptPos(d+1,c) = groupStart + 1;
                cellSlopePos(1,c) = groupStart + 2;
            end
            keepExamples = logical(keepExamples);

            %% Get model parameters
            allVoteObama = [cellsVoteObama{:}]';
            allTotals = [cellsTotal{:}]';
            post = @(b) cellMeanLogPdfNoMeans(b,predModel,obamaFrac,cellSlopePos,cellInterceptPos,allVoteObama,allTotals,keepExamples);
            trace = slicesample(initParams,500,'logpdf',post,'burnin',500);
            meanTrace = mean(trace);

            for c=1:numCells
                params{c} = [sum(meanTrace(cellInterceptPos(:,c))) sum(meanTrace(cellSlopePos(:,c)))];
            end
            
            allParams = cell2mat(params);
            timeParams{t} = params;
        end
        
        %% Save parameters
        paramFileName = sprintf('xbox_utils/meanPredictionModels/no_means_ratio_%0.3f_seed_%i_aggPrev_%i_modelAggPrev%i_demo_%s.mat',ratio,seed,aggregatePrev,modelAggregatePrev,demoNamesString);
        save(paramFileName,'timeParams','predModel');
    end
end