classdef NeuralNetwork < handle
    properties
        hyperparams
        layers
        layerNum
    end
    
    methods
        function initialize(obj,layerNames,hiddenSizes,inputNum,hyperparams)
            fprintf('Initializing Neural Network\n')
            obj.hyperparams = hyperparams;
            obj.layerNum = length(layerNames);
            obj.layers = cell(obj.layerNum,1);
            obj.hyperparams.momentumInit = obj.hyperparams.momentum;
            hiddenSizePos = 1;
            for i = 1:obj.layerNum
                layerName = layerNames{i};
                if strcmpi(layerName,'InnerProduct')
                    obj.layers{i} = InnerProduct();
                    
                    obj.layers{i}.Initialization(inputNum,hiddenSizes(hiddenSizePos));
                    
                    inputNum = hiddenSizes(hiddenSizePos);
                    hiddenSizePos = hiddenSizePos + 1;
                elseif strcmpi(layerName,'ReLU')
                    obj.layers{i} = ReLU();
                    obj.layers{i}.Initialization(inputNum,inputNum);
                elseif strcmpi(layerName,'APL')
                    obj.layers{i} = APL();
                    obj.layers{i}.Initialization(inputNum,inputNum);
                elseif strcmpi(layerName,'LWTA')
                    obj.layers{i} = LWTA();
                    obj.layers{i}.Initialization(inputNum,inputNum);
                elseif strcmpi(layerName,'Sigmoid')
                    obj.layers{i} = Sigmoid();
                    obj.layers{i}.Initialization(inputNum,inputNum);
                elseif strcmpi(layerName,'EuclideanLoss')
                    obj.layers{i} = EuclideanLoss();
                else
                    error('Unrecognized layer name %s',layerName)
                end
            end
        end
        
        % inputs and targets of the shape dim x numExamples
        function train(obj,inputs,targets,shrinkage,globalFuncNN)
            if ~exist('shrinkage','var')
                shrinkage = 0;
            end
            numExamples = obj.hyperparams.numExamples;
            obj.hyperparams.miniBatchSize = min(obj.hyperparams.miniBatchSize,numExamples);
            exSinceGeneration = 0;
            for itr = 1:obj.hyperparams.iterations
                if exSinceGeneration > 10*numExamples || itr == 1
                    fprintf('Creating new samples\n');
                    clear targets samplesAtPoint;
                    [trueMeans,samplesAtPoint,~,targets,sigma2] = SampleFromBasis(obj.hyperparams.B,obj.hyperparams.k,numExamples,obj.hyperparams.sampRange,obj.hyperparams.isBinary);
                    inputs = NeuralNetworkAvg.getInputFeatures(samplesAtPoint,sigma2,[],obj.hyperparams.isBinary);

                    if shrinkage
                        fprintf('Creating shrinkage features\n');
                        globalMean = globalFuncNN.ForwardProp(inputs);
                        inputs = [inputs; globalMean];

                        sigma2 = max(sigma2,0.0000001);
                        n = cellfun(@length,samplesAtPoint);
                        y = cellfun(@mean,samplesAtPoint);
                        targets = zeros(1,size(sigma2,2));
                        dim = size(sigma2,1);
                        
                        a = 0:0.0001:1;
                        %computeA = @CSAvg.computeAByGrad;
                        for ex=1:size(sigma2,2)
                            %A = computeA(1, y(:,ex), globalMean(:,ex), sigma2(:,ex), n(:,ex), obj.hyperparams.k);
                            %A = min(A,1);
                            %A = max(A,0);
                            %targets(:,ex) = A;
                            
                            %{
                            sigmaRatio = sigma2(:,ex) ./ n(:,ex);
                            M = globalMean(:,ex);
                            objFunc = ...
                                @(A) sum((trueMeans(:,ex) - ...
                                (M  + max(0, 1 - (sigmaRatio ./ (A + sigmaRatio))) ...
                                .*(y(:,ex) - M))).^2)/dim;
                            
                            objVal = zeros(length(a),1);
                            for i=1:length(a)
                                objVal(i) = objFunc(a(i));
                            end
                            [~,idx] = min(objVal);
                            targets(:,ex) = a(idx);
                            %}
                            
                            
                            M = globalMean(:,ex);
                            objFunc = ...
                                @(A) sum((trueMeans(:,ex) - ...
                                (M  + max(0, 1 - A).*(y(:,ex) - M))).^2)/dim;
                            
                            objVal = zeros(length(a),1);
                            for i=1:length(a)
                                objVal(i) = objFunc(a(i));
                            end
                            [~,idx] = min(objVal);
                            targets(:,ex) = a(idx);
                            

                            %{
                            A = a(idx);
                            sigma2marg = A + sigma2(:,ex) ./ n(:,ex);
                            shrinkage = sigma2(:,ex) ./ n(:,ex) ./ sigma2marg;
                            mu_h = globalMean(:,ex)  + max(0, 1 - shrinkage) .* (y(:,ex) - globalMean(:,ex));

                            hold off;
                            plot(globalMean(:,ex),'-bx'); hold on;
                            plot(y(:,ex),'g');
                            plot(mu_h,'-bo');
                            plot(trueMeans(:,ex),'k')
                            keyboard;
                            %}

                        end
                    end
                    
                    exSinceGeneration = 0;
                end
                idxs = randsample(numExamples,obj.hyperparams.miniBatchSize);
                exSinceGeneration = exSinceGeneration + obj.hyperparams.miniBatchSize;
                input_batch = inputs(:,idxs);
                targets_batch = targets(:,idxs);
                % Forwardprop
                loss = obj.ForwardProp(input_batch,targets_batch);

                % Backprop
                obj.BackProp();

                % Update params
                obj.UpdateParams();
                
                if mod(itr,100) == 0 || itr == 1
                    fprintf('Objective: %f, Iteration: %i, Learning Rate: %f, Momentum: %f\n',...
                        loss,itr,obj.hyperparams.learningRate,obj.hyperparams.momentum);
                end
                
                % Update momentum and learning rate
                obj.hyperparams.learningRate = ...
                    obj.hyperparams.learningRateBase*(obj.hyperparams.learningRateDecayBase)^itr;
                momentumStep = ...
                    (obj.hyperparams.momentumMax - obj.hyperparams.momentumInit)/obj.hyperparams.momentumChangeSteps;
                obj.hyperparams.momentum = obj.hyperparams.momentum + momentumStep;
                obj.hyperparams.momentum = min(obj.hyperparams.momentum,obj.hyperparams.momentumMax);
            end
        end
        
        function topOut = ForwardProp(obj,input,targets)
            doLoss = 1;
            if ~exist('targets','var')
                doLoss = 0;
            end
            for i = 1:obj.layerNum
                if isa(obj.layers{i}, 'Layer')
                    input = obj.layers{i}.ForwardProp(input);
                elseif isa(obj.layers{i}, 'LossLayer') && doLoss
                    topOut = obj.layers{i}.ForwardProp(input,targets);
                end
            end
            if ~doLoss
                topOut = input;
            end
        end
        
        function BackProp(obj)
            grad = obj.layers{obj.layerNum}.BackProp();
            for i = (obj.layerNum-1):-1:1
                grad = obj.layers{i}.BackProp(grad);
            end
        end
        
        function UpdateParams(obj)
            miniBatchSize = obj.hyperparams.miniBatchSize;
            learningRate = obj.hyperparams.learningRate;
            momentum = obj.hyperparams.momentum;
            for i = 1:obj.layerNum
                if isa(obj.layers{i}, 'Layer')
                    fields = fieldnames(obj.layers{i}.params);
                    numFields = length(fields);
                    for f = 1:numFields
                        param = obj.layers{i}.params.(fields{f});
                        paramGrad = obj.layers{i}.paramsGrad.(fields{f})/miniBatchSize;
                        paramsPrevUpdate = obj.layers{i}.paramsPrevUpdate.(fields{f});
                        
                        update = - learningRate*paramGrad + momentum*paramsPrevUpdate;
                        
                        obj.layers{i}.params.(fields{f}) =  param + update;
                        
                        obj.layers{i}.paramsPrevUpdate.(fields{f}) = update;
                    end
                end
            end
        end
    end
end