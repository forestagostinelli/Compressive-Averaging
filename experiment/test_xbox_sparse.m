clear
%close all
load('../survey-data-bcs-data-store/election/adjacency_DC_Alone.mat');
load('../survey-data-bcs-data-store/XboxPoll/XboxData.mat');
% Create basis function
timepoints = 1:length(samplesByState);
for i = 1:length(samples)
  samples{i} = double(samples{i})';
end
for t = 1:length(samplesByState);
    for i = 1:length(samplesByState{t})
        samplesByState{t}{i} = double(samplesByState{t}{i})';
    end
end
%TODO take D.C. into account

L = laplacian(matrix);
[U, S] = eig(L);
K = @(t)(U * diag(exp(-t * diag(S))) * U');
mapD = K(10) * eye(length(matrix));
mapK = 5;

%D = wmpdictionary(45, 'LstCpt', {{'haar', 5}});    % choose dictionary;
%D = wmpdictionary(45, 'LstCpt', {'dct'});    % choose dictionary;
timeD = wmpdictionary(45, 'LstCpt', {{'wpsym4', 5}});
timeD = timeD(:, 1:8);
timeK = 3;


ratios = [0.01 0.02 0.05 0.1 0.2];

methods = {'avg','csavg'};
seeds = 1:1;

allMeans = cell([length(seeds),length(ratios),length(methods)]);

adjustByState = 1;

for s=1:length(seeds)
    seed = seeds(s);
    for r = 1:length(ratios)
        ratio = ratios(r);
        statsModState = cell(length(methods),1);
        ratioSamplesByState = cell(length(samplesByState),1);
        for t = 1:length(samplesByState);
            ratioSamplesByState{t} = sample(samplesByState{t}, ratio, 1, seed);
        end
        timeSamples = cell(length(timepoints),1);
        if adjustByState
            for i=1:numel(statsModState)
                statsModState{i} = zeros(length(timepoints),1);
            end
        end
        for t=1:length(ratioSamplesByState);
            stateSamples = ratioSamplesByState{t};
            for prevT=(t-1):-1:max(1,t)
                for i=1:length(stateSamples)
                    stateSamples{i} = [stateSamples{i} ratioSamplesByState{prevT}{i}];
                end
            end
            index = 1:length(stateSamples);
            stateSamples = stateSamples(index);
            runner = Runner(stateSamples);
            timeSamples{t} = cell2mat(ratioSamplesByState{t}');
            if adjustByState
                sigma2 = cellfun(@var, stateSamples); 

                if ismember('avg',methods)
                    runner.add_method(SampleAvg());
                end
                if ismember('csavg',methods)
                    runner.add_method(CSAvg(mapD, mapK, sigma2));
                end
                %runner.add_method(CSAvgBoostrap(mapD, mapK, sigma2));
                %runner.add_method(JamesSteinAvg(sigma2));
                %runner.add_method(MTAvg(0.1, sigma2));

                runner.run_all(1, seed);

                mu_h = runner.mu_h;
                methodSampleNum = runner.methodSampleNum;
                for m = 1:length(methods)
                    means = mu_h(methods{m});
                    sampleNum = methodSampleNum(methods{m});
                    if min(sampleNum{1,1}) == 0
                        error('State has no samples\n')
                    end
                    statsModState{m,1}(t) = sum(means{1,1}.*sampleNum{1,1}/sum(sampleNum{1,1}));
                end
            end
            %runner.plot_score();
        end
        sigma2= cellfun(@var, timeSamples);

        timeRunner = Runner(timeSamples);
        if ismember('avg',methods)
            [~,meanIdx] = ismember('avg',methods);
            timeRunner.add_method(SampleAvg(statsModState{meanIdx,1}));
        end
        if ismember('csavg',methods)
            [~,meanIdx] = ismember('csavg',methods);
            timeRunner.add_method(CSAvg(timeD, timeK, sigma2/4, statsModState{meanIdx,1}));
        end
        %runner.add_method(JamesSteinAvg(sigma2));
        %runner.add_method(MTAvg(1, sigma2));

        timeRunner.datasetType = 'xbox';
        timeRunner.run_all(1, seed);
        mu_h = timeRunner.mu_h;
        for m = 1:length(methods)
            method_mu_h = mu_h(methods{m});
            allMeans{s,r,m} = method_mu_h{1,1};
        end
        %runner.plot_score();
        %saveas(1, 'result/xbox.eps', 'epsc');
    end
end
score = containers.Map();
numMethods = length(timeRunner.avgs);
timeRunner.ratios = ratios;
timeRunner.truth = cellfun(@mean, samples);
for mi=1:numMethods
    method = timeRunner.avgs{mi};
    name = method.get_name();
    [timeRunner.score(name), timeRunner.score_std(name)] = timeRunner.metric(allMeans(:,:,mi), timeRunner.truth);
end
timeRunner.plot_score();
