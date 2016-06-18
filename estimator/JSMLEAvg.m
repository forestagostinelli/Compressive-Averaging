classdef JSMLEAvg < Avg
  properties
      sigma2 % noise level;
  end
  methods
    function obj = JSMLEAvg(sigma2)
      obj.sigma2 = sigma2;
    end
    function name = get_name(obj)
      name = 'js-mle';
    end

    function mu_h = avg(obj, samples)
      % averaging using James-Stein estimators.
      % input:
      %     samples:   a 1-D cell array, each cell is a list of samples. 
      %     sigma2 :  noise variable.
      y = cellfun(@mean, samples);
      N = cellfun(@length, samples);
      n = length(y);
      M = sum(y .* (N ./ obj.sigma2)) / sum((N ./ obj.sigma2));   % global mean.
      sigma_inv = N ./ obj.sigma2;
      
      options = optimset('Display', 'None', 'Algorithm', 'active-set');
      result = fmincon(@(x)(sum(log(obj.sigma2 ./ N + x) + (y-M).^2./(obj.sigma2./N+x))), 1, -1, 0, [], [], [], [], [], options);
      
      % mu_h = M + max(0, (1- (n - 3) / sum(sigma_inv .* (y-M).^2))) * (y - M);
      shrink = 1-result ./ (obj.sigma2 ./ N + result);
      mu_h = (1-shrink) .* y + shrink * M;
    end
  end
end
