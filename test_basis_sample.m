% Test basis sample
clear
B = wmpdictionary(26, 'LstCpt', {{'wpsym4', 5}});
k = 2;
sampleNum = 100;
rangeNumSamplesAtPoint = [10, 20];

[trueMeans, samplesAtPoint, trueGlobalFuncs] = SampleFromBasis(B,k,sampleNum,rangeNumSamplesAtPoint);