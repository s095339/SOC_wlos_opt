#include "fir.h"
#include <stdint.h> 



void __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	//fir accelerater================================
	
	//step 1 send parameter to accelerater (taps)
	for(int i=0;i<N;i++){
        send_wb(WB_FIR_TAP_START + i*4, taps[i]);
    }
	//step 2 allocate input and output buffer
	for(int i=0;i<NI;i++){
        inputsignal[i] = i;
    }
	start_dma((uint32_t) INDATA_ADR, NI,OUTDATA_ADR);
	//step 3 start the fir accelerater


	//===============================================

	//return outputsignal;
}
		


int __attribute__ ( ( section ( ".mprjram" ) ) ) main_func(){
	
	fir();

	

	return 0;
}