clear;
%% Generate.
addpath('sparse');
load('./data/feworkDataset.mat');
years = [];
samples = cell(0);
count = 1;
for i = 1:length(FEWORK)
  if isempty(FEWORK{i})
    continue;
  end
  samples{count} = FEWORK{i};
  years(count) = index(i);
  count = count+1;
end
samples = samples';
M = cellfun(@mean, samples); % approximate true means with means of all samples.
sigma2= cellfun(@var, samples); 
N = cellfun(@length, samples);
n = length(samples);

ompType = 0;

%% recover. 
runner = Runner(samples);
% runner.sampler = @sample_eq;


%D = wmpdictionary(n, 'LstCpt', {{'haar', 5}});    % choose dictionary;
%D = wmpdictionary(n, 'LstCpt', {'dct'});    % choose dictionary;
%D = wmpdictionary(length(samples), 'LstCpt', {'poly'});    % choose dictionary;
D = wmpdictionary(n, 'LstCpt', {{'wpsym4', 5}});
D = D(:, 1:8);
%D = [ones(n,1) rand(n, K)];
k = 3;

%nn = NeuralNetworkAvg(D,k,sigma2);
%save('./Neural_Network/trainedNNs/fework.mat','nn');
load('./Neural_Network/trainedNNs/fework.mat');
runner.add_method(nn);
% CS Avg.
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


% BestPriorAvg;
%bestavg = BestPriorAvg(D, k, sigma2);
%runner.add_method(bestavg);

% BCS Avg.
% gamma_param = struct('a', 1, 'b', 1000, 'c', 0.01, 'd', 0.01, 'p', 0.01, 'q', 0.01);
% runner.add_method(BCSAvg(D, gamma_param, sigma2));

% MT-avg.
runner.add_method(SampleAvg());
runner.add_method(JamesSteinAvg(sigma2));
runner.add_method(MTAvg(1, sigma2));

ratios = [0.01, 0.02, 0.03, 0.04, 0.05, 0.1, 0.2, 0.3];
% ratios = [0.01, 0.02, 0.03];
% ratios = [0.1];
seeds = 1:30;

runner.run_all(ratios, seeds);
figure
runner.plot_score()

%saveas(1, 'results/fework.eps', 'epsc');
