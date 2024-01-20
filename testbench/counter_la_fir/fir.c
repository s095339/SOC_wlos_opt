#include "fir.h"
#include <stdint.h> 



int intr_dma = 0;
//==================
//qsort===================================================


int __attribute__ ( ( section ( ".mprjram" ) ) ) partition(int low,int hi){
	int pivot = A[hi];
	int i = low-1,j;
	int temp;
	for(j = low;j<hi;j++){
		if(A[j] < pivot){
			i = i+1;
			temp = A[i];
			A[i] = A[j];
			A[j] = temp;
		}
	}
	if(A[hi] < A[i+1]){
		temp = A[i+1];
		A[i+1] = A[hi];
		A[hi] = temp;
	}
	return i+1;
}

void __attribute__ ( ( section ( ".mprjram" ) ) ) sort(int low, int hi){
	if(low < hi){
		int p = partition(low, hi);
		sort(low,p-1);
		sort(p+1,hi);
	}
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) qsort(){
	sort(0,SIZES-1);
	return A;
}

//matmul===================================================

void __attribute__ ( ( section ( ".mprjram" ) ) ) matmul()
{
	int i=0;
	int j;
	int k;
	int sum;
	int kk;
	unsigned int count = 0;
	for (i=0; i<SIZE; i++){
		for (j=0; j<SIZE; j++){
			sum = 0;
			for(k = 0;k<SIZE;k++)
				sum += AA[(i*SIZE) + k] * B[(k*SIZE) + j];
			result[(i*SIZE) + j] = sum;
		}
	}
	
}





//==================


void __attribute__ ((section("mprjram")))isr_dma(){
	intr_dma = 1;
	for(int i=0;i<NI; i++)
		output[i] = outputsignal[i];
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



	//while( read_wb(WB_FIR_BLK_LVL) & (1<<ap_idle ) != 1<<ap_idle);
	//int ii=0;
	//do{
	//	send_wb(0x2600000c, outputsignal[ii++]<<16);
	//}while(ii<NI);
	//return outputsignal;
}
		


int __attribute__ ( ( section ( ".mprjram" ) ) ) main_func(){
	qsort();
	fir();
	matmul();
	//while(!intr_dma);

	
	return 0;
}