classdef BCSAvg < Avg
  properties
    B  % the basis
    gamma_param % a struct of parameters: a, b, c, d, p, q.
    sigma2 % noise level.
    name % name of this csavg
    maxiter % maximum number of iterations
  end
  
  methods
    function obj = BCSAvg(B, gamma_param, sigma2, name)
      obj.B = B;
      gamma_param_lists = {'a', 'b', 'c', 'd', 'p', 'q'};
      obj.gamma_param = struct();
      default_value = 1;
      for i = 1:length(gamma_param_lists)
        ch = gamma_param_lists{i};
        if isfield(gamma_param, ch)
          setfield(obj.gamma_param, ch, getfield(gamma_param, ch));
        else
          setfield(obj.gamma_param, ch, default_value); 
          fprintf('Warning: using deault value %f for gamma_param.%c', default_value, ch);
        end
      end
      obj.gamma_param = gamma_param;
      if nargin >= 4
        obj.name = name;
      else
        obj.name = '';
      end
      obj.maxiter = 10000;
      obj.sigma2 = sigma2;
    end
    
    function name = get_name(obj)
      if strcmp(obj.name, '') == 1
        name = 'bcsavg';
      else
        name = ['bcsavg-', obj.name];
      end
    end
    
    function mu_h = avg(obj, samples)  
      % find the nonempty sample sets and construct the measurement
      % matrix accordingly
      inx = ~cellfun(@isempty, samples);      
      I = eye(size(samples, 1));
      M = I(inx, :);
      
      dict = obj.B;
      
      Phi = M * dict;
      
      n = length(samples);
      m = cellfun(@length, samples);
      y = cellfun(@mean, samples);
      
      % fix initial dimensions
      % N = width of dictionary (or length of sparse weight vector)
      % K = number of measurements (i.e. those with >= 1 sample)
      N = size(dict, 2);
      K = size(M, 1);
      
      % get some auxilarly information about the samples ahead of
      % time so we can reuse these later
      sc = samples(inx);
      for i = 1:length(sc)
        sc{i} = sc{i}';
      end
      sample_counts = cellfun(@length, sc);
      sccs = cumsum(sample_counts);
      total_samples = sum(sample_counts);
      
      % initialize the vector of all of our samples
      s = cat(1, sc{:});
      
      % initialize the five parameters we are trying to optimize
      alpha = ones(N, 1);
      alpha0 = 1;
      beta = 1/mean(obj.sigma2); % TODO: different sigmas;
            
      % set values for the parameters for the Gamma distributions
      a = obj.gamma_param.a;
      b = obj.gamma_param.b;
      c = obj.gamma_param.c;
      d = obj.gamma_param.d;
      p = obj.gamma_param.p;
      q = obj.gamma_param.q;
      
      % create initial versions (before weight removal) of the
      % matricies A, B and C and the relevant products between them.
      %
      % we make this a function as we need to re-call it every time
      % we prune weights (i.e. reduce N)
      function [A, ATA, BTB, C] = build_matricies()
        rows = 1:total_samples;
        cols = zeros(total_samples, 1);
        for kk=1:K
          cols((sccs(kk) - sample_counts(kk) + 1):sccs(kk)) = kk;
        end
        
        A = sparse(rows, cols, 1, total_samples, K+N);
        ATA = A'*A;

        B = [eye(K), -Phi];
        BTB = B' * B;

        C = sparse(1:N, K+1:K+N, 1, N, K+N);
      end
      
      [A, ATA, BTB, C] = build_matricies();
      
      % set thresholds for weight removal and convergence
      w_eps = 1e-15; %2.22e-16
      lls_eps = 1e-8;
            
      lls = [];
      
      for iter=1:obj.maxiter
        Sigma_inv = beta*ATA + alpha0*BTB + C'*spdiags(alpha,0,N,N)*C;
        v = Sigma_inv \ (beta*A'*s);
        g = v(1:K);
        w = v(K+1:end);
        
        % todo: vectorize
        beta_denom = 0;
        for k=1:K
          beta_denom = beta_denom + sum((g(k) - sc{k}).^2);
        end
        beta = (total_samples+2*p)/ (beta_denom+2*q);
        alpha = (1+2*a)./(w.^2 + 2*b);
        alpha0 = (K+2*c) / (norm(g - Phi*w)^2+2*d);
        
        ll = obj.log_likelihood(sc, g, w, alpha, alpha0, beta, Phi, K, N,a,b,c,d,p,q, beta_denom);
        lls = [lls ll];
        
        if length(lls) >= 2 && abs(lls(iter) - lls(iter-1)) < lls_eps
          break;
        end
        
        % now we prune out any weights that are basically zero
        to_remove = abs(w) < w_eps;
        
        if sum(to_remove) > 0
          alpha = alpha(~to_remove);
          dict = dict(:, ~to_remove);
          Phi = M * dict;
          
          % update the dimensions as we have fewer weights now
          N = size(dict, 2);
          
          % rebuild the matricies
          [A, ATA, BTB, C] = build_matricies();
        end
      end
      
      % replace so we don't have to explicitly take inverse?
      Sigma = inv(Sigma_inv);
      Sigma_w = Sigma(K+1:end, K+1:end);
      Sigma_f = dict * Sigma_w * dict';
      
%       Sigma_w_inv = Sigma_inv(K+1:end, K+1:end);
%       Sigma_f = dict * (Sigma_w_inv \ dict');
      M = dict * w;
      
      sigma2marg = 1./alpha0 + obj.sigma2 ./ m;
      shrinkage = obj.sigma2 ./ m ./ sigma2marg;
      mu_h = M .* shrinkage + (1 - shrinkage) .* y;

    end
  end
  
  methods (Access = private)    
    function y = hard_thresh(~, x, lambda)
      y = x.*(abs(x) >= lambda);
    end
    
    function ll = log_likelihood(~, sc, g, w, alpha, alpha0, beta, Phi, K, N,a,b,c,d,p,q,beta_denom)
      ll = 0;
      
      % ll = ll - 0.5*(sum(g(k) - sc{k}).^2);
      ll = ll - 0.5 * beta_denom;      
      ll = ll + 0.5*K*log(beta) - 0.5*K*log(2*pi);
        
      ll = ll + 0.5*alpha0*K - 0.5*log(2*pi)*K;
      ll = ll - 0.5*norm(g - Phi*w)^2;
      
      ll = ll + 0.5*sum(alpha) - 0.5*log(2*pi)*N;
      ll = ll - 0.5*sum(alpha.*(w.^2));
      
      ll = ll + a*sum(log(alpha)) - b*sum(alpha);
      ll = ll + c*log(alpha0) - d*alpha0;
      ll = ll + p*log(beta) - q*beta;
    end
  end
end

