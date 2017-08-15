function writeBasicParaHDF5(FID, dt, step_tot, N, modify)
% write basic parameters
%      FID: file id for writing data
%       dt: time step size in ms
% step_tot: total number of simulation steps
%        N: vector for number of neurons in each population


if nargin == 4
    modify = 0;
end

if modify == 0
    hdf5write(FID,'/config/Net/INIT001/N', N, 'WriteMode', 'append');
    hdf5write(FID,'/config/Net/INIT002/dt',dt, 'WriteMode', 'append');
    hdf5write(FID,'/config/Net/INIT002/step_tot', step_tot, 'WriteMode', 'append');
elseif modify == 1
    hdf5write(FID,'/config/Net/INIT001/N', N); % overwrite /config/Net/INIT001
    hdf5write(FID,'/config/Net/INIT002/dt',dt); % overwrite /config/Net/INIT002
    hdf5write(FID,'/config/Net/INIT002/step_tot', step_tot, 'WriteMode', 'append');
end

% h5create(FID,'/config/Net/INIT001/N', size(N));
% h5write(FID,'/config/Net/INIT001/N', N);
% h5create(FID,'/config/Net/INIT002/dt',1);
% h5write(FID,'/config/Net/INIT002/dt',dt);
% h5create(FID,'/config/Net/INIT002/step_tot', 1 );
% h5write(FID,'/config/Net/INIT002/step_tot', step_tot);


end

