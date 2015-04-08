% get fig3

% nullclines
clc;clear;close all;

%%%%%%%%%%% table should be loaded as this
table = load('v_CV_tables.mat');
% manually fix some (possibly) numerical errors 
table.CV_mat(1:13,1) = 1;
table.CV_mat(end-2:end,1) = 0;
table.v_mat(end-2:end,1) = 0.5;
% something is still wrong here!!!

% transpose for interp2
table.miu_V_mat = table.miu_V_mat'; 
table.sigma_V_mat = table.sigma_V_mat'; 
table.CV_mat = table.CV_mat'; 
table.v_mat = table.v_mat';
%%%%%%%%%%% table should be loaded as above


%%%%%%%%%%% table should be loaded as this
table_aug = load('v_CV_tables_aug.mat');
% manually fix some (possibly) numerical errors 
x_up = table_aug.CV_mat;
x_up(isnan(x_up)) = 1;
x_up(isinf(x_up)) = 1;
table_aug.CV_mat(1:30,:) = x_up(1:30,:);

x_down = table_aug.CV_mat;
x_down(isnan(x_down)) = 0;
table_aug.CV_mat(31:60,:) = x_down(31:60,:);
table_aug.v_mat(isnan(table_aug.v_mat)) = 0.5;
% something is still wrong here!!!

% transpose for interp2
table_aug.miu_V_mat = table_aug.miu_V_mat'; 
table_aug.sigma_V_mat = table_aug.sigma_V_mat'; 
table_aug.CV_mat = table_aug.CV_mat'; 
table_aug.v_mat = table_aug.v_mat';
%%%%%%%%%%% table should be loaded as above



disp('Some numerical stuff must be serious wrong here!');

t_m = 10;
figure(1);
set(gcf,'color','w');

subplot(1,2,1);
hold on;
for c_mu = -16:2:16
    mu_ext = 15; %mV
    fh1 = @(mu_V, sigma_V) get_eq3_4_table_lookup(mu_V, sigma_V, table,  'v') - (mu_V-mu_ext)./(t_m*c_mu);
    h1 = ezplot(fh1,[10 ,30, 1, 4]);
    pause(0.5);
    
end

subplot(1,2,2);
hold on;
for c_sigma = 0:2:10
    sigma_ext = 2; %mV
    fh2 = @(mu_V, sigma_V) (sigma_V.^2-sigma_ext^2)/(t_m/2*c_sigma^2) - get_eq3_4_table_lookup(mu_V, sigma_V, table_aug,  'v*CV^2');
    h1 = ezplot(fh2,[10 ,40, 1, 10]);
    pause(0.5);
end


    
% 
%     mu_ext = 5; %mV
%     sigma_ext = 5; %mV
%     c_mu = 5; %mV
%     c_sigma = 20.2; %mV
%     
%     figure(1);
%     set(gcf,'color','w');
%     hold on;
%     fh1 = @(mu_V, sigma_V) get_eq3_4_table_lookup(mu_V, sigma_V, table,  'v') - (mu_V-mu_ext)./(t_m*c_mu);
%     fh2 = @(mu_V, sigma_V) (sigma_V.^2-sigma_ext^2)/(t_m/2*c_sigma^2) - get_eq3_4_table_lookup(mu_V, sigma_V, table,  'v').*get_eq3_4_table_lookup(mu_V, sigma_V, table,  'CV')^2;
%     % ezplot may take several minutes 
%     h1 = ezplot(fh1,[2 ,15, 2, 25]);
%     h2 = ezplot(fh2,[2 ,15, 2, 25]);

