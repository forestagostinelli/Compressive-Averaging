 function create_adjacency_matrix()
    clear
    %% Check method is working
    file = '../survey-data-bcs-data-store/election/adjacency.txt';
    matrix = compute_adjacency_matrix(file);
    
    prevAdj = load('../survey-data-bcs-data-store/election/adjacency.mat');
    assert(isempty(find(matrix ~= prevAdj.matrix, 1)))
    
    %% DC with no neighbors
    file = '../survey-data-bcs-data-store/election/adjacency_DC_Alone.txt';
    matrix = compute_adjacency_matrix(file);
    save('../survey-data-bcs-data-store/election/adjacency_DC_Alone.mat','matrix');
    
    %% DC with neighbors
    file = '../survey-data-bcs-data-store/election/adjacency_DC.txt';
    matrix = compute_adjacency_matrix(file);
    save('../survey-data-bcs-data-store/election/adjacency_DC.mat','matrix');
    
    %% No DC and no HI
    file = '../survey-data-bcs-data-store/election/adjacency_noDC_noHI.txt';
    matrix = compute_adjacency_matrix(file);
    save('../survey-data-bcs-data-store/election/adjacency_noDC_noHI.mat','matrix');
end

function adj = compute_adjacency_matrix(file)

    %% Load adjacency matrix
    data = importdata(file);
    dim = length(data);
    adj = zeros(dim,dim);
    entryNames = cell(dim,1);
    
    %% Compute adjacency matrix
    for d =1:dim
        data{d} = strsplit(data{d},',');
        entryNames{d} = data{d}{1};
    end
    
    for d =1:dim
        adj(d,:) = ismember(entryNames,data{d});
        adj(d,d) = 0;
    end
end

