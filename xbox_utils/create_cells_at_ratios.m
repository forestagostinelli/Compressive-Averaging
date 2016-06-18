clear
load('../survey-data-bcs-data-store/XboxPoll/XboxData.mat');
load('../survey-data-bcs-data-store/XboxPollDemo/pop_data.mat');
for i = 1:length(samples)
  samples{i} = double(samples{i})';
end

demoNames = {'age','sex','race','education','party','ideology','state'};
demoNamesString = strjoin(sort(demoNames),'_');
weightName = 'weight';
aggregatePrev = 0;

unNormalizedCellWeights = [];
cellCategories = [];

ratios = [0.01 0.03 0.05 0.1 0.2 0.3];
seeds = 6:10;

for r=1:length(ratios)
    ratio = ratios(r)
    if ratio == 1
        seeds = 1;
    end
    for s=1:length(seeds)
        seed = seeds(s)
        
        %% Get samples
        sampleIdxs = cell(length(samples),1);
        curr_samples = cell(length(samples),1);
        curr_samples_demo = cell(length(samples),1);
        samples_at_time = cell(length(samples),1);
        demo_at_time = cell(length(samples),1);
        for t=1:length(samples)
            sampleNum = length(samples{t});
            sampleIdxs{t} = randsample(sampleNum,floor(sampleNum*ratio));
            curr_samples{t} = samples{t}(sampleIdxs{t});
            samples_at_time{t} = curr_samples{t};
            curr_samples_demo{t} = samplesDemo{t}(sampleIdxs{t},:);
            demo_at_time{t} = curr_samples_demo{t};
            for prevT=(t-1):-1:max(1,t-aggregatePrev)
                curr_samples{t} = [curr_samples{t} samples_at_time{prevT}];
                curr_samples_demo{t} = [curr_samples_demo{t}; demo_at_time{prevT}];
            end
        end
        
        %% Put samples into cells
        curr_cells = cell(length(curr_samples),1);
        for t=1:length(curr_samples)
            curr_cell = Cells(pop_data,demoNames,weightName,unNormalizedCellWeights,cellCategories);
            curr_cell.makeValues(curr_samples{t},curr_samples_demo{t});
            curr_cells{t} = curr_cell;
            unNormalizedCellWeights = curr_cell.unNormalizedCellWeights;
            cellCategories = curr_cell.cellCategories;
        end

        %% Save cells
        cellFileName = sprintf('../createdData/XboxCells/ratio_%0.3f_seed_%i_aggPrev_%i_demo_%s.mat',ratio,seed,aggregatePrev,demoNamesString);
        save(cellFileName,'curr_cells','curr_samples','curr_samples_demo','samples_at_time','demo_at_time');
    end
end

