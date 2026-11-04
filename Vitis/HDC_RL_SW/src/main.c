#include "UHDC/UHDC.h"
#include <string.h>

#define PROGRAM_WORDS   128
#define BCACHE_WORDS    128

u32 program[PROGRAM_WORDS];
u32 bcache_data[BCACHE_WORDS];
u32 bcache_out[BCACHE_WORDS];

static u32 RxBuffer[BCACHE_WORDS] __attribute__((aligned(64)));

static void PrintDmaS2mmStatus(XAxiDma *AxiDma)
{
    u32 sr;

    sr = XAxiDma_ReadReg(AxiDma->RegBase + XAXIDMA_RX_OFFSET,
                         XAXIDMA_SR_OFFSET);

    //xil_printf("S2MM_DMASR = 0x%08x\r\n", sr);
    //xil_printf("  Halted = %d\r\n", (sr & XAXIDMA_HALTED_MASK) ? 1 : 0);
    //xil_printf("  Idle   = %d\r\n", (sr & XAXIDMA_IDLE_MASK)   ? 1 : 0);
    //xil_printf("  IOC    = %d\r\n", (sr & XAXIDMA_IRQ_IOC_MASK) ? 1 : 0);
    //xil_printf("  Error  = %d\r\n", (sr & XAXIDMA_ERR_ALL_MASK) ? 1 : 0);
}

static int DmaResetCore(void)
{
    int timeout = 1000000;

    XAxiDma_Reset(&AxiDma);

    while (timeout > 0) {
        if (XAxiDma_ResetIsDone(&AxiDma)) {
            return XST_SUCCESS;
        }
        timeout--;
    }

    xil_printf("DMA reset timeout\r\n");
    return XST_FAILURE;
}

static int DmaArmReadWords(int words)
{
    int Status;

    if ((words <= 0) || (words > BCACHE_WORDS)) {
        xil_printf("Invalid RX word count: %d\r\n", words);
        return XST_FAILURE;
    }

    if (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA)) {
        xil_printf("S2MM was busy, resetting DMA core...\r\n");
        Status = DmaResetCore();
        if (Status != XST_SUCCESS) {
            return XST_FAILURE;
        }
    }

    memset(RxBuffer, 0, words * sizeof(u32));
    Xil_DCacheFlushRange((UINTPTR)RxBuffer, words * sizeof(u32));
    //xil_printf("RxBuffer addr = 0x%08lx\r\n", (UINTPTR)RxBuffer);
    //xil_printf("RX MaxTransferLen = %lu\r\n", (u32)AxiDma.RxBdRing[0].MaxTransferLen);
    //xil_printf("RX DataWidth      = %lu\r\n", (u32)AxiDma.RxBdRing[0].DataWidth);
    //xil_printf("RX HasDRE         = %lu\r\n", (u32)AxiDma.RxBdRing[0].HasDRE);
    //xil_printf("RX length(bytes)  = %d\r\n", words * (int)sizeof(u32));
    Status = XAxiDma_SimpleTransfer(&AxiDma,
                                    (UINTPTR)RxBuffer,
                                    words * sizeof(u32),
                                    XAXIDMA_DEVICE_TO_DMA);
    if (Status != XST_SUCCESS) {
        xil_printf("S2MM SimpleTransfer failed: %d\r\n", Status);
        PrintDmaS2mmStatus(&AxiDma);
        return XST_FAILURE;
    }

    return XST_SUCCESS;
}

static int DmaWaitReadWords(u32 *dst, int words, int verbose)
{
    int i;
    u32 sr;

    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA)) {
        if (verbose) {
            PrintDmaS2mmStatus(&AxiDma);
        }
    }

    sr = XAxiDma_ReadReg(AxiDma.RegBase + XAXIDMA_RX_OFFSET,
                         XAXIDMA_SR_OFFSET);

    if (sr & XAXIDMA_ERR_ALL_MASK) {
        xil_printf("S2MM completed with error, SR = 0x%08x\r\n", sr);
        PrintDmaS2mmStatus(&AxiDma);
        return XST_FAILURE;
    }

    Xil_DCacheInvalidateRange((UINTPTR)RxBuffer, words * sizeof(u32));

    for (i = 0; i < words; i++) {
        dst[i] = RxBuffer[i];
    }

    return XST_SUCCESS;
}



void UHDC_init(void)
{
    int i;
    int a=0;
    int b=1;
    int c=2;
    int v=10;
    int c_rr=3;
    int int_temp = 0;
    int T=2;
    int h = 4;
    int pc = 0;

    // Program the instruction Cache
    program[pc++]  = BLD();
    program[pc++]  = XORLDA(a);
    program[pc++]  = XORLDB(b);//Try loadA and LoadA to see if it works!
    program[pc++]  = XORSTR(c);//c = a XOR b
    program[pc++]  = ROTLDB(2);// 2+1 bits shift
    program[pc++]  = ROTLDS(c);
    program[pc++]  = ROTLDS(c);
    program[pc++]  = ROTSTR(c_rr);
    program[pc++]  = PSUMLDS(a);
    program[pc++]  = PSUMLDS(b);
    program[pc++]  = PSUMLDS(c_rr);
    program[pc++]  = PSUMSTR(int_temp);
    program[pc++]  = MAJLDL(T);
    program[pc++]  = MAJLDS(int_temp);
    program[pc++]  = MAJSTR(h);

    program[pc++]  = MAJHmD();
    program[pc++]  = XORLDA(v);
    program[pc++]  = XORLDA(v);
    program[pc++]  = XORHmD();
    program[pc++]  = BSTR();
    //program[10] = XORACC_CFG(20, 40);
    //program[11] = XORACC_RUN(8, 60);
    for (i = pc; i < 128; i++) {
        program[i] = NOP();
    }
}

void BCache_init(void)
{
    int i;
    int a_addr=0;
    int b_addr=1;
    int a = 0xFF55AA00;
    int b = 0x00AA5577;
    int v = 0xFFFFFFFF;
    // c=XOR(a,b) = 0xFFFFFF77
    //ROT(c,2bit) = 0xFFFFFFDD
    /*temp=PSUM(a,b,c_rr)= 0xFF55AA00
    *			   		 + 0x00AA5577
    *					 + 0xFFFFFFDD
    */
    //Maj(temp) = 0xFFFFFF55
    bcache_data[a_addr] = a;
    bcache_data[b_addr] = b;

    for (i = b_addr+1; i < 128; i++) {
        bcache_data[i] = 0x00000000;
    }
    bcache_data[10] = v;
}

int main(void)
{
	int Status;
	int i;
	//init_platform();
	//Xil_DCacheDisable();

    PS_DMA_Reset();

    Status = DmaInit();
    xil_printf("HasMm2S = %d\r\n", AxiDma.HasMm2S);
    xil_printf("HasS2Mm = %d\r\n", AxiDma.HasS2Mm);
    xil_printf("HasSg   = %d\r\n", AxiDma.HasSg);
    xil_printf("RxChanBase = 0x%08lx\r\n", (UINTPTR)AxiDma.RxBdRing[0].ChanBase);
    xil_printf("TxChanBase = 0x%08lx\r\n", (UINTPTR)AxiDma.TxBdRing.ChanBase);

    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    UHDC_Reset();
    UHDC_init();
    BCache_init();
    UHDC_Start();
    //UHDC_ResetStart();
    MHV_init(); //Load Action Vectors

    // Step 1: Send instructions → control starts executing immediately
    xil_printf("Sending instruction program...\r\n");
    Status = DmaSendWords(program, PROGRAM_WORDS, 0);
    if (Status != XST_SUCCESS) {
        xil_printf("Instruction MM2S failed\r\n");
        return XST_FAILURE;
    }
    xil_printf("Instruction program sent.\r\n");

    // Step 2: Arm S2MM BEFORE sending BCache data.
    // BLD fires as soon as BCache arrives, compute runs, then BSTR streams out.
    // S2MM must be waiting with TREADY=1 before any of that happens.
    xil_printf("Arming S2MM for BSTR output...\r\n");
    Status = DmaArmReadWords(BCACHE_WORDS);
    if (Status != XST_SUCCESS) {
        xil_printf("S2MM arm failed\r\n");
        return XST_FAILURE;
    }
    xil_printf("S2MM armed and waiting.\r\n");

    // Step 3: Send BCache → triggers BLD → compute → BSTR → S2MM captures it
    xil_printf("Sending binary-cache data...\r\n");
    Status = DmaSendWords(bcache_data, BCACHE_WORDS, 0);
    if (Status != XST_SUCCESS) {
        xil_printf("BCache MM2S failed\r\n");
        return XST_FAILURE;
    }
    xil_printf("Binary-cache data sent.\r\n");

    // Step 4: Wait for BSTR output to finish
    xil_printf("Waiting for BSTR output...\r\n");
    Status = DmaWaitReadWords(bcache_out, BCACHE_WORDS, 0);
    if (Status != XST_SUCCESS) {
        xil_printf("S2MM receive failed\r\n");
        return XST_FAILURE;
    }

    xil_printf("Received updated binary cache:\r\n");
    for (i = 0; i < 10; i++) {
        xil_printf("bcache_out[%3d] = 0x%08x\r\n", i, bcache_out[i]);
    }

    return XST_SUCCESS;
}

