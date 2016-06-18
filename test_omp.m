%test_omp
clear
x = -3:0.5:3;
dim = length(x);
s = 3*sin(2*x) + x;
%s = s + normrnd(0,1,1,dim);
%s = s + [0.1, 0.2, 0.9, 0.1, 0.1, 0.2, 0.1, 0.2, 0.5, 0.3, 0.1, 0.3, 0.6];
s = s';
%B = wmpdictionary(dim, 'LstCpt', {'dct'});
B = wmpdictionary(dim, 'LstCpt', {{'wpsym4', 5}});
%B = wmpdictionary(dim, 'LstCpt', {{'haar', 5}});
%B = wmpdictionary(dim, 'LstCpt', {'sin'}); B = [ones(dim,1) B];
%B = [eye(dim) ones(dim,1)];
%B = B(:, 1:6);

eps = 10^-4;
sigma2 = ones(dim,1);

k = 2;

coeff = omp(s,B,sigma2, k, eps)

recoveredSig = B*coeff;

mse = mean((recoveredSig - s).^2);

fprintf('MSE is %f\n',mse)

plot(x,s,x,recoveredSig)