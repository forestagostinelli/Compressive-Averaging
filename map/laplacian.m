function L = laplacian(G)
% compute the laplacian of an undirected graph.
    L = diag(sum(G)) - G;
end