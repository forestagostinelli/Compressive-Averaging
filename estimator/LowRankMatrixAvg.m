classdef LowRankMatrixAvg < Avg
  properties
      sigma2 % noise level;
      k              % maximum rank.
  end
  methods
    function obj = LowRankMatrixAvg(k, sigma2)
      obj.sigma2 = sigma2;
      obj.k = k;
    end
    function name = get_name(obj)
      name = 'lowrank-mat';
    end

    function mu_h = avg(obj, samples)
      % averaging using Low Rank Matrix regularizer.
      % input:
      %     samples:   a 2-D cell array, each cell is a list of samples. 
      %     sigma2 :  noise variable.
      assert(ismatrix(samples));
      m = size(samples, 1);
      n = size(samples, 2);
      k = obj.k;
      N = cellfun(@length, samples);
      sigma2 = obj.sigma2;
      prec = N./sigma2;
      noise = sigma2./N;
      
      y = cellfun(@mean, samples); % sample averages.
      U = randn(m, k);
      V = randn(k, n); 
      M = U * V;
      A = 1;                                                 % initialize A.
      
      iteration = 100;
      tol = 1e-4;
      prevA = inf;
      prevU = zeros(m, k);
      prevV = zeros(k, n);
      for it = 1:iteration
        % low rank factorization.
        V = obj.computeV(U, y, 1./(A + noise));
        U = obj.computeV(V', y', 1./(A + noise)')';
        M = U * V;
        % gradient descent on A. 
        A = obj.computeA(A, y, M, noise);
        if abs(prevA-A) < tol && sum(abs(prevU(:)-U(:))) < sum(abs(U(:))) * tol ...
            && sum(abs(prevV(:)-V(:))) < sum(abs(V(:))) * tol
          break;
        else
          prevA = A;
          prevV = V;
          prevU = U;
        end
      end
      if it == iteration
        fprintf('warning. may not converge: iteration %d, residual A %f, residual U %f, residual V %f\n', ...
                it, abs(prevA-A)/abs(A), sum(abs(prevU(:)-U(:)))/sum(abs(U(:))), sum(abs(prevV(:)-V(:)))/sum(abs(V(:))));
      end
      sigma2marg = A + noise;
      shrinkage = noise ./ sigma2marg;
      mu_h = M  + max(0, 1 - shrinkage) .* (y - M);
    end
    
    function V = computeV(obj, U, Y, precision)
      % find U such that ||U * V - Y||_\Sigma is minimal.
      % use linear regression for every column of V.
      V = zeros(size(U, 2), size(Y, 2));
      for j = 1:size(Y, 2)
        V(:, j) = (U' * diag(precision(:, j)) * U) \ (U' * (precision(:, j) .* Y(:, j)));
      end
    end
    
    function A = computeA(obj, A, y, M, noise)
      options = optimset('Display', 'None', 'Algorithm', 'active-set');
      A = fmincon(@(x)(sum(reshape(log(x + noise) + (y - M).^2 ./ (x + noise), [], 1))),...
                                 A, -1, 0, [], [], [], [], [], options);
    end
  end
end
