#include "fir.h"
#include <stdint.h> 


extern int* matmul();
extern int* qsort();
int intr_dma = 0;
void __attribute__ ((section("mprjram")))isr_dma(){
	intr_dma = 1;
	send_wb(0x2600000c, 0xABCD0000);
}

void __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	//fir accelerater================================
	
	//step 1 send parameter to accelerater (taps)
	// 送tap到AXILITE
	for(int i=0;i<N;i++){
        send_wb(WB_FIR_TAP_START + i*4, taps[i]);
    }
	//step 2 allocate input and output buffer
	//把INPUT存到SDRAM
	for(int i=0;i<NI;i++){
        inputsignal[i] = i;
    }

	//啟動dma
	start_dma((uint32_t) INDATA_ADR, NI,OUTDATA_ADR);

	//step 3 start the fir accelerater
	enum BLKLVL blklvl;
	while( read_wb(WB_FIR_BLK_LVL) & (1<<ap_idle ) != 1<<ap_idle);
	send_wb(WB_FIR_BLK_LVL,  (1 << ap_start) );



	while( read_wb(WB_FIR_BLK_LVL) & (1<<ap_idle ) != 1<<ap_idle);
	//int ii=0;
	//do{
	//	send_wb(0x2600000c, outputsignal[ii++]<<16);
	//}while(ii<NI);
	//return outputsignal;
}
		


int __attribute__ ( ( section ( ".mprjram" ) ) ) main_func(){
	
	fir();
	//qsort();
	//matmul();
	while(1){

		if(intr_dma)break;
			//intr_dma = 0;
			//int ii=0;
			//do{
			//	send_wb(0x2600000c, outputsignal[ii++]<<16);
			//}while(ii<NI);
			

	}
	for(int i=0;i<NI;i++){
		send_wb(0x2600000c, outputsignal[i]<<16);
	}
	return 0;
}