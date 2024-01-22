#ifndef __FIR_H__
#define __FIR_H__
#define RCV_SDRAM_INDATA __attribute__((section(".indata")))
#define RCV_SDRAM_OUTDATA __attribute__((section(".outdata")))
#include <stdint.h> 

// linker memory
#define INDATA_ADR  0x38001000
#define OUTDATA_ADR  0x38002000
//wishbone operation
#define send_wb(target,data) (*(volatile uint32_t*)(target)) = data // send wishbone signal
#define read_wb(target)  (*(volatile uint32_t*)(target))// wishbone read
//data memory

//************************************************************/
//fir accelerater                                             /
//************************************************************/
#define N 11
#define NI 64
volatile RCV_SDRAM_INDATA int inputsignal[NI]; 
volatile RCV_SDRAM_OUTDATA int outputsignal[NI];

int output[NI];

int taps[N] = {0,-10,-9,23,56,63,56,23,-9,-10,0};
// fir mmio
#define WB_FIR_BLK_LVL      0x30000000
#define WB_FIR_TAP_START    0x30000040
#define WB_DMA_START_ADDR   0x30000080
#define WB_DMA_LENGTH_ADDR  0x30000084
#define WB_DMA_SAVE_ADDR    0x30000088
#define data_len N
enum BLKLVL 
{
    ap_start, ap_done, ap_idle
};

// fir funcion/macro
void init_fir_taps(int * t, int n){
    for(int i=0;i<n;i++){
        send_wb(WB_FIR_TAP_START + i*4, t[i]);
    }
}
void send_fir_input(){
    for(int i=0;i<NI;i++){
        inputsignal[i] = i;
    }
}
void start_dma(uint32_t start_addr, int input_length, uint32_t save_addr){

    send_wb(WB_DMA_START_ADDR ,start_addr);
    send_wb(WB_DMA_LENGTH_ADDR ,input_length);
    send_wb(WB_DMA_SAVE_ADDR ,save_addr);
}

//=======================================================================//
//algorithm                                                              //
//=======================================================================//
//qsort

#define SIZES 10
int A[SIZES] = {893, 40, 3233, 4267, 2669, 2541, 9073, 6023, 5681, 4622};

//matmul

#define SIZE 4
	int AA[SIZE*SIZE] = {0, 1, 2, 3,
			0, 1, 2, 3,
			0, 1, 2, 3,
			0, 1, 2, 3,
	};
	int B[SIZE*SIZE] = {1, 2, 3, 4,
		5, 6, 7, 8,
		9, 10, 11, 12,
		13, 14, 15, 16,
	};
	int result[SIZE*SIZE];

#endif