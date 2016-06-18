trueMeans = [0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.59 0.61];
T = length(trueMeans);
x = 1:T;

h = plot(x,trueMeans,'r'); hold on;
set(h, 'LineWidth', 1);

samples = cell()

ylim([0 1]);
xlim([1 T]);