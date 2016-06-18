classdef Runner < handle
 properties
  avgs    % a list of methods added, type <Avg>.
  allsamples % all of the samples.
  groupLabel % label of group e.g. timepoint
  truth   % ground truth from <allsamples>.
  metric  % a func @(mu_hs, truth). evaluating the performance.
  metric_description

  mu_h    % a dictionary of recovered means for each method.
  score   % a dictionary of score for each method. 
  score_std % a dictionary of score standard deviations.
  ratios  % ratios last used.
  seeds   % seeds last used.
  
  methodSampleNum % number of samples in each group for each run and ratio
  method_mu_hs
  
  datasetType
  
  sampler %% sample method.
 end

 methods
  function obj = Runner(allsamples,groupLabel) 
    % create an experiment runner.
    if ~exist('groupLabel','var')
        groupLabel = 1:length(allsamples);
    end
    obj.groupLabel = groupLabel;
    obj.avgs = {};
    obj.mu_h = containers.Map();
    obj.score = containers.Map();
    obj.score_std = containers.Map();
    
    obj.allsamples = allsamples;
    obj.metric = @metric_mean_abs_percent;
    obj.metric_description = 'Mean Absolute Difference';
    obj.truth = cellfun(@mean, obj.allsamples); % approximate true means with means of all samples.
    
    obj.methodSampleNum = containers.Map();
    
    obj.sampler = @sample;
  end

  function [] = add_method(obj, avg)   
    % add an averaging method to the experiment runner.
    assert(isa(avg, 'Avg'));
    obj.avgs{length(obj.avgs)+1} = avg;
  end

  function [] = run_all(obj, ratios, seeds, y, N)
    %% run all methods on the dataset with <ratios> and <seeds>.
    if (~exist('y','var'))
        y = [];
    end
    if (~exist('N','var'))
        N = [];
    end
    numMethods = length(obj.avgs);
    n_ratio = length(ratios);
    n_run = length(seeds);
    
    for mi = 1:numMethods
        method = obj.avgs{mi};
        name = method.get_name();
        obj.method_mu_hs{mi} = cell(n_run, n_ratio);
        obj.methodSampleNum(name) = cell(n_run, n_ratio);
    end
    
    obj.ratios = sort(ratios);
    obj.seeds = seeds;
    obj.method_mu_hs = cell(length(obj.avgs),1);
    for nj = 1:n_ratio
        for ni = 1:n_run
            samples = obj.sampler(obj.allsamples, ratios(nj), 1, seeds(ni));
            for mi = 1:numMethods
              method = obj.avgs{mi};
              name = method.get_name();
              %fprintf('-----Running method %s-----\n',name)
              [mu_hs, sampleNum] = obj.run_ratio(method, ratios, seeds, y, N, nj, ni, samples,...
                  obj.method_mu_hs{mi}, obj.methodSampleNum(name));
              obj.method_mu_hs{mi} = mu_hs;
              
              obj.mu_h(name) = mu_hs;
              obj.methodSampleNum(name) = sampleNum;
            end
            %{
            y = cellfun(@mean,samples);
            numSamps = sum(cellfun(@length,samples));
            x = obj.groupLabel;
            h = plot(x,y,'o'); hold on;
            set(h, 'LineWidth', 3);
            h = plot(x,obj.truth,'k-'); hold on;
            set(h, 'LineWidth', 3);
            allkeys = {'sample means','true means'};
            allMethodNames = sortMethods(obj.mu_h.keys());
            for mi = 1:numMethods
                name = allMethodNames{mi};
                allkeys{mi+2} = name;
                method_mu_h = obj.mu_h(name);
                h = plot(x,method_mu_h{1,1},getLineStyle(name));
                set(h, 'LineWidth', 3);
            end
            ylim([1 2])
            title(sprintf('Number of Samples = %i',numSamps))
            legend(allkeys);
            keyboard;
            %}
        end
    end
    for mi = 1:numMethods
        method = obj.avgs{mi};
        name = method.get_name();
        [obj.score(name), obj.score_std(name)] = obj.metric(obj.mu_h(name), obj.truth);
    end
  end
  
  function plot_means(obj)
    %% Plot means
    numMethods = length(obj.avgs);
    if ~exist('xaxis','var')
        xaxis = 1:length(obj.truth);
    end
    
    y = obj.truth;
    if (strcmpi('xbox',obj.datasetType))
        y = 100*(y-1);
    end
    legendInfo = cell(numMethods+1,1);

    plot(xaxis,y,'o');
    legendInfo{1} = 'True Means';
    hold on;
    for mi = 1:numMethods
        method = obj.avgs{mi};
        name = method.get_name();
        mu_hs = obj.method_mu_hs{mi};
        mu = mu_hs{end,end};
        
        if (strcmpi('xbox',obj.datasetType))
            mu = 100*(mu-1);
        end

        plot(xaxis,mu);
        legendInfo{1+mi} = name;
        hold on;
    end
    legend(legendInfo);
    hold off;
    if (strcmpi('xbox',obj.datasetType))
        hold on
        fiftyMark = 50*ones(length(xaxis),1);
        fiftyTwoMark = 51.96*ones(length(xaxis),1);
        plot(xaxis,fiftyMark,xaxis,fiftyTwoMark,'--');
    end
  end
  
  function obj = run_one(obj, avg, ratios, seeds)
    obj.ratios = ratios;
    obj.seeds = seeds;
    name = avg.get_name();
    mu_hs = obj.run_ratio(avg, ratios, seeds);
    [obj.score(name), obj.score_std(name)] = obj.metric(mu_hs, obj.truth);
    obj.mu_h(name) = mu_hs;
  end
  
  function [mu_hs, sampleNum] = run_ratio(obj, avg, ratios, seeds, y, N, nj, ni, samples, mu_hs, sampleNum)
    % run all ratio tests with the given <avg> method.
    makeY = 0;
    makeN = 0;
    if (~exist('y','var')) || isempty(y)
        makeY = 1;
    end
    if (~exist('N','var')) || isempty(N)
        makeN = 1;
    end

    if makeY == 1
        y = cellfun(@mean,samples);
    end
    if makeN == 1
        N = cellfun(@length,samples);
    end
    sampleNum{ni, nj} = cellfun(@length,samples);
    mu_hs{ni, nj} = avg.avg(samples,y,N);
  end


  function hf = plot_score(obj, options)
    hf = [];
    %subplot(211)
    %obj.plot_means();
    %subplot(212)
    
    score = obj.score;
    score_std = obj.score_std;
    ratios = obj.ratios;

    allkeys = score.keys();
    allkeys = sortMethods(allkeys);
    
    if nargin >= 2
      check_option = @(x)(nargin >= 2 && isfield(options, x));
    else
      check_option = @(x)(false);
    end
    colorShade = 0.0;
    for i = 1:length(allkeys)
      name = allkeys{i};
      sc = cell2mat(score(name));
      sc_std = cell2mat(score_std(name));
      [lineStyle, extra] = getLineStyle(name);
      if check_option('errorbar')
        h = errorbar(100*ratios, sc, sc_std, lineStyle); hold on;
      elseif ~extra
        h = plot(100*ratios, sc, lineStyle); hold on;
      else
        h = plot(100*ratios, sc, lineStyle, 'color', [0 colorShade 0]); hold on;
        colorShade = min(colorShade + 0.3,1);
      end
      set(h, 'LineWidth', 3);
    end
    xlabel('Percentage of Samples');
    ylabel(obj.metric_description);
    hl = legend(allkeys);
    %set(h, 'LineWidth', 2);
    set(gca,'FontSize',10,'fontWeight','bold');
  end
 end
end
