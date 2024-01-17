#ifndef __HEADER__H_
#define __HEADER__H_


//fir
#define N 11

int taps[N] = {0,-10,-9,23,56,63,56,23,-9,-10,0};
int inputbuffer[N];
int inputsignal[N] = {1,2,3,4,5,6,7,8,9,10,11};
int outputsignal[N];

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


#define TESTPRINT(data)  (*(volatile int32_t*)0x30000090) = data

//uart end
int endflag = 0;
int intr_flag = 0;
#define uart_fifo_depth 8
#define GPIO 0x260000c
#define send_wb(target, data) (*(volatile uint32_t*)(target) = data)

#endif