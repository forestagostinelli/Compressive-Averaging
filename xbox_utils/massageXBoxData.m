% Massage XBOX data
clear
%% Load demographic data
fid = fopen('../survey-data-bcs-data-store/XboxPollDemo/XboxPollDemo.csv');
xboxDemographics = textscan(fid, '%s %s %s %s %s %s %s %s %s %s %s', 'Delimiter',',', 'HeaderLines',1, ... 
    'MultipleDelimsAsOne',true, 'CollectOutput',false);
fclose(fid);

%% Make userID int
fprintf('Massaging Demographics Data\n')
userIDDemo = xboxDemographics{2};
xboxDemographics{2} = cellfun(@str2num,userIDDemo); 

%% Load survey responses
fid = fopen('../survey-data-bcs-data-store/XboxPoll/XboxPoll.csv');
xboxData = textscan(fid, '%s %s %s %s %s %s', 'Delimiter',',', 'HeaderLines',1, ... 
    'MultipleDelimsAsOne',true, 'CollectOutput',false);
fclose(fid);

%% Make userID int
fprintf('Massaging Response Data\n')
userID = xboxData{2};
xboxData{2} = cellfun(@str2num,userID);

%% Massage Date
fprintf('Converting date to datenum\n')
xboxData{4} = datetime(xboxData{4}(:));
fprintf('\n');

%% Save Data
fprintf('Saving Data\n')
save('../survey-data-bcs-data-store/XboxPollDemo/XboxPollDemoMassage.mat','xboxDemographics');
save('../survey-data-bcs-data-store/XboxPoll/XboxPollMassage.mat','xboxData');