classdef CSAvg < Avg
    properties
        B  % the basis
        k  % sparsity level
        sigma2 % noise level.
        name % name of this csavg
        computeA % function to compute A, default is MLE.
        mean % if using different mean than samples
    end
    methods
        function obj = CSAvg(B, k, sigma2, mean, name)
          % constructor of Avg
          % input: 
          %         B           :    a set of basis, each column is a basis vector.
          %         k           :    k-sparse constraint
          obj.B = B;
          obj.k = k;
          sigma2(sigma2 == 0) = min(sigma2(sigma2 ~= 0));
          obj.sigma2 = sigma2;
          
          if ~exist('mean','var')
            obj.mean = [];
          else
            obj.mean = mean;
          end
          
          if exist('name','var')
            obj.name = name;
          else
            obj.name = '';
          end
          obj.computeA = @CSAvg.computeAByLineSearch;
        end
        
        function name = get_name(obj)
          if strcmp(obj.name, '') == 1
            name = 'OMP';
          else
            name = obj.name;
          end
        end
        
        function mu_h = avg(obj, samples, y, N)
            % compressive averaging.
            % input:
            %         samples:   a 1-D cell array, each cell is a list of samples. 
            %         sigma2 :    noise variable.
            B = obj.B;
            k = obj.k;
            sigma2 = obj.sigma2;
            
            isBinary = 1;
            for t=1:length(samples)
                if sum(sum(samples{t} == 1 | samples{t} == 2)) < length(samples{t})
                    isBinary = 0;
                    break;
                end
            end
            
            if (~exist('y','var'))
                y = cellfun(@mean, samples);
            end
            if (~exist('N','var'))
                N = cellfun(@length, samples);
            end
            
            n = length(y);

            bestObjective = inf;
            optA = 0;
            optAlpha = [];
            optSupp = [];
            
            iteration = 10;
            eps_omp = 1e-4;
            
            if isBinary
                obj.computeA = @CSAvg.computeAByLineSearch;
            else
                obj.computeA = @CSAvg.computeAByGrad;
            end
            
            if isBinary
                aStartRange = 0.01;
            else
                aStartRange = [0 0.1 1 5];
            end
            
            for a=1:length(aStartRange)
                A = aStartRange(a);
                
                prevA = inf;

                for it = 1:iteration
                  % sparse decomposition. 
                  [alpha, supp] = omp(y, B, A +  sigma2 ./ N, k, eps_omp);
                  M = B * alpha;
                  %M = max(M,1);
                  %M = min(M,2);

                  % gradient descent on A. 
                  A = obj.computeA(A, y, M, sigma2, N, length(supp));
                  A = max(A,0);
                  
                  sigma2marg = A + sigma2 ./ N;
                  diff = (y - M).^2;
                  objective = sum(diff./sigma2marg + log(sigma2marg));
            
                  if objective < bestObjective || (a == 1 && it == 1)
                    optA = A;
                    optAlpha = alpha;
                    optSupp = supp;
                    bestObjective = objective;
                  end
                  if prevA == A
                    break;
                  else
                    prevA = A;
                  end
                end
            end
            A = optA;
            M = B * optAlpha;

            sigma2marg = A + sigma2 ./ N;
            shrinkage = sigma2 ./ N ./ sigma2marg;
            mu_h = M  + max(0, 1 - shrinkage) .* (y - M);
            if isBinary
                mu_h = max(mu_h,1);
                mu_h = min(mu_h,2);
            end
            %{
            subplot(211)
            hold off;
            plot(M,'b-x')
            hold on
            plot(y,'g')
            hold on
            plot(mu_h,'b-o')
            a = 0:0.001:1;
            diff = (y - M).^2;
            
            objectiveFunc = @(A) sum(diff./(A + sigma2 ./ N) + log((A + sigma2 ./ N)));
            out = zeros(length(a),1);
            for i=1:length(a)
                out(i) = objectiveFunc(a(i));
            end
            subplot(212)
            plot(a,out);
            
            A
            keyboard;
            %}
            
        end
    end
    
    methods(Static)
      % estimate A from y: MLE estimator.
      function A = computeAByLineSearch(A, y, M, sigma2, N, k)
        meanY = mean(y);
        
        sigmaRatio = sigma2./N;
        maxA = max(min(0.25-sigmaRatio),0);
        a = 0:0.0001:maxA;

        mu = 0;
        %epsA = 0.0001;
        %variance = 0.01*(maxA^2)*(log(0.5 - abs(1.5-meanY) + epsA) - log(epsA))/(log(0.5 + epsA) - log(epsA));
        %variance = 0.01*((0.5 - abs(1.5-meanY))).^2/0.25;
        %variance = 0.01*maxA*(-abs(1.5 - meanY).^2 + 0.25)/0.25;
        variance = 0.01*maxA;
        %fprintf('%f, %f, %f\n',maxA,meanY,variance);
        
        aPlusSigmaRatio = bsxfun(@plus,a,sigmaRatio);
        objFunc = log(sqrt(aPlusSigmaRatio)) ...
            + bsxfun(@times,(y - M).^2,1./(2*aPlusSigmaRatio));
        objFunc = bsxfun(@minus,objFunc,log(normpdf(a,mu,variance))); % Add prior regularization
        
        objFunc = sum(objFunc,1);
        
        [~,idx] = min(objFunc);
        
        A = a(idx);

        
      end
      function A = computeAByGrad(A, y, M, sigma2, N, k)
          options = optimset('Display', 'None', 'Algorithm', 'active-set');
          A = fmincon(@(x)(sum(log(x + sigma2 ./ N) ...
                                                        + (y - M).^2 ./ (x + sigma2 ./ N) ) ),...
                                     A, -1, 0, [], [], [], [], [], options);
      end
      
      % estimate A from y: empirical moment estimator based on variance.
      function A = computeAByVarIso(A, y, M, sigma2, N, k)
        A = (y - M)' * (y - M) / (length(y) - k) - mean(sigma2 ./ N);
      end
      
      % estimate A from y: empirical moment estimator based on variance.
      function A = computeAByVar(A, y, M, sigma2, N, k)
        options = optimset('Display', 'None', 'Algorithm', 'active-set');
        sig2 = sigma2 ./ N;
        A = fmincon(@(x)((sum((y-M).*(y-M)./ (x + sig2)) - length(y) + k).^2),...
                                   A, -1, 0, [], [], [], [], [], options);
      end
    end
end
