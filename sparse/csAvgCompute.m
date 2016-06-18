function [mu_h,alpha,supp,A] = csAvgCompute(samples,sigma2,y,N,B,k,bootstrap,bootstrapAlpha,bootstrapSupp,Atotal)
    if (~exist('y','var'))
        y = cellfun(@mean, samples);
    end
    if (~exist('N','var'))
        N = cellfun(@length, samples);
    end
    sigma2(sigma2 == 0) = min(sigma2(sigma2 ~= 0));

    eps_omp = 1e-4;
    if ~bootstrap
        A = 0.001;
        computeA = @CSAvg.computeAByLineSearch;
        iteration = 10;
        prevA = inf;

        for it = 1:iteration
            % sparse decomposition. 
            if bootstrap
                [alpha, supp] = bootstrapOmp(y, B, A +  sigma2 ./ N, k, eps_omp,bootstrapAlpha,bootstrapSupp);
                M = B * alpha;
            else
                [alpha, supp] = omp(y, B, A +  sigma2 ./ N, k, eps_omp);
                M = B * alpha;
            end

            % gradient descent on A. 
            A = computeA(A, y, M, sigma2, N, length(supp));
            if A < 0 
                %fprintf('ERROR: A is %f which is less than zero.\n',A)
                %A = 0;
                %break;
            end
            if prevA == A
                break;
            else
                prevA = A;
            end
        end
    else
        A = Atotal;
        [alpha, supp] = bootstrapOmp(y, B, A +  sigma2 ./ N, k, eps_omp,bootstrapAlpha,bootstrapSupp);
        M = B * alpha;
    end

    sigma2marg = A + sigma2 ./ N;
    shrinkage = sigma2 ./ N ./ sigma2marg;
    mu_h = M  + max(0, 1 - shrinkage) .* (y - M);
    
    %{
    if bootstrap
        plot(M,'r-x')
        hold on
        plot(y,'g')
        hold on
        plot(mu_h,'r-o')
        A
        keyboard;
    else
        plot(y,'c')
        A
        hold on
    end
    %}
end

