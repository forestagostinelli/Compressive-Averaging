function res = sample(samples, ratio, min_sample, seed)
  rng(seed);
  
  m = numel(samples);
  N = cellfun(@length, samples);
  res = cell(size(samples));
  count = 0;
  for i = 1:m
    if N(i) < min_sample
      ind = 1:N(i);
    else
      ind = randsample(1:N(i), min_sample, true);
    end
    this_sample = cell2mat(samples(i));
    res(i) = {this_sample(ind)};
    samples(i) = {this_sample(setdiff(1:N(i), ind))};
    N(i) = N(i) - length(ind);
  end
  
  allN = sum(N(:));
  ind = randsample(1:allN, allN, true);
  id = cell(size(samples));
  for i = 1:m
    id(i) = {ind(count+1:count+N(i))};
    count = count + N(i);
  end
 
  thres = ceil(count * ratio);
  for i = 1:m
    this_sample = cell2mat(samples(i));
    this_id = id{i};
    res{i} = [res{i}, this_sample(this_id <= thres)];
  end
end