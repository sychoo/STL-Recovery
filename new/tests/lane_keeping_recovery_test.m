% this aims to be a minimal example that demonstrates vehicle recovery 
% using a lane while optimizing for the cumulative 

clear;
yalmip('clear');
config_lk;

% start with the plot, and go backwards focus on first subgraph


%%%%%%%%%% INITIAL CONDITION %%%%%%%%%%%
% position, velocity, angle and angle velocity
x_0 = [5, 10, 0, 2]';
% x_0 = [5, 6, 0, 2]';
%%%%%%%%%% /INITIAL CONDITION %%%%%%%%%%%


%%%%%%%%%% STATE SPACE MODEL %%%%%%%%%%%
A = [0, 1, 0, 0;
     0, a_c1, 0, a_c2;
     0, 0, 0, 1;
     0, a_c3, 0, a_c4];
B = [0; 2*C_alphaF/m; 0; 2*l_F*C_alphaF/I_z];

% note that x_t_next = A * x_t + B * u_t

%%%%%%%%%% /STATE SPACE MODEL %%%%%%%%%%%


%%%%%%%%%% CONSTANTS %%%%%%%%%%%%
deltaT = 0.1; % definition of 1 time step

H = 61;  % H * 0.1 secs horizon

alpha_value = 18;
beta_value = 25;
% alpha_value = 15;
% beta_value = 15;

u_max = 0.72; % physical limit of the turning angle
du_max = 0.72; % change rate of the input (angle)

yl = -1; % lower bound of difference between the vehicle and center line of the lane
yu = 1; % upper bound of difference between the vehicle and center line of the lane

track_lambda = 30;
%%%%%%%%%% /CONSTANTS %%%%%%%%%%%%



% a curve track
delta_x = v * deltaT;
[y_upperbounds, y_lowerbounds] = sine_curvature(yl, yu, H, track_lambda, delta_x);


% color = []
xpos = -1.9;
figure;
set(gca,'position',[0.5 0.19 0.80 0.78],'box','on','linewidth',0.8);
t = tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
nexttile
% subplot(3,1,1); 
hold on

% lateral position
% plot the 3 different policies
% only plot the lateral positions
states_tmp = [1,2,3,4,5,6,7]; %optimal_states{1};
plot(states_tmp(1,:),'-','LineWidth',1.5);
states_tmp = [1,1,1,2,3,3,4,4,4,5,5,5]; %optimal_states{2};
plot(states_tmp(1,:),'--','LineWidth',1.5);
% states_tmp = optimal_states{3};
% plot(states_tmp(1,:),'-.','LineWidth',1.5);

set(gca,'ColorOrderIndex',1)
fh = fill_between_y(1:H,y_lowerbounds,y_upperbounds,'no');
fh.FaceColor = "#B2B2B2";
text(1.5,-2,'Lane')
scatter(1,x_0(1),100,"pentagram",'filled');
legend({'trajectory 1','trajectory 2','trajectory 3'},'NumColumns',3,'Location','northoutside','FontSize',12)
yl=ylabel('y-coordinate (m)','FontSize',13);
pos=get(yl,'Pos');set(yl,'Pos',[xpos pos(2) pos(3)])
xlabel('x-coordinate (m)','FontSize',14);
ylim([-7.5,9]);xlim([1,H-1]);xticks([1:5:H-1,60]);xticklabels([0:5:H-1,60]);
title('Locations','FontSize',10);
set(gca,'box','on','linewidth',1)