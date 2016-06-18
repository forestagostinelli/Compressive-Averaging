function res = sample_eq(samples, ratio, min_sample, seed)
  rng(seed);
  m = length(samples);
  N = cellfun(@length, samples);
  n_sample = max(floor(mean(N) * ratio), min_sample);
  res = cell(m, 1);
  for i = 1:m
    n = N(i);
    if n  < n_sample
      warning('number of samples to collect exceed the total number of samples in category. use truncation.');
      n_sample = n;
    end
    ind = randsample(1:n, n_sample, true);
    res{i} = samples{i}(ind);
  end
end