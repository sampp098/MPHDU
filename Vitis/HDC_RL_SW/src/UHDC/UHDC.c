#include "UHDC.h"

volatile u32 (*MHV)[MHV_WORDS] = (volatile u32 (*)[MHV_WORDS])MHV_BASE_ADDR;

void MHV_init(){
	u32 row, word;
	for (row = 0; row < MHV_ROWS; row++) {
        for (word = 0; word < MHV_WORDS; word++) {
            MHV[row][word] = 1U;
        }
    }
	Xil_DCacheFlushRange((UINTPTR)MHV, MHV_WORDS*MHV_ROWS* sizeof(u32));
}

XAxiDma AxiDma;
u32 TxBuffer[MAX_TX_WORDS] __attribute__((aligned(64)));
void PrintDmaMm2sStatus(XAxiDma *AxiDma)
{
    u32 sr;

    sr = XAxiDma_ReadReg(AxiDma->RegBase + XAXIDMA_TX_OFFSET, XAXIDMA_SR_OFFSET);

    xil_printf("MM2S_DMASR = 0x%08x\r\n", sr);
    xil_printf("  Halted = %d\r\n", (sr & XAXIDMA_HALTED_MASK) ? 1 : 0);
    xil_printf("  Idle   = %d\r\n", (sr & XAXIDMA_IDLE_MASK) ? 1 : 0);
    xil_printf("  IOC    = %d\r\n", (sr & XAXIDMA_IRQ_IOC_MASK) ? 1 : 0);
    xil_printf("  Error  = %d\r\n", (sr & XAXIDMA_ERR_ALL_MASK) ? 1 : 0);

    if (sr & XAXIDMA_ERR_INTERNAL_MASK) xil_printf("  Internal error\r\n");
    if (sr & XAXIDMA_ERR_SLAVE_MASK)    xil_printf("  Slave error\r\n");
    if (sr & XAXIDMA_ERR_DECODE_MASK)   xil_printf("  Decode error\r\n");
}

int DmaInit(void)
{
    XAxiDma_Config *CfgPtr;
    int Status;

    CfgPtr = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (CfgPtr == NULL) {
        xil_printf("No DMA configuration found.\r\n");
        return XST_FAILURE;
    }

    xil_printf("Cfg BaseAddr   = 0x%08lx\r\n", (UINTPTR)CfgPtr->BaseAddr);
    xil_printf("Cfg HasMm2S    = %d\r\n", CfgPtr->HasMm2S);
    xil_printf("Cfg HasS2Mm    = %d\r\n", CfgPtr->HasS2Mm);
    xil_printf("Cfg HasMm2SDRE = %d\r\n", CfgPtr->HasMm2SDRE);
    xil_printf("Cfg HasS2MmDRE = %d\r\n", CfgPtr->HasS2MmDRE);
    xil_printf("Cfg Mm2SWidth  = %d\r\n", CfgPtr->Mm2SDataWidth);
    xil_printf("Cfg S2MmWidth  = %d\r\n", CfgPtr->S2MmDataWidth);
    xil_printf("Cfg HasSg      = %d\r\n", CfgPtr->HasSg);


    Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
    if (Status != XST_SUCCESS) {
        xil_printf("DMA init failed: %d\r\n", Status);
        return XST_FAILURE;
    }

    if (XAxiDma_HasSg(&AxiDma)) {
        xil_printf("DMA is configured in Scatter-Gather mode.\r\n");
        return XST_FAILURE;
    }

    XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    return XST_SUCCESS;
}

int DmaSendWords(const u32 *src, int words, int verbose)
{
    int Status;
    int i;

    if ((words <= 0) || (words > MAX_TX_WORDS)) {
        xil_printf("Invalid DMA word count: %d\r\n", words);
        return XST_FAILURE;
    }

    for (i = 0; i < words; i++) {
        TxBuffer[i] = src[i];
    }

    Xil_DCacheFlushRange((UINTPTR)TxBuffer, words * sizeof(u32));

    Status = XAxiDma_SimpleTransfer(&AxiDma,
                                    (UINTPTR)TxBuffer,
                                    words * sizeof(u32),
                                    XAXIDMA_DMA_TO_DEVICE);
    if (Status != XST_SUCCESS) {
        xil_printf("SimpleTransfer failed: %d\r\n", Status);
        return XST_FAILURE;
    }

    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) {
        if (verbose) {
            PrintDmaMm2sStatus(&AxiDma);
        }
    }

    if (verbose) {
        xil_printf("DMA transfer completed: %d words\r\n", words);
    }

    return XST_SUCCESS;
}

void UHDC_ResetStart(void)
{
    Xil_Out32(GPIO_CTRL_ADDR, 0x1);  // reset
    Xil_Out32(GPIO_CTRL_ADDR, 0x0);  // release reset
    Xil_Out32(GPIO_CTRL_ADDR, 0x2);  // start
}

void UHDC_Reset(void)
{
    Xil_Out32(GPIO_CTRL_ADDR, 0x1);  // reset
    Xil_Out32(GPIO_CTRL_ADDR, 0x0);  // release reset
}
void UHDC_Start(void)
{
    Xil_Out32(GPIO_CTRL_ADDR, 0x2);  // start
}

void PS_DMA_Reset(void)
{
    Xil_Out32(DMA_RESET_ADDR, 0x00000000);
    usleep(10000);
    Xil_Out32(DMA_RESET_ADDR, 0x80000000);
}
