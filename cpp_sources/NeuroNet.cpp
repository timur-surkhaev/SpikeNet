#include "NeuroNet.h"
//#include <iostream>
//#include <random>
//#include <vector>
#include <iterator>     // std::back_inserter
#include <algorithm>    // std::for_each, copy
#include <numeric>      // std::accumulate
#include <string.h>     // for memcpy
#include <ctime>

using namespace std;

NeuroNet::NeuroNet(vector<int> N_array_input, double dt_input, int step_tot_input, char delim_input, char indicator_input){

	N_array = N_array_input;
	dt = dt_input;
	step_tot = step_tot_input;
	delim = delim_input;
	indicator = indicator_input;
	Num_pop = N_array.size();
	runaway_killed = false;
	step_killed = -1;
	
	
};


void NeuroNet::update(int step_current){

	if (runaway_killed == false){ // if not runaway_killed
		/*------------------------------------------------------------------------------------------------------*/
	
		// Update neuron states
		// Pre-coupling update
	
		for (int pop_ind = 0; pop_ind < Num_pop; ++pop_ind){
			// Update spikes and nonref
			NeuroPopArray[pop_ind]->update_spikes(step_current); // this must always be the first operation!!!
			// Update action potential for electrical coupling
			// ElectricalSynapsesArray[i_pre][i_pre].update_action_potential(NeuroPopArray[i_pre], step_current);

			// check runaway activity
			runaway_killed |= NeuroPopArray[pop_ind]->get_runaway_killed(); // Bitwise OR assignment, a |= b meaning  a = a | b
			if (runaway_killed == true){
				step_killed = step_current;
			}
		}

		/*------------------------------------------------------------------------------------------------------*/
		// Chemical Coupling
		for (unsigned int syn_ind = 0; syn_ind < ChemSynArray.size(); ++syn_ind){
				ChemSynArray[syn_ind]->recv_pop_data(NeuroPopArray);
				// recv_data should be more optimized if using MPI!
				ChemSynArray[syn_ind]->update(step_current);
				ChemSynArray[syn_ind]->send_pop_data(NeuroPopArray);
		}
		
		// Electrical coupling
		

		/*------------------------------------------------------------------------------------------------------*/
		// Update membrane potential
		// Post-coupling update
		for (int pop_ind = 0; pop_ind < Num_pop; ++pop_ind){
			// Update membrane potential
			NeuroPopArray[pop_ind]->update_V(step_current); 
		}

	} // if not runaway_killed

}



void NeuroNet::output_results(ofstream& output_file){

	// write data
	// cout << "Outputting results into text file..." << endl;
	
	// KILL002 # step at which runaway activity is killed
	output_file << indicator << " KILL002" << endl;
	output_file << step_killed << delim << endl;

	// dump population data
	for (int i = 0; i < Num_pop; i++){
		NeuroPopArray[i]->output_results(output_file);
	}

	// dump synapse data
	for (unsigned int i = 0; i < ChemSynArray.size(); i++){
		ChemSynArray[i]->output_results(output_file);
	}
	
}

#ifdef HDF5
void NeuroNet::import_restart(H5File & file,string out_filename){

	Num_pop=read_scalar_HDF5<int>(file,string("/Net/Num_pop"));
	for (unsigned int ind = 0; ind < N_array.size(); ++ind){
		NeuroPopArray.push_back(new NeuroPop(ind, N_array[ind], dt, step_tot, delim, indicator));
		cout << "\t Initialising neuron pop " << ind+1 << "..." << endl;

		NeuroPopArray[ind]->import_restart(file,ind,out_filename);
	}
	string syn_str = "/syns/";
	int n_syns=read_scalar_HDF5<int>(file,syn_str+"n_syns");
	for (int ind = 0; ind < n_syns; ++ind){

		ChemSynArray.push_back(new ChemSyn(dt, step_tot, delim, indicator));
		// network.ChemSynArray.back()->init(type, i_pre, j_post, N_array[i_pre], N_array[j_post], I, J, K, D);

		ChemSynArray[ind]->import_restart(file,ind);
	}

}

void NeuroNet::export_restart(H5File & file){

	Group group_Net = file.createGroup(string("/Net"));
	write_vector_HDF5(group_Net,N_array,string("N_array"));
	write_scalar_HDF5(group_Net,step_tot,string("step_tot")); 
	write_scalar_HDF5(group_Net,dt,string("dt")); 
	write_scalar_HDF5(group_Net,Num_pop,string("Num_pop")); 
		
	string pops_str = "/pops/";
	Group group_pops = file.createGroup(pops_str);
	for (int ind = 0; ind < Num_pop; ++ind){
		NeuroPopArray[ind]->export_restart(group_pops);
	}
	string syn_str = "/syns/";
	Group group_syns = file.createGroup(syn_str);
	int n_syns=static_cast<int>(ChemSynArray.size());
	write_scalar_HDF5(group_syns,n_syns,"n_syns");
	for (int ind = 0; ind < n_syns; ++ind){
		ChemSynArray[ind]->export_restart(group_syns,ind);
	}

}

void NeuroNet::output_results(H5File & file_HDF5){

	// KILL002 # step at which runaway activity is killed
	Group group_tmp = file_HDF5.createGroup(string("/run_away_killed"));
	vector<int> v_tmp; v_tmp.push_back(step_killed);
	write_vector_HDF5(group_tmp, v_tmp, string("step"));
		
	// dump population data
	for (int i = 0; i < Num_pop; i++){
		NeuroPopArray[i]->output_results(file_HDF5);
	}

	// dump synapse data
	for (unsigned int i = 0; i < ChemSynArray.size(); i++){
		ChemSynArray[i]->output_results(file_HDF5, i);
	}
	
}

#endif

