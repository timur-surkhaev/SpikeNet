function R = cluster_sorted_rate( R )
    % get cluster rate
    R = get_cluster_rate( R );
    C_rate = R.cluster.rate;
        
    % sort the rate and each time point
    [sorted_rate, cluster_sequence] = sort(C_rate, 'descend');
    
    % cluster rank
    [a_ind, b_ind] = size(cluster_sequence);
    cluster_rank = zeros(a_ind,b_ind);
    for i = 1:b_ind
        cluster_rank(cluster_sequence(:,i),i) = (1:a_ind)';
    end

    % threshold the 1st symbolic sequence based on 1st sorted rate
    theta = 5:1:15; % Hz, threshold
    lt = length(theta);
    seq_1st = repmat(cluster_sequence(1,:), lt, 1); 
    for i = 1:lt
        seq_1st(i, sorted_rate(1,:) < theta(i)  ) = 0; % or NaN?
    end
    
    
    % statistical analysis on the thresholded 1st symbolic sequence
    switch_seq = cell(1,lt);
    high_du = cell(1,lt);
    low_du = cell(1,lt);
    for i = 1:lt
        [seq_tmp, high_du_tmp, low_du_tmp] = seq_postprocess( seq_1st(i,:) );
        switch_seq{i} = seq_tmp;
        high_du{i} = high_du_tmp;
        low_du{i} = low_du_tmp;
    end
    
    % output results
    R.cluster.threshold = theta;
    R.cluster.switch_seq = switch_seq;
    R.cluster.high_du = high_du;
    R.cluster.low_du = low_du;
    R.cluster.sorted_rate = sorted_rate;
    R.cluster.sym_seq = cluster_sequence;
    R.cluster.rate_rank = cluster_rank;
    
end



function [switch_seq, high_du, low_du] = seq_postprocess(seq)
% symbolic sequence postprocesing
% start from simple solutions!

% cut head and tail
head = seq(1);
h = 0;
for i = 1:length(seq)
    if seq(i) == head
        h = i;
    else
        break;
    end
end
seq(1:h) = [];

tail = seq(end);
t = 0;
for i = length(seq):-1:1
    if seq(i) == tail
        t = i;
    else
        break;
    end
end
seq(t:end) = [];

% contract sequence and find durations
switch_seq = seq(1);
du = 1;
for i = 2:length(seq)
    if seq(i) == seq(i-1)
        du(end) = du(end)+1;
    else
        du = [du 1]; % new duration counter
        switch_seq = [switch_seq seq(i)]; % new entry in switch sequence
    end
end

% differentiate high and low states
high_du = du(switch_seq > 0);
low_du = du(switch_seq == 0);
switch_seq(switch_seq == 0) = []; % only high states

end
