%clear
%close all
T = 30;
covMat = zeros(T,T);

fullD = wmpdictionary(T, 'LstCpt', {{'wpsym4', 5}});
D = fullD(:, 1:8);
k = 3;

%load('../createdData/trainedNNs/simulated.mat')
nn = NeuralNetworkAvg(D,k,rand(T,1),[],[],0);
%save('../createdData/trainedNNs/simulated.mat','nn');

allNoise = [0 0.1 0.2];
allL = [5 10 20];

figure;
plotPos = 1;
onlyExamples = 0;
numExamples = 1;
for n=1:length(allNoise)
    for l=1:length(allL)
        noise = allNoise(n);
        len = allL(l);
        fprintf('Noise %f, Length %f\n',noise,len);

        for i=1:T
            for j=1:T
                covMat(i,j) = exp(-((i-j)^2)/(2*len^2));
                if i == j
                    covMat(i,j) = covMat(i,j) + noise^2;
                end
            end
        end

        meanVals = zeros(T,1);

        for ex=1:numExamples
            rng('shuffle')
            trueMeans = mvnrnd(meanVals,covMat);

            if onlyExamples
                subplot(length(allNoise),length(allL),plotPos);
                plot(trueMeans);  hold on;
            end
            samples = cell(T,1);

            sigma2 = abs(normrnd(0,5,T,1));
            %sigma2(:) = 10;
            sampleNum = 2000;
            for t=1:T
                samplesT = normrnd(trueMeans(t),sqrt(sigma2(t)),sampleNum,1);
                samples{t} = samplesT';
            end

            sigma2 = cellfun(@var,samples);
            M = cellfun(@mean,samples);

            %% Estimate means
            if ~onlyExamples
                runner = Runner(samples);
                runner.add_method(nn);

                runner.add_method(CSAvg(D, k, sigma2));

                %baselines.
                runner.add_method(SampleAvg());
                runner.add_method(JamesSteinAvg(sigma2));
                runner.add_method(MTAvg(1, sigma2));

                ratios = [0.01 0.03 0.05 0.1 0.2 0.3];
                seeds = 1:10;

                runner.run_all(ratios, seeds);
                if ex == 1
                    score = runner.score;
                else
                    allkeys = score.keys();
                    for i = 1:length(allkeys)
                        key = allkeys{i};
                        keyScore = score(key);
                        runScore = runner.score(key);
                        for s=1:length(keyScore)
                            keyScore{s} = keyScore{s} + runScore{s};
                        end
                        score(key) = keyScore;
                    end
                end
            end
        end
        if ~onlyExamples
            allkeys = score.keys();
            for i = 1:length(allkeys)
                key = allkeys{i};
                keyScore = score(key);
                for s=1:length(keyScore)
                    keyScore{s} = keyScore{s}/numExamples;
                end
                score(key) = keyScore;
            end
            runner.score = score;
            subplot(length(allNoise),length(allL),plotPos);
            runner.plot_score();
        end
        title(sprintf('Length %i, Noise %.1f',len,noise));
        plotPos = plotPos + 1;
        hold off;
    end
end

%{
figure;
plot(trueMeans); hold on;
plot(M);
for t=1:T
    x = t*ones(length(samples{t}),1);
    scatter(x,samples{t});
end
%}