# Soc Final Project

[TOC]


## Git command step

### 1. 初始設定
Clone這個proj
>git clone git@github.com:s095339/SOC_wlos_opt.git

用git branch檢查branch 的名稱是不是develop 如果不是
> git clone -b develop  git@github.com:s095339/SOC_wlos_opt.git

如果是就不用做。
這次要保護main branch，上面只能放「可以動」的版本。所以要開一個develop branch開發。整個實作都會在develop上merge 完成。

再來，開自己的branch。為了讓工作比較明瞭，branch的名稱不能亂取。這邊的branch統一叫做feature branch，代表我們要加到專案上的feature，也就是全雙工uart、DMA、SDRAM這三個東西

> git branch feature-[your branch name]

[your branch name] 可以是uart dma sdram 反正要取很好懂名字就可以。例如
> git branch feature-uart

然後切到你的branch 
> git checkout [your branch name]

這樣就可以開始自己的工作了，

### 2. 流程
在自己做的時候，commit message要盡量寫的詳細，內容包含：
1.開頭：大致做了甚麼 add modify delte
2.原因或問題
3.做了甚麼修改
例如
```text=
fix: 修改uart Fifo
問題：fifo無法正確運作，韌體無法把資料傳下來
原因：因為某某寫錯了
修改：修改了FIFO的某個功能
```

當自己的feature寫好測試好之後，首先要把別人可能在develop branch上的改變先pull下來，看看自己已經可以動的code，跟別人的東西一起跑會不會動

(在你自己的branch) 把遠端的develop pull下來
```
git pull origin develop
git checkout develop    // 順便切到develop把
git pull                // develop的最新變化pull下來 
git checkout [your branch]
```
然後做測試。可能會有不能動的結果，修改到可以動後，把自己的修改給commit，然後切到develop，把自己的feature給合併到develop 並 push
```
git checkout develop
git pull 
git merge --no-ff [your branch]
git push
```


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


