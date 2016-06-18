clear
fid = fopen('../survey-data-bcs-data-store/XboxPollDemo/exit_poll_2012.csv');
exit_poll_w_header = textscan(fid, '%s %s %s %s %s %s %s %s %s %s %s', 'Delimiter',',', ... 
    'MultipleDelimsAsOne',true, 'CollectOutput',false);

header = cell(length(exit_poll_w_header),1);
exit_poll = cell(length(exit_poll_w_header{1})-1,length(exit_poll_w_header));

for h=1:length(header)
    header{h} = exit_poll_w_header{h}{1};
    exit_poll(:,h) = exit_poll_w_header{h}(2:end);
end

%% Change independent to other
partyPos = ismember(lower(header),lower('PARTY'));
changeIdxs = strcmpi(exit_poll(:,partyPos),'Independent/Something else');
exit_poll(changeIdxs,partyPos) = {'other'};

%% Change age range
agePos = ismember(lower(header),lower('AGE'));
changeIdxs = strcmpi(exit_poll(:,agePos),'45-65');
exit_poll(changeIdxs,agePos) = {'45-64'};

%% Change education
eduPos = ismember(lower(header),lower('EDUCATION'));
changeIdxs = strcmpi(exit_poll(:,eduPos),'Some college/assoc. degree');
exit_poll(changeIdxs,eduPos) = {'some college'};
changeIdxs = strcmpi(exit_poll(:,eduPos),'No high school diploma');
exit_poll(changeIdxs,eduPos) = {'didn''t graduate from HS'};
changeIdxs = strcmpi(exit_poll(:,eduPos),'Postgraduate study');
exit_poll(changeIdxs,eduPos) = {'College graduate'};

%% change race
racePos = ismember(lower(header),lower('RACE'));
changeIdxs = strcmpi(exit_poll(:,racePos),'Hispanic/Latino');
exit_poll(changeIdxs,racePos) = {'Hispanic'};
changeIdxs = strcmpi(exit_poll(:,racePos),'Asian');
exit_poll(changeIdxs,racePos) = {'Other'};

%% Make weights double and get rid of NAs
nRows = size(exit_poll,1);
weightCol = strcmpi(header,'weight');
goodRowIdxs = zeros(nRows,1);
for r=1:nRows
    if (~ismember('NA',exit_poll(r,:)))
        goodRowIdxs(r) = 1;
    end
    exit_poll{r,weightCol} = str2double(exit_poll{r,weightCol});
end
goodRowIdxs = logical(goodRowIdxs);
exit_poll = exit_poll(goodRowIdxs,:);

%% Make two party
presCol = strcmpi(header,'vote');
exit_poll(:,presCol) = lower(exit_poll(:,presCol));
obamaIdxs = strcmpi(exit_poll(:,presCol),'barack obama');
mittIdxs = strcmpi(exit_poll(:,presCol),'mitt romney');
twoPartyIdxs = obamaIdxs | mittIdxs;
exit_poll = exit_poll(twoPartyIdxs,:);

obamaIdxs = strcmpi(exit_poll(:,presCol),'barack obama');
mittIdxs = strcmpi(exit_poll(:,presCol),'mitt romney');

exit_poll(obamaIdxs,presCol) = {2};
exit_poll(mittIdxs,presCol) = {1};

%% Change state to abberviation
stateCol = strcmpi(header,'state');
stateAbbrevs = {'AL','AK','AZ','AR','CA','CO','CT','DC','DE','FL','GA','HI','ID','IL','IN',...
        'IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',...
        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA'...
        'WA','WV','WI','WY'};
for s=1:length(stateAbbrevs)
    fullName = StateLookup(stateAbbrevs{s});
    stateIdxs = strcmpi(exit_poll(:,stateCol),fullName);
    assert(max(stateIdxs) == 1,'No state matching name %s',fullName);
    
    exit_poll(stateIdxs,stateCol) = stateAbbrevs(s);
end

%% Switch party and ideology columns
%{
partyPos = ismember(lower(header),lower('PARTY'));
ideologyPos = ismember(lower(header),lower('IDEOLOGY'));

partyRepubIdxs = strcmpi(exit_poll(:,partyPos),'Republican');
partyOtherIdxs = strcmpi(exit_poll(:,partyPos),'Other');
partyDemoIdxs = strcmpi(exit_poll(:,partyPos),'Democrat');

ideaoConservativeIdxs = strcmpi(exit_poll(:,ideologyPos),'Conservative');
ideaoModerateIdxs = strcmpi(exit_poll(:,ideologyPos),'Moderate');
ideaoLiberalIdxs = strcmpi(exit_poll(:,ideologyPos),'Liberal');

exit_poll(partyRepubIdxs,ideologyPos) = {'Conservative'};
exit_poll(partyOtherIdxs,ideologyPos) = {'Moderate'};
exit_poll(partyDemoIdxs,ideologyPos) = {'Liberal'};

exit_poll(ideaoConservativeIdxs,partyPos) = {'Republican'};
exit_poll(ideaoModerateIdxs,partyPos) = {'Other'};
exit_poll(ideaoLiberalIdxs,partyPos) = {'Democrat'};
%}

save('../survey-data-bcs-data-store/XboxPollDemo/exit_poll_2012.mat','exit_poll','header');