mu = [1,1,1,1,1,1,1,1,100,100]';
n = length(mu);
m = 10000;
samples = {};
sigma2 = 1;
global M_list;
M_list = [];
for i = 1:n
  samples{i,1} = sqrt(sigma2) * randn(1, m) + mu(i);
end

runner = Runner(samples);
runner.metric = @metric_mse;
runner.metric_description = 'Mean Squared Error';
runner.add_method(SampleAvg());
runner.add_method(JamesSteinAvg(sigma2));

D = [eye(n) ones(n,1)];
runner.add_method(CSAvg(D, 2, sigma2));
% 
% % BCS Avg.
% gamma_param = struct('a', 1, 'b', 1000, 'c', 1, 'd', 1, 'p', 1, 'q', 1000);
% runner.add_method(BCSAvg(D, gamma_param, sigma2));
% 
% % MT-avg.
% runner.add_method(MTAvg(0.1, sigma2));

ratios = [0.001, 0.005];
seeds = 1:100;

runner.run_all(ratios, seeds);
figure
runner.plot_score()
