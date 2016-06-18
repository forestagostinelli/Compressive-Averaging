classdef BestPriorAvg < Avg
    properties
        B  % the basis
        k  % sparsity level
        sigma2 % noise level.
        name % name of this csavg
    end
    methods
        function obj = BestPriorAvg(B, k, sigma2, name)
          % constructor of Avg
          % input: 
          %         B           :    a set of basis, each column is a basis vector.
          obj.B = B;
          obj.sigma2 = sigma2;
          obj.k = k;
          if nargin >= 4
            obj.name = name;
          else
            obj.name = '';
          end
        end
        
        function name = get_name(obj)
          if strcmp(obj.name, '') == 1
            name = 'bestprior';
          else
            name = ['bestprior-', obj.name];
          end
        end
        
        function mu_h = avg(obj, samples)
            % compressive averaging.
            % input:
            %         samples:   a 1-D cell array, each cell is a list of samples. 
            %         sigma2 :    noise variable.
            B = obj.B;
            k = obj.k;
            sigma2 = obj.sigma2;
            
            y = cellfun(@mean, samples);
            N = cellfun(@length, samples);
            n = length(y);
            K = size(B, 2);
            
            A = 1;
            minA = inf;
            bestM = B(:,1);
            eps_omp = 1e-4;
            iteration = 100;
            
            for it = 1:mycombnk(K, k) * 3
              ind = randsample(1:K, k, false);
              A = 1;
              prevA = nan;
              for i = 1:iteration
                [alpha, supp] = omp(y, B(:,ind), A +  sigma2 ./ N, k, eps_omp);
                M = B(:,ind) * alpha;
                options = optimset('Display', 'None', 'Algorithm', 'active-set');
                A = fmincon(@(x)(sum(log(x + sigma2 ./ N) ...
                                                              + (y - M).^2 ./ (x + sigma2 ./ N) ) ),...
                                           A, -1, 0, [], [], [], [], [], options);
                if prevA == A
                  break;
                else
                  prevA = A;
                end
              end
              if A < minA
                minA = A;
                bestM = M;
              end
            end
            
            sigma2marg = minA + sigma2 ./ N;
            shrinkage = sigma2 ./ N ./ sigma2marg;
            mu_h = bestM  + max(0, 1 - shrinkage) .* (y - bestM);
        end
    end
end
