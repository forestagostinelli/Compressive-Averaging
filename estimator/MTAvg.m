classdef MTAvg < Avg
  % Multi-Task Averaging with constant task correlation. 
  properties
      sigma2 % noise level;
      gamma  % regularization paramter;
  end
  methods
    function obj = MTAvg(gamma, sigma2)
      % constructor for MTAvg.
      % input: 
      %   gamma - regularization paramter.
      %   sigma2 - noise-level.
      %   A - a function A(i,j) describing the correlation 
      %       task i and j.
      obj.sigma2 = sigma2;
      obj.gamma = gamma;
    end
    function name = get_name(obj)
      name = 'MTAvg';
    end

    function mu_h = avg(obj, samples, y, N)
      % averaging using multi-task averaging.
      % input:
      %     samples:   a 1-D cell array, each cell is a list of samples. 
      %     sigma2 :  noise variable.
        shape = size(samples);
        samples = samples(:);
        sigma2 = obj.sigma2(:);
        if (~exist('y','var'))
            y = cellfun(@mean, samples);
        end
        if (~exist('N','var'))
            N = cellfun(@length, samples);
        end

        n = length(samples);
        diffMat = repmat(y, 1, n) - repmat(y', n, 1);
        a = (2 * n * (n-1)) / sum(diffMat(:).^2);
        A = ones(n, n) * a;
        L = laplacian(A);
        Sigma = diag(sigma2 ./ N);
        mu_h = (eye(n) + obj.gamma / n * Sigma * L) \ y;
        mu_h = reshape(mu_h, shape);
        
        %{
        hold off;
        plot(y,'g')
        hold on
        plot(mu_h,'b-o')
        keyboard;
        %}

    end
  end
end
