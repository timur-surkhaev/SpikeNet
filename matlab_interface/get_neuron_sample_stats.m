function R = get_neuron_sample_stats( R )
% autocorrelation is calculated instead of power spectral density
% note that Fourier transform of the autocorrelation function of a signal is the power spectrum of the signal

dt = R.dt;
disp('Getting neuron sample data statistics');
window_ms = 100; %ms
window = round( window_ms/(dt*10) );
lagNum = round( 10^4/(dt*10) );
            


for pop = 1:2
    n = length(R.neuron_sample.neuron_ind{pop});
    
    for i = 1:n
       
        E = R.neuron_sample.I_AMPA{pop}(i,:) + R.neuron_sample.I_ext{pop}(i,:); % I_ext is always excitatory
        I = R.neuron_sample.I_GABA{pop}(i,:); % negative values
        V = R.neuron_sample.V{pop}(i,:);

        E = E(1:10:end); % down-sampling
        I = I(1:10:end);
        V = V(1:10:end);

%         E_std_t = movingstd(E, window);
%         E_mean_t = movingmean(E, window);
%         I_std_t = movingstd(I, window);
%         I_mean_t = movingmean(I, window);
        tot_mean_t = movingmean(I + E, window);
        tot_std_t = movingstd(I + E, window);

        [xcf_EI,xlags] = crosscorr( E,I, lagNum ); % do NOT use xcorr!!
        [acf_E, lags] = autocorr(E, lagNum );
        [acf_I,~] = autocorr(I, lagNum );
        [acf_V,~] = autocorr(V, lagNum );
        
        [acf_tot_mean,~] = autocorr(tot_mean_t, lagNum );
        [acf_tot_std,~] = autocorr(tot_std_t, lagNum );
        [xcf_tot_mean_std,~] = crosscorr( tot_mean_t, tot_std_t, lagNum );
        
        
        
        if i == 1 && pop == 1
            XCF_EI = xcf_EI;
            ACF_E = acf_E;
            ACF_I = acf_I;
            ACF_V = acf_V;
            EI_ratio = mean(E)/mean(I);
            ACF_TOT_MEAN = acf_tot_mean;
            ACF_TOT_STD = acf_tot_std;
            XCF_TOT_MEAN_STD = xcf_tot_mean_std;
        else
            XCF_EI = [XCF_EI; xcf_EI];
            ACF_E = [ACF_E; acf_E];
            ACF_I = [ACF_I; acf_I];
            ACF_V = [ACF_V; acf_V];
            EI_ratio = [EI_ratio mean(E)/mean(I)];
            
            ACF_TOT_MEAN = [ACF_TOT_MEAN; acf_tot_mean];
            ACF_TOT_STD = [ACF_TOT_STD; acf_tot_std];
            XCF_TOT_MEAN_STD = [XCF_TOT_MEAN_STD; xcf_tot_mean_std];
            
        end
        
    end
end

R.neuron_sample_stats.xlag = xlags*(dt*10); % lags for cross correlation
R.neuron_sample_stats.lag = lags*(dt*10);
R.neuron_sample_stats.EI_xcf = XCF_EI;
R.neuron_sample_stats.E_acf = ACF_E;
R.neuron_sample_stats.I_acf = ACF_I;
R.neuron_sample_stats.V_acf = ACF_V;
R.neuron_sample_stats.EI_ratio = EI_ratio;

R.neuron_sample_stats.tot_std_acf = ACF_TOT_STD;
R.neuron_sample_stats.tot_mean_acf =  ACF_TOT_MEAN;
R.neuron_sample_stats.tot_mean_std_xcf = XCF_TOT_MEAN_STD;


end
