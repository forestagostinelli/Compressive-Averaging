function [val, val_std] = metric_me(mu_hs, truth)
% evaluate the performance of mu_hs with respect to truth under mean absolute error.
% return:
%   val: performance for different ratios.
%   val_std: standard deviation of val.
%   tag: name of this method.
  n_ratio = size(mu_hs, 2);
  val = cell(1, n_ratio);
  val_std = cell(1, n_ratio);
  metric = @(mu_h)(sum(reshape(abs(mu_h - truth), [], 1)) / numel(truth));
  for i = 1:n_ratio
    val{i} = mean(cellfun(metric, mu_hs(:, i)));
    val_std{i} = std(cellfun(metric, mu_hs(:,i)));
  end
end
