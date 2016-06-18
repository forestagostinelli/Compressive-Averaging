function [errorPerState,errorCountry] = twoPartyElectionError(cells,poststrat,plotData,onlyCountry)
    if ~exist('onlyCountry','var')
        onlyCountry = 0;
    end
    isCell = strcmpi(class(cells),'Cells');
    if poststrat && isCell
        countryPrediction = cells.getPostStratEst();
    elseif isCell
        countryPrediction = cells.getRawEst();
    else
        demoNamesString = 'all';
        catNamesString = 'all';
        catMap = cells(demoNamesString);
        catMeans = catMap(catNamesString);
        countryPrediction = catMeans(end);
    end
    countryPrediction = 100*(countryPrediction-1);
    errorCountry = individualElectionError(countryPrediction,'Country');
    
    % TODO for now excluding DC and HI
    areas = {'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','ID','IL','IN',...
        'IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',...
        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA'...
        'WA','WV','WI','WY'};
    
    errorPerState = zeros(length(areas),1);
    if onlyCountry
        return;
    end
    predictions = zeros(length(areas),1);
    truths = zeros(length(areas),1);
    for a=1:length(areas)
        if isCell
            prediction = getCellGroupEst(cells,{'state'},areas(a),poststrat);
        else
            catMap = cells('state');
            catMeans = catMap(areas{a});
            prediction = catMeans(end);
        end
        prediction = 100*(prediction-1);
        predictions(a) = prediction;
        [errorPerState(a), truths(a)] = individualElectionError(prediction,areas{a});
    end
    
    if plotData
        xaxis = 1:length(areas);
        plot(xaxis,truths,'--o',xaxis,predictions,'-o');
        hold on;
        fiftyMark = 50*ones(length(xaxis),1);
        plot(xaxis,fiftyMark,'--');
        hold off;
        ylim([0 100]);
        xlim([min(xaxis) max(xaxis)]);
        set(gca, 'XTick',1:length(areas), 'XTickLabel', areas)
        title(sprintf('%s','State Accuracy'))
    end
end

function [err, truth]= individualElectionError(prediction,area)
    area = upper(area);
    switch area
        case 'COUNTRY'
            truth = 100*(65915796/(65915796 + 60933500));
        case 'AL'
            truth = 100*(795696/(795696 + 1255925));
        case 'AK'
            truth = 100*(122640  /(122640 + 164676));
        case 'AZ'
            truth = 100*(1025232   /(1025232  + 1233654));
        case 'AR'
            truth = 100*(394409  /(394409 + 647744));
        case 'CA'
            truth = 100*(7854285  /(7854285  + 4839958));
        case 'CO'
            truth = 100*(1323101  /(1323101 + 1185243));
        case 'CT'
            truth = 100*(905083  /(905083 + 634892));
        case 'DE'
            truth = 100*(242584  /(242584 + 165484));
        case 'DC'
            truth = 100*(267070  /(267070  + 21381));
        case 'FL'
            truth = 100*(4237756  /(4237756 + 4163447));
        case 'GA'
            truth = 100*(1773827  /(1773827 + 2078688));
        case 'HI'
            truth = 100*(306658  /(306658 + 121015));
        case 'ID'
            truth = 100*(212787  /(212787 + 420911));
        case 'IL'
            truth = 100*(3019512  /(3019512 + 2135216));
        case 'IN'
            truth = 100*(1152887  /(1152887 + 1420543));
        case 'IA'
            truth = 100*(822544  /(822544 + 730617));
        case 'KS'
            truth = 100*(440726  /(440726 + 692634));
        case 'KY'
            truth = 100*(679370  /(679370 + 1087190));
        case 'LA'
            truth = 100*(809141  /(809141 + 1152262));
        case 'ME'
            truth = 100*(401306 /(401306 + 292276));
        case 'MD'
            truth = 100*(1677844  /(1677844 + 971869));
        case 'MA'
            truth = 100*(1921290  /(1921290 + 1188314));
        case 'MI'
            truth = 100*(2564569  /(2564569 + 2115256));
        case 'MN'
            truth = 100*(1546167  /(1546167 + 1320225));
        case 'MS'
            truth = 100*(562949  /(562949 + 710746));
        case 'MO'
            truth = 100*(1223796  /(1223796 + 1482440));
        case 'MT'
            truth = 100*(201839  /(201839 + 267928));
        case 'NE'
            truth = 100*(302081  /(302081 + 475064));
        case 'NV'
            truth = 100*(531373  /(531373 + 463567));
        case 'NH'
            truth = 100*(369561  /(369561 + 329918));
        case 'NJ'
            truth = 100*(2125101  /(2125101 + 1477568));
        case 'NM'
            truth = 100*(415335  /(415335 + 335788));
        case 'NY'
            truth = 100*(4485741  /(4485741 + 2490431));
        case 'NC'
            truth = 100*(2178391  /(2178391 + 2270395));
        case 'ND'
            truth = 100*(124827  /(124827 + 188163));
        case 'OH'
            truth = 100*(2827710  /(2827710 + 2661433));
        case 'OK'
            truth = 100*(443547  /(443547 + 891325));
        case 'OR'
            truth = 100*(970488  /(970488 + 754175));
        case 'PA'
            truth = 100*(2990274  /(2990274 + 2680434));
        case 'RI'
            truth = 100*(279677  /(279677 + 157204));
        case 'SC'
            truth = 100*(865941  /(865941 + 1071645));
        case 'SD'
            truth = 100*(145039  /(145039 + 210610));
        case 'TN'
            truth = 100*(960709  /(960709 + 1462330));
        case 'TX'
            truth = 100*(3308124  /(3308124 + 4569843));
        case 'UT'
            truth = 100*(251813  /(251813 + 740600));
        case 'VT'
            truth = 100*(199239  /(199239 + 92698));
        case 'VA'
            truth = 100*(1971820  /(1971820 + 1822522));
        case 'WA'
            truth = 100*(1755396  /(1755396 + 1290670));
        case 'WV'
            truth = 100*(238269  /(238269 + 417655));
        case 'WI'
            truth = 100*(1620985  /(1620985 + 1407966));
        case 'WY'
            truth = 100*(69286  /(69286 + 170962));
        otherwise
            error('Unrecognized State Abbreviation %s',stateAbrev);
    end
    err = abs(prediction - truth);
end