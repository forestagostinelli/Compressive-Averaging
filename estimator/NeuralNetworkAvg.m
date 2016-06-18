classdef NeuralNetworkAvg < Avg
  properties
      B % Basis
      k  % sparsity level
      neural_network % the neural network
      shrinkage_nn %% nn to predict shrinkage
      sigma2 % noise level
  end
  
  methods
    function obj = NeuralNetworkAvg(B,k,sigma2,globalFuncNN,shrinkageNN,isBinary)
        if ~exist('isBinary','var')
            isBinary = 1;
        end

        obj.B = B;
        obj.k = k;
        sigma2(sigma2 == 0) = min(sigma2(sigma2 ~= 0));
        obj.sigma2 = sigma2;

        %% Generate Training Data
        rangeNumSamplesAtPoint = [5, 10000];
        %fprintf('Getting examples\n');
        sampleNum = 1;
        [trueMeans,samplesAtPoint,~,targets,sigma2] = SampleFromBasis(obj.B,obj.k,sampleNum,rangeNumSamplesAtPoint,isBinary);

        %fprintf('Getting input features\n');
        inputFeatures = NeuralNetworkAvg.getInputFeatures(samplesAtPoint,sigma2,[],isBinary);
        inputDim = size(inputFeatures,1);
        
        %% Train Neural Network
        outputDim = size(targets,1);
        
        layerNames = {'InnerProduct','APL','InnerProduct','APL','InnerProduct','APL','InnerProduct','EuclideanLoss'};
        hiddenSizes = [1000,1000,1000,outputDim];
        hyperparams = struct;
        hyperparams.miniBatchSize = 100;
        hyperparams.iterations = 60000;
        hyperparams.learningRateBase = 0.1;
        hyperparams.learningRate = hyperparams.learningRateBase;
        hyperparams.momentum = 0.5;
        hyperparams.momentumMax = 0.9;
        hyperparams.momentumChangeSteps = 5000;
        hyperparams.B = obj.B;
        hyperparams.k = obj.k;
        hyperparams.sampRange = rangeNumSamplesAtPoint;
        hyperparams.numExamples = 3000;
        hyperparams.isBinary = isBinary;
        
        hyperparams.learningRateDecayBase = 0.99993;

        if ~exist('globalFuncNN','var') || isempty(globalFuncNN)
            obj.neural_network = NeuralNetwork();
            obj.neural_network.initialize(layerNames,hiddenSizes,inputDim,hyperparams);
            obj.neural_network.train(inputFeatures,targets);
        else
            %fprintf('Skipping global function training. Neural network provided\n');
            obj.neural_network = globalFuncNN;
        end
        
        %% Build network to determine optimal shrinkage

        [trueMeans,samplesAtPoint,~,~] = SampleFromBasis(obj.B,obj.k,sampleNum,rangeNumSamplesAtPoint);
        sigma2 = trueMeans.*(1-trueMeans);
        inputFeatures = NeuralNetworkAvg.getInputFeatures(samplesAtPoint,sigma2,[],isBinary);
        globalMean = obj.neural_network.ForwardProp(inputFeatures);
        
        inputFeatures = [inputFeatures; globalMean];
        inputDim = size(inputFeatures,1);
        
        n = cellfun(@length,samplesAtPoint);
        y = cellfun(@mean,samplesAtPoint);
        targets = zeros(1,size(sigma2,2));
        for ex=1:size(sigma2,2)
            targets(ex) = 0.001;
        end
        
        outputDim = size(targets,1);
        hiddenSizes(end) = outputDim;
        if ~exist('shrinkageNN','var') || isempty(shrinkageNN)
            obj.shrinkage_nn = NeuralNetwork();
            %obj.shrinkage_nn.initialize(layerNames,hiddenSizes,inputDim,hyperparams);
            %obj.shrinkage_nn.train(inputFeatures,targets,1,obj.neural_network);
        else
            obj.shrinkage_nn = shrinkageNN;
        end
        
        %{
        inputFeatures = NeuralNetworkAvg.getInputFeatures(samplesAtPoint);
        m = obj.neural_network.ForwardProp(inputFeatures);
        inputFeatures = [inputFeatures; m];
        A = obj.shrinkage_nn.ForwardProp(inputFeatures);
        sigma2marg = A + sigma2 ./ n;
        shrinkage = sigma2 ./ n ./ sigma2marg;
        mu_h = m  + max(0, 1 - shrinkage) .* (y - m);

        idx = 1; hold off
        plot(m,'-bx'); hold on;
        plot(inputFeatures(1:26),'g');
        plot(mu_h,'-bo');
        keyboard;
        %}
        
    end
    
    function name = get_name(obj)
      name = 'DNN';
    end

    function mu_h = avg(obj, samples, y, N)
        if (~exist('y','var'))
            y = cellfun(@mean, samples);
        end
        if (~exist('N','var'))
            N = cellfun(@length, samples);
        end

        dim = length(samples);
        
        for d =1:dim
            samples{d} = samples{d} - 1; % so samples are between 0 and 1
        end

        isBinary = 1;
        for t=1:length(samples)
            if sum(sum(samples{t} == 0 | samples{t} == 1)) < length(samples{t})
                isBinary = 0;
                break;
            end
        end

        if isBinary
            exampleInputFeatures = NeuralNetworkAvg.getInputFeatures(samples,obj.sigma2,y-1,isBinary);
        else
            exampleInputFeatures = NeuralNetworkAvg.getInputFeatures(samples,obj.sigma2,y,isBinary);
        end
        output = obj.neural_network.ForwardProp(exampleInputFeatures);
        globalMean = output(1:dim);
        %shrinkageInput = [exampleInputFeatures; globalMean];
        %A = obj.shrinkage_nn.ForwardProp(shrinkageInput);
        %A = max(A,0);
        %A = min(A,0.25);
        

        if isBinary
            globalMean = globalMean + 1; % so answer is between 1 and 2
            computeA = @CSAvg.computeAByLineSearch;
        else
            % TODO not implemented
            globalMean = globalMean*8;
            computeA = @CSAvg.computeAByGrad;
        end

        A = computeA(1, y, globalMean, obj.sigma2, N, obj.k);
        
        sigma2marg = A + obj.sigma2 ./ N;
        shrinkage = obj.sigma2 ./ N ./ sigma2marg;
        %shrinkage = A;
        mu_h = globalMean + max(0, 1 - shrinkage) .* (y - globalMean);
        %mu_h = globalMean;     
        %{
        subplot(211)
        hold off;
        plot(globalMean,'b-x')
        hold on
        plot(y,'g')
        hold on
        plot(mu_h,'b-o')
        keyboard;
        %}
    end
  end
  
  methods(Static)
    function inputFeatures = getInputFeatures(samplesAtPoint,sigma2,y,isBinary)
        if ~exist('y','var')
            y = [];
        end
        % TODO add true variance as an input feature
        dim = size(samplesAtPoint,1);
        numExamples = size(samplesAtPoint,2);
        inputFeatures = zeros(dim*3,numExamples);
        
        if ~isempty(y)
            m = y;
        else
            m =  cellfun(@mean,samplesAtPoint); % mean
        end

        
        for ex = 1:numExamples
            example = samplesAtPoint(:,ex);
            
            sampleNum = cellfun(@length,example);
            adjustSampleNum = sampleNum/100000;
            
            exM = m(:,ex);
            exSigma2 = sigma2(:,ex);
            if ~isBinary
                exM = exM/8;
                exSigma2 = exSigma2/5;
            end
            
            inputFeatures(:,ex) = [exM; exSigma2; adjustSampleNum];
        end
    end
  end
end