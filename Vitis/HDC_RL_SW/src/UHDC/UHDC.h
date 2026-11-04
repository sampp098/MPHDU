
#ifndef UHDCA_HEADER
#define UHDCA_HEADER

#include "xparameters.h"
#include "xaxidma.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xstatus.h"
#include "xil_io.h"
#include "sleep.h"
#include "instruction.h"

#define DMA_DEV_ID         XPAR_AXIDMA_0_DEVICE_ID
#define GPIO_CTRL_ADDR     XPAR_AXI_GPIO_0_BASEADDR
#define DMA_RESET_ADDR     0xFF0A0054
#define MAX_TX_WORDS       256

//Hamming Distance
#define MHV_BASE_ADDR   XPAR_UHDC_HMMD_MEMCTRL_0_BASEADDR
#define MHV_ROWS        7U
#define MHV_BITS        1024U
#define MHV_WORDS       (MHV_BITS / 32U)

/* MHV is a 2D array located at BRAM base address */
extern volatile u32 (*MHV)[MHV_WORDS];


extern XAxiDma AxiDma;
extern u32 TxBuffer[MAX_TX_WORDS] __attribute__((aligned(64)));
void MHV_init();
void PrintDmaMm2sStatus(XAxiDma *AxiDma);

int DmaInit(void);

int DmaSendWords(const u32 *src, int words, int verbose);

void UHDC_ResetStart(void);
void UHDC_Reset(void);
void UHDC_Start(void);

void PS_DMA_Reset(void);

#endif
