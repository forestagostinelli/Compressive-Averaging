classdef MLCSAvg < Avg
  % multi-level CSAvg
  % idea: use multiple truth families, and let data determine which family
  % to rely on. i.e. different priors...
    properties
        B  % the basis
        k  % maximum sparsity level
        sigma2 % noise level.
        name % name of this csavg
    end
    methods
        function obj = MLCSAvg(B, k, sigma2, name)
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
            name = 'mlcsavg';
          else
            name = ['mlcsavg-', obj.name];
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

            gamma = ones(k+1,1) / (k+1);
            scale = 1;
            gammay = N ./ sigma2;
            iteration = 10;
            eps_omp = 1e-4;
            prev = [ones(k+2, 1) * inf];
            
            M = zeros(size(B,1), k+1);
            
            % plain version.
%             function e = energy(x)
%               sx = sum(x);
%               prec = sx * gammay ./ (sx + gammay);
%               e = sum(-log(prec));
%               px = x / sx;
%               e = e + sum((y - M * px) .* prec);
%             end
            
%           % scale version
            function e = energy(x)
              s = x(end);
              px = x(1:end-1);
              prec = s * gammay ./ (s + gammay);
              e = sum(-log(prec));
              e = e + sum((y - M * px).^2 .* prec);
            end

            for it = 1:iteration
              % sparse decomposition. 
              M(:, k+1) = mean(y);
              for ki = 1:k
                [alpha, supp] = omp(y, B, sigma2 ./ N, ki, eps_omp);
                M(:, ki) = B * alpha;
              end

              % fmincon on gamma.
              options = optimset('Display', 'None', 'Algorithm', 'active-set');
              A = [-eye(k+2); ones(1,k+1) 0; -ones(1,k+1) 0];
              b = [zeros(k+2, 1); 1; -1];
              result = fmincon(@energy, [gamma; scale], A, b, [], [], [], [], [], options);
              gamma = result(1:end-1);
              scale = result(end);
               if all(prev == result)
                 break;
               else
                 prev = result;
               end
            end
            
            
            sxy = scale + gammay;
            mu_h = gammay ./ sxy .* y + M * scale * gamma ./ sxy;
        end
            
    end
end
