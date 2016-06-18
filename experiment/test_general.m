clear
close all
%% Generate. 
load('./data/gunlawDataset.mat');
samples = samples';
for i = 1:length(samples)
  samples{i} = double(samples{i});
end

M = cellfun(@mean, samples); % approximate true means with means of all samples.
sigma2= cellfun(@var, samples); 

%% recover.
runner = Runner(samples);

fullD = wmpdictionary(length(samples), 'LstCpt', {{'wpsym4', 5}});
D = fullD(:, 1:8);

k = 3;

type = 'OMP';

if strcmpi(type,'OMP')
    runner.add_method(CSAvg(D, k, sigma2));
elseif strcmpi(type,'DNN')
    nn = NeuralNetworkAvg(D, k, sigma2);
    runner.add_method(nn);
end

runner.run_all(1, 1);

names = runner.mu_h.keys;
result = runner.mu_h(names{1});
result = result{1};

plot(result);

