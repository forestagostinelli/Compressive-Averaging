classdef JamesSteinAvg < Avg
  properties
      sigma2 % noise level;
  end
  methods
    function obj = JamesSteinAvg(sigma2)
      obj.sigma2 = sigma2;
    end
    function name = get_name(obj)
      name = 'JS';
    end

    function mu_h = avg(obj, samples, y, N)
      % averaging using James-Stein estimators.
      % input:
      %     samples:   a 1-D cell array, each cell is a list of samples. 
      %     sigma2 :  noise variable.
        if (~exist('y','var'))
            y = cellfun(@mean, samples);
        end
        if (~exist('N','var'))
            N = cellfun(@length, samples);
        end

        n = numel(y);
        weighted = y .* N;
        M = sum(weighted(:)) / sum(N(:));   % global mean.
        mu_h = obj.avgWithM(samples, M, y, N);
    end
  
    function mu_h = avgWithM(obj, samples, M, y, N)
        if (~exist('y','var'))
            y = cellfun(@mean, samples);
        end
        if (~exist('N','var'))
            N = cellfun(@length, samples);
        end

        n = numel(y);
        sigma_inv = N ./ obj.sigma2;
        deviation = sigma_inv .* (y-M).^2;
        mu_h = M + max(0, 1- (n - 3) / sum(deviation(:))) * (y - M);
    end
  end
end
