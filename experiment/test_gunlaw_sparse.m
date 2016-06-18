% time series experiment: GUNLAW data.
clear
%close all
%% Generate. 
load('./data/gunlawDataset.mat');
%load('../survey-data-bcs-data-store/XboxPoll/XboxData.mat');
samples = samples';
for i = 1:length(samples)
  samples{i} = double(samples{i});
end
M = cellfun(@mean, samples); % approximate true means with means of all samples.
sigma2= cellfun(@var, samples); 
N = cellfun(@length, samples);
n = length(samples);

ompType = 0;

%% recover.
runner = Runner(samples,keys);

% use different k for different ratios.
%fullD = wmpdictionary(length(samples), 'LstCpt', {{'haar', 5}});    % choose dictionary;
%fullD = wmpdictionary(length(samples), 'LstCpt', {'poly'});    % choose dictionary;
%fullD = wmpdictionary(length(samples), 'LstCpt', {'dct'});    % choose dictionary;
fullD = wmpdictionary(length(samples), 'LstCpt', {{'wpsym4', 5}});
D = fullD(:, 1:8);


k = 3;

%nn = NeuralNetworkAvg(D, k, sigma2);
%save('./Neural_Network/trainedNNs/gunlaw.mat','nn');
load('./Neural_Network/trainedNNs/gunlaw.mat');
runner.add_method(nn);

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

    fullD = wmpdictionary(length(samples), 'LstCpt', {{'wpsym4', 5}});
    D = fullD(:, 1:8);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (wpsym)'));
elseif ompType == 3
    fullD = wmpdictionary(length(samples), 'LstCpt', {{'wpsym4', 5}});
    D = fullD(:, 1:4);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (L=4)'));

    D = fullD(:, 1:8);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (L=8)'));

    D = fullD(:, 1:16);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (L=16)'));

    D = fullD(:, 1:32);
    runner.add_method(CSAvg(D, k, sigma2, [], 'OMP (L=32)'));
end

%baselines.
runner.add_method(SampleAvg());
runner.add_method(JamesSteinAvg(sigma2));
runner.add_method(MTAvg(1, sigma2));

ratios = [0.01 0.02 0.03 0.04 0.05 0.1 0.2 0.3];
seeds = 1:30;

runner.run_all(ratios, seeds);

figure
runner.plot_score();
%saveas(1, 'results/gunlaw.eps', 'epsc');


