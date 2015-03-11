function simulate_single_neuron( R, pop, sample_ind, seg_input )
% this function completely emulates the single neuron behavior in the C++
% simulator


% dump parameters
dt =  R.dt;
step_tot = R.step_tot;
dt_reduced =  R.reduced.dt;
step_tot_reduced = R.reduced.step_tot;

V = R.neuron_sample.V{pop}(sample_ind,:);
% I_leak = R.neuron_sample.I_leak{pop}(sample_ind,:);
I_AMPA = R.neuron_sample.I_AMPA{pop}(sample_ind,:);
I_GABA = R.neuron_sample.I_GABA{pop}(sample_ind,:);
I_ext = R.neuron_sample.I_ext{pop}(sample_ind,:);
neuron_ind = R.neuron_sample.neuron_ind{pop}(sample_ind);

spikes = find( R.spike_hist{pop}(neuron_ind,:) );


Cm = R.PopPara{pop}.Cm;
tau_ref = R.PopPara{pop}.tau_ref;
V_rt = R.PopPara{pop}.V_rt;
V_lk = R.PopPara{pop}.V_lk;
g_leak = R.PopPara{pop}.g_lk;
V_th = R.PopPara{pop}.V_th;

% find threshold current for neuron to fire
I_th = g_leak*(V_th - V_lk) % important!!!!!!!!!!!!!
I_E_mean = mean(I_AMPA + I_ext)
I_I_std = std(I_AMPA + I_ext)
I_I_mean = mean(I_GABA)
I_E_std = std(I_GABA)
I_tot_mean = mean(I_AMPA + I_ext + I_GABA)
I_tot_std = std(I_AMPA + I_ext + I_GABA)
EI_ratio = mean(I_AMPA + I_ext)/mean(I_GABA)


% simulate the stuff again in matlab (xx_new)
% reproduce the behavior of the C++ code

spikes_new = [];
V_new = zeros(1,step_tot);
V_new(1) = V(1);

tau_steps = round(tau_ref/dt);
ref_tmp = 0;

for t = 1:(step_tot-1)
    % update_spikes
    if ref_tmp == 0 && V_new(t) >= V_th
        ref_tmp = tau_steps;
        spikes_new = [spikes_new t];
    end
    if ref_tmp > 0
        ref_tmp = ref_tmp - 1;
        V_new(t) = V_rt;
    end
    % update_V
    if ref_tmp == 0
        I_leak = -g_leak*(V_new(t) - V_lk);
        
        %I_GABA(t) = 0;
        %I_AMPA(t) = 0;
        %I_ext(t) = 0;
        
        V_dot =  (I_leak + I_AMPA(t) + I_GABA(t) + I_ext(t))/Cm;
        
        %V_dot = (I_leak + I_th)/Cm;
        
        V_new(t+1) = V_new(t) + V_dot*dt;
    end
end

spikes = spikes(:)';
spikes_new = spikes_new(:)';
if nnz(sort(spikes_new) - sort(spikes)) > 0
    warning('Simulator does not behave identically as c++ code!');
end

% Segmetation
seg_size = 4*10^5; % 40 sec
seg_size_reduced = round(seg_size*dt/dt_reduced); % be careful!!!

if nargin < 4
    seg_input = 1:ceil(step_tot/seg_size);
end

for seg = seg_input
    seg_ind = get_seg(step_tot, seg_size, seg);
    seg_ind_reduced = get_seg(step_tot_reduced, seg_size_reduced, seg);
    
    % figure('numbertitle','off','name','check_simulation_correctness','color','w');
    % V_step = 1;
    %
    % ax1 = subplot(3,1,1);
    % line([spikes; spikes], [zeros(size(spikes)); ones(size(spikes))]);
    % xlim([min(seg_ind) max(seg_ind)]);
    %
    % ax2 = subplot(3,1,2);
    % line([spikes_new ; spikes_new ], [zeros(size(spikes_new)); ones(size(spikes_new))]);
    %
    % x = seg_ind;
    % V_seg = V(seg_ind);
    % V_new_seg = V_new(seg_ind);
    %
    % ax3 = subplot(3,1,3);
    % hold on;
    % plot(x(1:V_step:end), V_seg(1:V_step:end), 'b', x(1:V_step:end), V_new_seg(1:V_step:end), 'r')
    % ymin = min(min(V_seg), min(V_new_seg));
    % ymax = max(max(V_seg), max(V_new_seg));
    % yrange = ymax - ymin;
    % ylim([ymin-0.2*yrange,  ymax+0.2*yrange]);
    %
    % linkaxes([ax1, ax2, ax3],'x');
    
    
    h_ccs = figure('numbertitle','off','name','check_current_stats','color','w', 'position', [680   498   562   600]);
    window_ms = 100; %ms
    window = round(window_ms/dt);
    x = seg_ind*dt*10^-3;
    
    I_E = I_AMPA+I_ext;
    I_I = I_GABA;
    
    I_E = I_E(seg_ind);
    I_I = I_I(seg_ind);
    
    I_E_std = movingstd(I_E, window);
    I_E_mean = movingmean(I_E, window);
    
    I_I_std = movingstd(I_I, window);
    I_I_mean = movingmean(I_I, window);
    
    I_tot_std = movingstd(I_E+I_I, window);
    
    
    %%%%%%%%%%%%%
    ax(1) = subplot(5,1,1);
    hold on;
    shadedErrorBar(x, I_E_mean, I_E_std, 'r');
    shadedErrorBar(x, I_I_mean, I_I_std, 'b');
    shadedErrorBar(x, I_E_mean+I_I_mean, I_tot_std, 'k');
    plot(x, I_th*ones(size(x)), 'k--');
    ylabel('E/I current mean (std)')
    xlim([min(x) max(x)]);
   
    %%%%%%%%%%%%%
    ax(2) = subplot(5,1,2);
    line([spikes; spikes]*dt*10^-3, [zeros(size(spikes)); ones(size(spikes))]);
    
    num_spikes = nnz(spikes>=min(seg_ind) & spikes<=max(seg_ind));
    ylabel('spikes')
    xlim([min(x) max(x)]);
    
    %%%%%%%%%%%%%
    ax(3) = subplot(5,1,3);
    hold on;
    V_step = 10;
    V_seg = V(seg_ind);

    plot(x(1:V_step:end), V_seg(1:V_step:end))
    ymin = min(V_seg);
    ymax = max(V_seg);
    yrange = ymax - ymin;
    ylim([ymin-0.2*yrange,  ymax+0.2*yrange]);

    ylabel('membrane potential')
    xlim([min(x) max(x)]);
    
    %%%%%%%%%%%%%
    % moving autocorrelation of V/I
    ax(4) = subplot(5,1,4);
    window_length =  0.5*10^4; % 0.5 sec
    lagNum = 0.1*10^4; % up to 100ms
    sliceNum = 10^3; % the more the better
    [mid_points, lags, acc_mat] = moving_autocorr(I_E, window_length, lagNum, sliceNum);
    imagesc( x(mid_points), lags*dt*10^-3, acc_mat);
    
    xlim([min(x) max(x)]);

    
    %% individual neuron rate
     ax(5) = subplot(5,1,5);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     pop_ind = 1;
    %     sigma_gaussian = 50; % ms, which is width???
    %
    %     % Dump fields
    %     N = R.N;
    %
    %     sample_size = 2000; % sample neurons
    %     % down-sampling
    %     if N(pop_ind) >= sample_size
    %         ind_sample = ceil(linspace(1,N(pop_ind),sample_size));
    %     else
    %         ind_sample = 1:1:N(pop_ind);
    %     end
    %
    %     % Dump fields
    %     spike_hist = R.reduced.spike_hist{pop_ind}( ind_sample,  seg_ind_reduced);
    %
    %     % Gaussian filter
    %     kernel = spike_train_kernel_YG(sigma_gaussian, dt_reduced, 'gaussian'); % be careful about the dt here! it's in ms
    %
    %     neuron_rate = zeros(size(spike_hist));
    %     disp('This may take a while...');
    %     for i = 1:length(ind_sample)
    %         neuron_rate(i,:) = SpikeTrainConvolve(spike_hist(i,:), kernel);
    %     end
    %
    %     % imagesc( seg_ind(1:10:end)*dt, 1:length(ind_sample), neuron_rate(:, 1:10:end) );
    %     imagesc( seg_ind_reduced(1:10:end)*dt_reduced*10^-3, 1:length(ind_sample), neuron_rate(:, 1:10:end) );
    
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Dump fields
%     Rate = R.cluster.rate(:,seg_ind_reduced);
%     Rate = Rate(:,1:10:end); % reduce resolution
%     cluster_membership = R.cluster.label(neuron_ind);
%     Mnum = R.ExplVar.Mnum;
%     imagesc(seg_ind_reduced(1:10:end)*dt_reduced*10^-3, 1:Mnum, Rate);
%     xlim([min(x) max(x)]);

    this_cluster = R.cluster.label(neuron_ind);
    num_spikes_cluster = full(sum( R.reduced.spike_hist{pop}(R.cluster.label == this_cluster, seg_ind_reduced), 1));
    % Plot number of refractory neurons
    x_reduced = seg_ind_reduced*dt_reduced*10^-3;
    line([x_reduced; x_reduced], [zeros(1, length(x_reduced)); num_spikes_cluster], 'color','b');
    
    xlim([min(x) max(x)]);
    
    xlabel(sprintf('t (sec), neuron from cluster %d', this_cluster));
    
    linkaxes(ax,'x');

    
    
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% why does it convery so little
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% information?
%     figure(2);
%     spectrogram(I_E,window_length,round(window_length/2));
    
    
    next = input('next?');
    close all;
end



end