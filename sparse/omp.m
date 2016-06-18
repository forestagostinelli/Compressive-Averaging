function [y_h, supp] = omp(s,B,sigma2, k, eps)
% OMP Recovery
% input:
%           s - the signal.
%           B - the basis.
%           sigma2 - a vector of variances. noise level of each observation.
%           k - find k-sparse solution.
%           eps - convergence creterion.


%% change scaling. 
L_inv = diag(1./sqrt(sigma2));
B = L_inv * B;
s = L_inv * s;
norms = sqrt(sum(B .* B));
B = B ./ repmat(norms, size(B,1), 1);

%% use regular omp.

M = size(B, 1);                            % Size of orignal space.
N = size(B, 2);                            % dimension of latent space.
y_h = zeros(N, 1);                      % recovered signal.
Aug_t=zeros(M, k);                  %  subset of basis.
supp = zeros(1,k);
r_n = s;                                            %  residual.

for t = 1:k                                   
    product = abs(B' * r_n);   
    [~, pos] = max(product);
    Aug_t(:, t) = B(:,pos);         
    B(:,pos)=zeros(M,1);                                    
    
    aug_y=pinv(Aug_t' * Aug_t)*Aug_t'* s; 
    r_n=s - Aug_t * aug_y;                            

    supp(t) = pos;                          
    
    if (r_n'  * r_n < eps)   
        supp = supp(1:t);
        aug_y = aug_y(1:t);
        break;
    end
end
y_h(supp) = aug_y;
y_h = y_h ./ norms';
