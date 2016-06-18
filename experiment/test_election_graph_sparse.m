%% Generate. 
clear;
load('../survey-data-bcs-data-store/election/2012.mat');

for i=1:length(samples)
%    samples{i}(samples{i} == 1) = 2;
%    samples{i}(samples{i} == 0) = 1;
end

samples = samples';
for i = 1:length(STATE)
    STATE{i} = STATE{i}';
end
load('../survey-data-bcs-data-store/election/adjacency_DC.mat');

%index = [1:8 10:length(STATE)];
index = 1:length(STATE);
STATE = STATE(index);
samples = samples(index);

M = cellfun(@mean, samples); % approximate true means with means of all samples.
sigma2= cellfun(@var, samples); 
N = cellfun(@length, samples);
n = length(samples);

L = laplacian(matrix);
[U, S] = eig(L);
K = @(t)(U * diag(exp(-t * diag(S))) * U');
D = K(10) * eye(n);


%% recover.
runner = Runner(samples);
%runner.metric = @metric_mse;
%runner.metric_description = 'Mean Squared Error';

%nn = NeuralNetworkAvg(D,5,sigma2);
%runner.add_method(nn);

% runner.add_method(MLCSAvg(D, 20, sigma2));
runner.add_method(CSAvg(D, 15, sigma2));
runner.add_method(CSAvgBoostrap(D, 5, sigma2));

% BCS Avg.
% gamma_param = struct('a', 1, 'b', 1000, 'c', 1, 'd', 1, 'p', 1, 'q', 1000);
% runner.add_method(BCSAvg(D, gamma_param, sigma2));

% baselines.
runner.add_method(SampleAvg());
runner.add_method(JamesSteinAvg(sigma2));
% runner.add_method(JSMLEAvg(sigma2));
%runner.add_method(MTAvg(0.1, sigma2));

ratios = [0.001 0.005 0.01, 0.03, 0.05, 0.1 0.2 0.3];
% ratios = [0.01, 0.02, 0.03];
% ratios = [0.1];
seeds = 1:30;

runner.run_all(ratios, seeds);

figure
runner.plot_score();

mkdir('result');
saveas(1, 'result/president2012.eps', 'epsc');

% % ratios = [0.1];
% seeds = 1:10;
% 
% ni = length(seeds);
% nj = length(ratios);
% 
% mu_h('avg') = run_ratio(@avg, samples, ratios, seeds);
% mu_h('js') = run_ratio(@(sp)(james_stein(sp, sigma2)), samples, ratios, seeds);
% 
% %%
% % use different k for different ratios.
% % D = wmpdictionary(n, 'LstCpt', {{'haar', 5}});    % choose dictionary;
% %D = wmpdictionary(n, 'LstCpt', {'dct'});    % choose dictionary;
% % D = wmpdictionary(n, 'LstCpt', {{'wpsym4', 5}});
% %D = D(:, 1:8);
% 
% %D = [randn(n, 30) ones(n,1)];
% 
% % ks = [3,3, 3, 2, 3, 3, 4, 4];
% ks = ones(1, length(ratios)) * 3;
% cs = cell(ni, nj);
% for j = 1:nj
%    cs(:, j) = run_ratio(@(sp)(csavg(sp, D, ks(j), sigma2)), samples, [ratios(j)], seeds);
% end
% mu_h('csavg') = cs;
% 
% %%
% allkeys = mu_h.keys();
% for i = 1:length(allkeys)
%   name = allkeys{i};
%   mse(name) = run_mse(mu_h(name), M);
% end
% 
% plot_mse(ratios, mse);




