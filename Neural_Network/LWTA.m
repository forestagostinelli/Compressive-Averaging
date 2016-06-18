classdef LWTA < Layer
        
    methods
        function Initialization(obj,bottomShape,topShape)
            inputNum = sum(bottomShape);
            outputNum = sum(topShape);

            obj.params = struct;
            obj.hyperParams.blockSize = 2;
            obj.hyperParams.selectedNeurons = [];
        end
        
        function output = ForwardProp(obj,input)
            obj.input = input;
            % TODO handle case where input size is not divisible by block
            % size
            inputSize = size(input,1);
            batchSize = size(input,2);
            input = reshape(input,[obj.hyperParams.blockSize inputSize/obj.hyperParams.blockSize batchSize]);
            [~,idxs] = max(input);
            
            obj.hyperParams.selectedNeurons = false(size(input));
            for i=1:obj.hyperParams.blockSize
                obj.hyperParams.selectedNeurons(i,:,:) = ~idxs == i;
            end
            obj.hyperParams.selectedNeurons = reshape(obj.hyperParams.selectedNeurons,[inputSize batchSize]);
            
            output = obj.input.*obj.hyperParams.selectedNeurons;
            
            obj.output = output;
        end
        
        function grad = BackProp(obj,grad)
            %% Propdown Gradient
            grad = grad.*obj.hyperParams.selectedNeurons;
        end
    end
    
end