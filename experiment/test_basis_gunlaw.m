clear;
addpath('sparse');
load('../survey-data-bcs-data-store/GSS/GUNLAW/allsamples_YEAR_GUNLAW.mat');
y = cellfun(@mean, samples);

 D = wmpdictionary(26, 'LstCpt', {'dct'});
% D = wmpdictionary(26, 'LstCpt', {'sin'}); D = [ones(26,1) D];
% D = wmpdictionary(26, 'LstCpt', {{'haar', 5}});
% D = wmpdictionary(26, 'LstCpt', {{'wpsym4', 5}});

code = omp(y', D, ones(26,1)*0.3, 3, 1e-4);
plot(D * code);
hold on;
plot(y, 'r.', 'MarkerSize', 20)
