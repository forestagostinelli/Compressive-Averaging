function [y_h, supp] = bootstrapOmp(s, B, sigma2, k, eps, bootstrapAlpha, bootstrapSupp)
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

%% Pick which k to use
% TODO make sure pos picked has support
if ~(length(bootstrapAlpha(bootstrapAlpha ~= 0)) == length(bootstrapSupp))
    keyboard
end


[~,bootStrapPos] = sort(abs(bootstrapAlpha(bootstrapAlpha ~= 0)),'ascend');
bootStrapPos = bootStrapPos(1:min(2,length(bootStrapPos)));

%bootStrapPos = [min([1 2],length(bootstrapSupp))];
bootStrapPos = max(bootStrapPos,1);
bootStrapPos = bootStrapPos(1:(min(length(bootstrapSupp),length(bootStrapPos))));
bootStrapPos = unique(bootStrapPos);

numSharedSupp = length(bootStrapPos);

aug_y=zeros(k,1);
for p=1:numSharedSupp
    pickKPos = bootstrapSupp(bootStrapPos(p));
    Aug_t(:,p) = B(:,pickKPos);
    B(:,pickKPos)=zeros(M,1);

    aug_y(p) = bootstrapAlpha(pickKPos)*norms(pickKPos);
    r_n=s - Aug_t * aug_y;                            

    supp(p) = pickKPos;
end

%% Pick the rest of k
for t = (1+numSharedSupp):k
    if (r_n'  * r_n < eps)   
        supp = supp(1:t-1);
        aug_y = aug_y(1:t-1);
        break;
    end
    
    product = abs(B' * r_n);
    [~, pos] = max(product);
    Aug_t(:, t) = B(:,pos);
    B(:,pos)=zeros(M,1);
    
    new_aug_y=pinv(Aug_t' * Aug_t)*Aug_t'* s;
    aug_y(t) = new_aug_y(t);
    r_n=s - Aug_t * aug_y;                            

    supp(t) = pos;                          
end
y_h(supp) = aug_y;
y_h = y_h ./ norms';
