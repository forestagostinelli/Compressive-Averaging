classdef CSAvgBoostrap < Avg
    properties
        B  % the basis
        k  % sparsity level
        sigma2 % noise level.
        name % name of this csavg
    end
    methods
        function obj = CSAvgBoostrap(B, k, sigma2, name)
          % constructor of Avg
          % input: 
          %         B           :    a set of basis, each column is a basis vector.
          %         k           :    k-sparse constraint
          obj.B = B;
          obj.k = k;
          obj.sigma2 = sigma2;
          if nargin >= 4
            obj.name = name;
          else
            obj.name = '';
          end
          
        end
        
        function name = get_name(obj)
          if strcmp(obj.name, '') == 1
            name = 'csavg-boost';
          else
            name = ['csavg-boost-', obj.name];
          end
        end
        
        function mu_h = avg(obj, samples, y, N)
            % compressive averaging.
            % input:
            %         samples:   a 1-D cell array, each cell is a list of samples. 
            %         sigma2 :    noise variable.
            B = obj.B;
            k = obj.k;
            n = length(samples);
            sigma2 = obj.sigma2;
            
            if (~exist('y','var'))
                y = cellfun(@mean, samples);
            end
            if (~exist('N','var'))
                N = cellfun(@length, samples);
            end

            boosts = 5;
            boostN = zeros(n, boosts);
            boostB = repmat(B, boosts, 1);
            Y = zeros(n, boosts);
            Sig = zeros(n, boosts);
            a = 1;
            b = 1;
            if ~isempty(find(N==0))
              fprintf('error');
            end
            function u = random_sample(x)
              if length(x) == 1
                u = x;
              else
                u = randsample(x, ceil(length(x)), true);
              end
            end
            for bn = 1:boosts
              sy = cellfun(@random_sample, samples,  'UniformOutput', false);
              boostN(:, bn) = cellfun(@length, sy);
              Y(:, bn) = cellfun(@mean, sy);
              Sig(:, bn) = cellfun(@(x)((sum((x-mean(x)).^2) + 2 * b) / (2 * a + length(x))), sy);
            end
            
            

            A = 1;
            iteration = 10;
            eps_omp = 1e-4;
            prevA = inf;

            for it = 1:iteration
              % sparse decomposition. 
              [alpha, supp] = omp(Y(:), boostB, A +  Sig(:) ./ boostN(:), k, eps_omp);
              M = B * alpha;

              % gradient descent on A. 
              effgrad = inf;
              retry = 0;  
              options = optimset('Display', 'None', 'Algorithm', 'active-set');
              energy = @(x)(sum(log(x + Sig(:) ./ boostN(:)) ...
                                                            + (Y(:) - repmat(M, boosts, 1)).^2 ./ (x + Sig(:) ./ boostN(:)) ) );
              A = fmincon(energy, A, -1, 0, [], [], [], [], [], options);
               if prevA == A
                 break;
               else
                 prevA = A;
               end
            end


            sigma2marg = A + sigma2 ./ N;
            shrinkage = sigma2 ./ N ./ sigma2marg;
            mu_h = M .* shrinkage + (1 - shrinkage) .* y;

        end
            
    end
end
