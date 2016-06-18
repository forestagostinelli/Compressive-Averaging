% Test NN
clear;

x = -1:0.1:1;
dim = length(x);
offsets = -1:0.1:1;

offsetNum = length(offsets);

inputs = zeros(dim,offsetNum);
outputs = zeros(dim,offsetNum);

for o=1:offsetNum
    input = x + offsets(o);
    inputs(:,o) = input;
    outputs(:,o) = sin(input);
end

layerNames = {'InnerProduct','ReLU','InnerProduct','EuclideanLoss'};
hiddenSizes = [1000,21];
hyperparams = struct;
hyperparams.miniBatchSize = 100;
hyperparams.iterations = 100;
hyperparams.learningRate = 0.1;

hyperparams.learningRateDecayBase = 0.99999;

nn = NeuralNetwork();
nn.initialize(layerNames,hiddenSizes,dim,hyperparams);
nn.train(inputs,outputs);