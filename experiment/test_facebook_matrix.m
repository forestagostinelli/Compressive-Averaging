% time series experiment: GUNLAW data.
%% Generate. 
clear
data = load('../survey-data-bcs-data-store/December-2012--Facebook-(omnibus)/allsamples_matrix.mat');
samples = data.data;
M = cellfun(@mean, samples); % approximate true means with means of all samples.
sigma2= cellfun(@var, samples); 
N = cellfun(@length, samples);
n = size(samples);

sigma2 = mean(sigma2(:)) * 0.1 + sigma2 * 0.9; % smoothing.

%% recover. 
runner = Runner(samples);
runner.metric = @metric_sqrt_mse;

runner.add_method(LowRankMatrixAvg(1, sigma2));

%  baselines.
runner.add_method(SampleAvg());
runner.add_method(JamesSteinAvg(sigma2));
runner.add_method(MTAvg(0.01, sigma2));

ratios = [0.01, 0.03, 0.07, 0.1, 0.2, 0.3, 0.4, 0.5];
% ratios = [0.01, 0.02, 0.03];
% ratios = [0.1];
seeds = 1:10;

runner.run_all(ratios, seeds);
runner.plot_score()

saveas(1, 'result/facebook_matrix.eps', 'epsc');


