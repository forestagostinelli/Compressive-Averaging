clear
%close all
%{
totalDataFile = '../survey-data-bcs-data-store/XboxCells/ratio_1.000_seed_1_demo_age_education_ideology_party_race_sex.mat';
samples = load(totalDataFile,'curr_samples');
samples = samples.curr_samples;
%}
demoNames = {'race','age','party','education','ideology','sex'};
demoNamesString = strjoin(sort(demoNames),'_');

samples = load('../survey-data-bcs-data-store/XboxPoll/XboxData.mat','samples');
samples = samples.samples;
for i = 1:length(samples)
  samples{i} = double(samples{i})';
end

trueMeans = cellfun(@mean, samples); % approximate true means with means of all samples.
sigma2= cellfun(@var, samples); 

ompType = 3;

%% recover. 

% use different k for different ratios.
%D = wmpdictionary(length(samples), 'LstCpt', {'poly'});    % choose dictionary;
fullD = wmpdictionary(length(samples), 'LstCpt', {{'wpsym4', 6}});

D = fullD(:, 1:8);
k = 3;

ratios = [0.01 0.02 0.03 0.04 0.05 0.1 0.2 0.3];
seeds = 1:30;

runner = Runner(samples);
%nn = NeuralNetworkAvg(D, k, sigma2);
%save('../createdData/trainedNNs/xbox.mat','nn');
%load('../createdData/trainedNNs/xbox.mat')
%runner.add_method(nn);


if ompType == 0
	runner.add_method(CSAvg(D, k, sigma2));
elseif ompType == 1
    for k=1:2:7
        runner.add_method(CSAvg(D, k, sigma2, [], sprintf('OMP (k=%i)',k)));
    end
elseif ompType == 2
    fullD = wmpdictionary(length(samples), 'LstCpt', {{'haar', 5}});    % choose dictionary;
    D = fullD(:, 1:8);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (haar)'));

    fullD = wmpdictionary(length(samples), 'LstCpt', {'poly'});    % choose dictionary;
    D = fullD(:, 1:8);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (poly)'));

    fullD = wmpdictionary(length(samples), 'LstCpt', {'dct'});    % choose dictionary;
    D = fullD(:, 1:8);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (dct)'));

    fullD = wmpdictionary(length(samples), 'LstCpt', {{'wpsym4', 6}});
    D = fullD(:, 1:8);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (wpsym)'));
elseif ompType == 3
    fullD = wmpdictionary(length(samples), 'LstCpt', {{'wpsym4', 6}});
    D = fullD(:, 1:4);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (L=4)'));

    D = fullD(:, 1:8);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (L=8)'));

    D = fullD(:, 1:16);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (L=16)'));

    D = fullD(:, 1:32);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (L=32)'));
end
%  baselines.
runner.add_method(SampleAvg());
runner.add_method(JamesSteinAvg(sigma2));
runner.add_method(MTAvg(1, sigma2));

runner.run_all(ratios, seeds);
figure
runner.plot_score();

%saveas(1, 'results/xbox_raw.eps', 'epsc');
 