# Soc Final Project

[TOC]


## Git command step

### 1. 初始設定
Clone這個proj
>git clone git@github.com:s095339/SOC_wlos_opt.git


開自己的branch。為了讓工作比較明瞭，branch的名稱不能亂取。這邊的branch統一叫做feature branch，代表我們要加到專案上的feature，也就是全雙工uart、DMA、SDRAM這三個東西

> git branch feature-[your branch name]

[your branch name] 可以是uart dma sdram 反正要取很好懂名字就可以。例如
> git branch feature-uart

然後切到你的branch 
> git checkout [your branch name]

這樣就可以開始自己的工作了，




## Optimization
### 1. Full-duplex Uart Optimization

### 2. SDRAM intergration

### 3. FIR using DMA




## Command from lab5
### Simulation for matrix multiplication
```sh
cd ~/caravel-soc_fpga-lab/lab-wlos_baseline/testbench/counter_la_mm
source run_clean
source run_sim
```

### Simulation for FIR
```sh
cd ~/caravel-soc_fpga-lab/lab-wlos_baseline/testbench/counter_la_fir
source run_clean
source run_sim
```

### Simulation for qsort
```sh
cd ~/caravel-soc_fpga-lab/lab-wlos_baseline/testbench/counter_la_qs
source run_clean
source run_sim
```

### Simulation for uart
```sh
cd ~/caravel-soc_fpga-lab/lab-wlos_baseline/testbench/uart
source run_clean
source run_sim
```

## Verification with Vivado
### Synthesis and Generate bitstream
```sh
cd ~/caravel-soc_fpga-lab/lab-wlos_baseline/vivado
source run_vivado
```


