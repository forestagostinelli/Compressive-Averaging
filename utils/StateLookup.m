function fullStateName = StateLookup( stateAbrev )
    switch stateAbrev
        case 'AL'
            fullStateName = 'Alabama';
        case 'AK'
            fullStateName = 'Alaska';
        case 'AZ'
            fullStateName = 'Arizona';
        case 'AR'
            fullStateName = 'Arkansas';
        case 'CA'
            fullStateName = 'California';
        case 'CO'
            fullStateName = 'Colorado';
        case 'CT'
            fullStateName = 'Connecticut';
        case 'DE'
            fullStateName = 'Delaware';
        case 'FL'
            fullStateName = 'Florida';
        case 'GA'
            fullStateName = 'Georgia';
        case 'HI'
            fullStateName = 'Hawaii';
        case 'ID'
            fullStateName = 'Idaho';
        case 'IL'
            fullStateName = 'Illinois';
        case 'IN'
            fullStateName = 'Indiana';
        case 'IA'
            fullStateName = 'Iowa';
        case 'KS'
            fullStateName = 'Kansas';
        case 'KY'
            fullStateName = 'Kentucky';
        case 'LA'
            fullStateName = 'Louisiana';
        case 'ME'
            fullStateName = 'Maine';
        case 'MD'
            fullStateName = 'Maryland';
        case 'MA'
            fullStateName = 'Massachusetts';
        case 'MI'
            fullStateName = 'Michigan';
        case 'MN'
            fullStateName = 'Minnesota';
        case 'MS'
            fullStateName = 'Mississippi';
        case 'MO'
            fullStateName = 'Missouri';
        case 'MT'
            fullStateName = 'Montana';
        case 'NE'
            fullStateName = 'Nebraska';
        case 'NV'
            fullStateName = 'Nevada';
        case 'NH'
            fullStateName = 'New Hampshire';
        case 'NJ'
            fullStateName = 'New Jersey';
        case 'NM'
            fullStateName = 'New Mexico';
        case 'NY'
            fullStateName = 'New York';
        case 'NC'
            fullStateName = 'North Carolina';
        case 'ND'
            fullStateName = 'North Dakota';
        case 'OH'
            fullStateName = 'Ohio';
        case 'OK'
            fullStateName = 'Oklahoma';
        case 'OR'
            fullStateName = 'Oregon';
        case 'PA'
            fullStateName = 'Pennsylvania';
        case 'RI'
            fullStateName = 'Rhode Island';
        case 'SC'
            fullStateName = 'South Carolina';
        case 'SD'
            fullStateName = 'South Dakota';
        case 'TN'
            fullStateName = 'Tennessee';
        case 'TX'
            fullStateName = 'Texas';
        case 'UT'
            fullStateName = 'Utah';
        case 'VT'
            fullStateName = 'Vermont';
        case 'VA'
            fullStateName = 'Virginia';
        case 'WA'
            fullStateName = 'Washington';
        case 'WV'
            fullStateName = 'West Virginia';
        case 'WI'
            fullStateName = 'Wisconsin';
        case 'WY'
            fullStateName = 'Wyoming';
        case 'DC'
            fullStateName = 'District of Columbia';
        otherwise
            error('Unrecognized State Abbreviation %s',stateAbrev)
    end

end

