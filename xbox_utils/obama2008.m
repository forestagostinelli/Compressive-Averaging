function [obamaFraction] = obama2008(state)
    switch state
        case 'AL'
            obamaFraction = (813479 /(813479 + 1266546));
        case 'AK'
            obamaFraction = (123594	/(123594 + 193841));
        case 'AZ'
            obamaFraction = (1034707   /(1034707 + 1230111));
        case 'AR'
            obamaFraction = (422310  /(422310 + 638017));
        case 'CA'
            obamaFraction = (8274473  /(8274473  + 5011781));
        case 'CO'
            obamaFraction = (1288633  /(1288633 + 1073629));
        case 'CT'
            obamaFraction = (997772  /(997772 + 629428));
        case 'DE'
            obamaFraction = (255459  /(255459 + 152374));
        case 'DC'
            obamaFraction = (245800  /(245800  + 17367));
        case 'FL'
            obamaFraction = (4282074  /(4282074 + 4045624));
        case 'GA'
            obamaFraction = (1844123  /(1844123 + 2048759));
        case 'HI'
            obamaFraction = (325871  /(325871 + 120566));
        case 'ID'
            obamaFraction = (236440  /(236440 + 403012));
        case 'IL'
            obamaFraction = (3419348  /(3419348 + 2031179));
        case 'IN'
            obamaFraction = (1374039  /(1374039 + 1345648));
        case 'IA'
            obamaFraction = (828940  /(828940 + 682379));
        case 'KS'
            obamaFraction = (514765  /(514765 + 699655));
        case 'KY'
            obamaFraction = (751985  /(751985 + 1048462));
        case 'LA'
            obamaFraction = (782989  /(782989 + 1148275));
        case 'ME'
            obamaFraction = (421923 /(421923 + 295273));
        case 'MD'
            obamaFraction = (1629467  /(1629467 + 959862));
        case 'MA'
            obamaFraction = (1904097  /(1904097 + 1108854));
        case 'MI'
            obamaFraction = (2872579  /(2872579 + 2048639));
        case 'MN'
            obamaFraction = (1573354  /(1573354 + 1275409));
        case 'MS'
            obamaFraction = (554662  /(554662 + 724597));
        case 'MO'
            obamaFraction = (1441911  /(1441911 + 1445814));
        case 'MT'
            obamaFraction = (231667  /(231667 + 242763));
        case 'NE'
            obamaFraction = (333319  /(333319 + 452979));
        case 'NV'
            obamaFraction = (533736  /(533736 + 412827));
        case 'NH'
            obamaFraction = (384826  /(384826 + 316534));
        case 'NJ'
            obamaFraction = (2215422  /(2215422 + 1613207));
        case 'NM'
            obamaFraction = (472422  /(472422 + 346832));
        case 'NY'
            obamaFraction = (4804945  /(4804945 + 2752771));
        case 'NC'
            obamaFraction = (2142651  /(2142651 + 2128474));
        case 'ND'
            obamaFraction = (141278  /(141278 + 168601));
        case 'OH'
            obamaFraction = (2940044  /(2940044 + 2677820));
        case 'OK'
            obamaFraction = (502496  /(502496 + 960165));
        case 'OR'
            obamaFraction = (1037291  /(1037291 + 738475));
        case 'PA'
            obamaFraction = (3276363  /(3276363 + 2655885));
        case 'RI'
            obamaFraction = (296571  /(296571 + 165391));
        case 'SC'
            obamaFraction = (862449  /(862449 + 1034896));
        case 'SD'
            obamaFraction = (170924  /(170924 + 203054));
        case 'TN'
            obamaFraction = (1087437  /(1087437 + 1479178));
        case 'TX'
            obamaFraction = (3528633  /(3528633 + 4479328));
        case 'UT'
            obamaFraction = (327670  /(327670 + 596030));
        case 'VT'
            obamaFraction = (219262  /(219262 + 98974));
        case 'VA'
            obamaFraction = (1959532  /(1959532 + 1725005));
        case 'WA'
            obamaFraction = (1750848  /(1750848 + 1229216));
        case 'WV'
            obamaFraction = (303857  /(303857 + 397466));
        case 'WI'
            obamaFraction = (1677211  /(1677211 + 1262393));
        case 'WY'
            obamaFraction = (82868  /(82868 + 164958));
        otherwise
            error('Unrecognized State Abbreviation %s',state);
    end
end

