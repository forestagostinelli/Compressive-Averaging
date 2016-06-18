function [trueMeans,samplesAtPoint,trueGlobalFuncs,targets,sigma2,As] = SampleFromBasis(B,k,sampleNum,rangeNumSamplesAtPoint,isBinary,knownSigma2)
    if ~exist('isBinary','var')
        isBinary = 1;
    end

    dim = size(B,1);
    supportSize = size(B,2);
    
    trueMeans = zeros(dim,sampleNum);
    trueGlobalFuncs = zeros(dim,sampleNum);
    sigma2 = zeros(dim,sampleNum);
    
    samplesAtPoint = cell(dim,sampleNum);
    As = zeros(sampleNum,1);
    targets = zeros(dim,sampleNum);
    covMat = zeros(dim,dim);

    if isBinary
        fMinVal = 0;
        fMaxVal = 1;
    else
        fMinVal = -3;
        fMaxVal = 3;
    end
    
    for s=1:sampleNum
        %% Generate true mean
        supportPos = randsample(2:supportSize,k-1);
        supportPos = [1 supportPos];
        
        coeffs = zeros(supportSize,1);
        currGlobalFunc = zeros(dim,1);
        for p=1:k
            pos = supportPos(p);
            
            for d=1:dim
                dMinVal = (fMinVal-currGlobalFunc(d))/B(d,pos);
                dMaxVal = (fMaxVal-currGlobalFunc(d))/B(d,pos);
                if B(d,pos) < 0
                    temp = dMinVal;
                    dMinVal = dMaxVal;
                    dMaxVal = temp;
                end
                assert(dMaxVal >= dMinVal);

                if d == 1
                    maxVal = dMaxVal;
                    minVal = dMinVal;
                end
                if dMinVal > minVal
                    minVal = dMinVal;
                end
                if dMaxVal < maxVal
                    maxVal = dMaxVal;
                end
            end
            
            assert(maxVal >= minVal);
            coeffs(pos) = unifrnd(minVal,maxVal);
            currGlobalFunc = currGlobalFunc + B(:,pos)*coeffs(pos);
        end
        
        globalFunc = B*coeffs;

        if isBinary
            A = abs(normrnd(0,0.01));

            if A > min(globalFunc - globalFunc.^2)
                minG = min(globalFunc - globalFunc.^2);
                A = minG - minG*0.1;
            end

            globalFunc = max(globalFunc,0.0000001);
            globalFunc = min(globalFunc,0.9999999);
            a = ((1-globalFunc)./(A) - 1./globalFunc).*(globalFunc.^2);
            b = a.*(1./globalFunc - 1);
            trueMean = betarnd(a,b);
            %trueMean = normrnd(globalFunc,A);

            if max(isnan(trueMean)) == 1
                keyboard;
            end
            assert(max(isnan(trueMean)) == 0);
        
            trueMean = min(trueMean,1);
            trueMean = max(trueMean,0);

            assert(min(trueMean) >= 0 && max(trueMean) <= 1);
            assert(min(globalFunc) >= 0 && max(globalFunc) <= 1);
        else
            A = std(globalFunc)*rand(1);
            trueMean = normrnd(globalFunc,sqrt(A));
        end

        As(s) = A;
        
        %{
        hold off;
        plot(globalFunc,'-x'); hold on;
        plot(trueMean,'-or');
        keyboard;
        %}
        

        trueMeans(:,s) = trueMean;
        %targets(dim+1,s) = As(s);
        
        %% Generate Random Samples
        numSamplesRegion = randi(rangeNumSamplesAtPoint);
        numSamples = numSamplesRegion + randi(ceil([-numSamplesRegion numSamplesRegion]/10),dim,1);
        numSamples = max(numSamples,1);

        if isBinary
            sigma2(:,s) = trueMeans(:,s).*(1-trueMeans(:,s));
            for d=1:dim
                sampleAtPoint = rand(numSamples(d),1) < trueMeans(d,s);
                samplesAtPoint{d,s} = sampleAtPoint;
            end
        else
            sigma2(:,s) = abs(normrnd(0,5,dim,1));
            sampleMean = zeros(dim,1);
            for d=1:dim
                sampleAtPoint = normrnd(trueMeans(d,s),sqrt(sigma2(d,s)),numSamples(d),1);
                samplesAtPoint{d,s} = sampleAtPoint;
                sampleMean(d) = mean(sampleAtPoint);
            end
            globalFunc = globalFunc/8;
        end
        trueGlobalFuncs(:,s) = globalFunc;
        targets(1:dim,s) = trueGlobalFuncs(:,s);
    end
end