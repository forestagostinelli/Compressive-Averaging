% simple synthetic experiment.

%% Generate. 
m = 10;
k = 1;
K = 10;

B = rand(m, K);
alpha = zeros(K, 1);
alpha(randsample(1:K, k, true)) = randn;
M = B * alpha;     % globlal mean. 
sigma2 = 0.3;
N = randi(100, m, 1) + 10;   
samples = cell(m,1);
for i = 1:m
  samples(i) = {(randn(N(i), 1) * sqrt(sigma2)+ M(i))'};
end

%% recover. 

mu_h = containers.Map();
mse = containers.Map();

ratios = [0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35];
seeds = 1:10;

mu_h('avg') = run_ratio(@avg, samples, ratios, seeds);
mu_h('js') = run_ratio(@(sp)(james_stein(sp, sigma2)), samples, ratios, seeds);
mu_h('csavg') = run_ratio(@(sp)(csavg(sp, B, k, sigma2)), samples, ratios, seeds);

allkeys = mu_h.keys();
for i = 1:length(allkeys)
  name = allkeys{i};
  mse(name) = run_mse(mu_h(name), M);
end

plot_mse(ratios, mse);


