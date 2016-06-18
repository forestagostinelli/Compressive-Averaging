clear
load('../survey-data-bcs-data-store/XboxPoll/XboxData.mat');
load('../survey-data-bcs-data-store/XboxPollDemo/pop_data.mat')
for i = 1:length(samples)
  samples{i} = double(samples{i})';
end

demoNames = {'age','sex','race','education'};
demoNamesString = strjoin(sort(demoNames),'_');
weightName = 'weight';
aggregatePrev = 0;

unNormalizedCellWeights = [];
cellCategories = [];

ratios = [1];
seeds = 1;

predModel = @(b,x) 1./(1+exp(-(b*[ones(1,length(x)); x])));

for r=1:length(ratios)
    ratio = ratios(r)
    if ratio == 1
        seeds = 1;
    end
    for s=1:length(seeds)
        seed = seeds(s)
        %% Load data
        currDataFileName = sprintf('../survey-data-bcs-data-store/XboxCells/ratio_%0.3f_seed_%i_aggPrev_%i_demo_%s.mat',ratio,seed,aggregatePrev,demoNamesString);
        curr_cells = load(currDataFileName,'curr_cells');
        curr_cells = curr_cells.curr_cells;
        
        curr_samples = load(currDataFileName,'curr_samples');
        curr_samples = curr_samples.curr_samples;
        curr_means = cellfun(@mean,curr_samples);

        numCells = curr_cells{1}.numCells;
        
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
        
        %% Initialize parameters
        params = cell(numCells,1);
        cellsVoteObama = cell(numCells,1);
        cellsTotal = cell(numCells,1);
        
        initParams = zeros(2*numUniqueCategories + 2,1);
        numParamsPerCell = 2*length(demoNames) + 2; %Cell specific, category shared, all shared
        cellSlopePos = zeros(numParamsPerCell/2,numCells);
        cellInterceptPos = zeros(numParamsPerCell/2,numCells);

        keepExamples = zeros(numCells,length(curr_means));

        for c=1:numCells
            %% Get the data
            totalSamples = [];
            voteObama = [];

            for t=1:length(curr_cells)
                isPopulated = curr_cells{t}.populatedCells(c);
                if ~isPopulated
                    continue;
                end
                keepExamples(c,t) = curr_cells{t}.numInCell(c) > 0;
                totalSamples = [totalSamples curr_cells{t}.numInCell(c)];
                voteObama = [voteObama length(find(curr_cells{t}.cellSamples{c} == 2))];
            end
            cellsVoteObama{c} = voteObama;
            cellsTotal{c} = totalSamples;

            %% Cell specific params
            %cellSlopePos(1,c) = c;
            %cellInterceptPos(1,c) = numCells + c;

            %% Shared based on category params
            groupStart = 0;
            for d=1:length(demoNames)
                demoCategory = curr_cells{t}.cellCategories{d,c};
                categoryPos = find(ismember(uniqueCategoriesPerDemo{d},demoCategory));
                assert(length(categoryPos) == 1,'Each cell should have exactly one category match for each demographic.');
                cellSlopePos(d,c) = groupStart + categoryPos;
                cellInterceptPos(d,c) = groupStart + length(uniqueCategoriesPerDemo{d}) + categoryPos;
                groupStart = groupStart + 2*length(uniqueCategoriesPerDemo{d});
            end

            %% Shared by all cells params
            cellSlopePos(d+1,c) = groupStart + 1;
            cellInterceptPos(d+1,c) = groupStart + 2;                
        end
        keepExamples = logical(keepExamples);
        timeMeans = curr_means' - 1;

        %% Get model parameters
        allVoteObama = [cellsVoteObama{:}]';
        allTotals = [cellsTotal{:}]';
        post = @(b) cellMeanLogPdf(b,predModel,timeMeans,cellSlopePos,cellInterceptPos,allVoteObama,allTotals,keepExamples);
        trace = slicesample(initParams,500,'logpdf',post,'burnin',500);
        meanTrace = mean(trace);

        for c=1:numCells
            params{c} = [sum(meanTrace(cellInterceptPos(:,c))) sum(meanTrace(cellSlopePos(:,c)))];
        end

        %% Save parameters
        paramFileName = sprintf('xbox_utils/meanPredictionModels/shared_no_inidividual_ratio_%0.3f_seed_%i_aggPrev_%i_demo_%s.mat',ratio,seed,aggregatePrev,demoNamesString);
        save(paramFileName,'params','predModel');
    end
end