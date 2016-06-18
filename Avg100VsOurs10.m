%avg100 = [5.0 3.8 2.9 1.8 6.8 5.6 2.4 2.1];
%avg10  =[10.2 7.0 3.8 3.2 11.1 7.2 3.8 3.2];
%ours100 = [3.9 2.9 2.7 2.4 6.0 4.8 3.0 2.9];
%ours10 =  [4.7 3.9 2.9 2.6 5.5 4.3 2.9 2.5];

avg100 = [5.0 3.8 6.8 5.6];
ours10 =  [4.7 3.9 5.5 4.3];


maxAxis = max(max(avg100),max(ours10));

x = 0:0.01:maxAxis;
y = 0:0.01:maxAxis;

figure;
h = plot(x,y,'k--'); hold on;
set(h, 'LineWidth', 4);
%h = plot(x,y+1,'r--');
%set(h, 'LineWidth', 4);


scatter(avg100,ours10,500,'filled');
%scatter(avg100Mean,ours10Mean,80,'filled');
%scatter(avg100Median,ours10Median,80,'filled');


xlabel('Average Method at 100%');
ylabel('Best of Our Methods at 10%');

set(gca,'FontSize',25,'fontWeight','bold');

xlim([0 maxAxis]);
ylim([0 maxAxis]);
title('Average Method vs Our Methods')