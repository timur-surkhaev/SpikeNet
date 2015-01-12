function raster_plot(R, pop_ind, seg, sample_color, varargin)

% Input check and default values
if nargin < 3
    seg = 1;
end

sample_size = 500; % sample neurons for raster plot
seg_size = 4*10^4; % 2*10^4 for 2-pop, segmentation size for each plot



text_fontsize = 12;
for i = 1:(length(varargin)/2)
    eval([varargin{i*2-1}, '=', num2str(varargin{i*2}), ';' ]);
end



% Dump fields
dt = R.reduced.dt;
step_tot = R.reduced.step_tot;
N = R.N;
% rate_sorted = R.Analysis.rate_sorted;

% 
dt = dt/1000;

% Segmetation
seg_ind = get_seg(step_tot, seg_size, seg);

% Dump fields
num_spikes = R.reduced.num_spikes{pop_ind}(seg_ind);
spike_hist = R.reduced.spike_hist{pop_ind}(:,seg_ind);
T = seg_ind*dt;

% Plot raster plot
if nnz(num_spikes) > 0
    % down-sampling
    if N(pop_ind) >= sample_size
        ind_sample = ceil(linspace(1,N(pop_ind),sample_size));
    else
        ind_sample = 1:1:N(pop_ind);
    end
    
    if isempty(sample_color)
        [Y,X,~] = find(spike_hist(ind_sample,:));
        xdata = ( [X(:)'; X(:)']+seg_ind(1)-1 )*dt; % sec
        ydata = [Y(:)'-1;Y(:)'];
        line(xdata, ydata,'Color','k');
    else
        hold on;
        sample_color = (sample_color-min(sample_color))/(diff(minmax(sample_color)));
        sample_color(sample_color == 0) = eps;
        jetmap = colormap('jet(1000)');
        
        for i = 1:length(ind_sample)
            color_tmp = jetmap( ceil(sample_color(i)*1000),:);
            [Y,X,~] = find(spike_hist(ind_sample(i),:));
            xdata = ( [X(:)'; X(:)']+seg_ind(1)-1 )*dt; % sec
            ydata = [Y(:)'-1;Y(:)']+i-1;
            line(xdata, ydata, 'Color', color_tmp);
        end
        colormap('jet');
    end
    
    
    ylim([0,length(ind_sample)]);
    ylabel('Neurons','fontsize',text_fontsize)
%     if pop_ind == 1
%         if rate_sorted == 1
%             ylabel('Rate-sorted sample neuron index');
%         else
%             ylabel('Sample neuron index');
%         end
%     end
    
    xlim([T(1)-dt, T(1)+(length(seg_ind)-1)*dt]); % make sure all the plots have the same axis scale
    
    % Keep tick lables while remove tick marks
    % set(gca, 'xtick', [], 'Ticklength', [0 0], 'TickDir','out');
    set(gca,'ytick',[],'ydir','reverse');
    % set(gca,'xtick',[]);
    box on;

    
        
end

end

