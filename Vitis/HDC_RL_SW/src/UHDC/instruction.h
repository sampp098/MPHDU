#ifndef INST_BUILDER_H
#define INST_BUILDER_H

#include <stdint.h>

typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t  u8;

/* ---------------- Opcodes ---------------- */
enum {
    OP_NOP      = 0x00,
    OP_BLD      = 0x01,
    OP_BSTR     = 0x02,
    OP_ILD      = 0x03,
    OP_ISTR     = 0x04,

    OP_XORLDA   = 0x05,
    OP_XORLDB   = 0x06,
    OP_XORSTR   = 0x07,

    OP_ROTLDB   = 0x08,
    OP_ROTLDS   = 0x09,
    OP_ROTSTR   = 0x0A,

    OP_PSUMLDS  = 0x0B,
    OP_PSUMSTR  = 0x0C,

    OP_MAJLDL   = 0x0D,
    OP_MAJLDS   = 0x0E,
    OP_MAJSTR   = 0x0F,

    OP_XORLOOP  = 0x10,
    OP_ROTLOOP  = 0x11,
    OP_XORACC   = 0x12,
    OP_BINLOOP  = 0x13,
    OP_PSUMLOOP = 0x14,

    OP_XORHMD   = 0x1D,
    OP_ROTHMD   = 0x1E,
    OP_MAJHMD   = 0x1F
};

/* ---------------- Field masks ---------------- */
#define OPCODE_SHIFT   27u
#define OPCODE_MASK    0x1Fu
#define IMM27_MASK     0x07FFFFFFu
#define FIELD13_MASK   0x1FFFu

/* Simple packers */
static inline u32 INST_OP(u32 op)
{
    return (op & OPCODE_MASK) << OPCODE_SHIFT;
}

static inline u32 INST_IMM27(u32 op, u32 imm27)
{
    return ((op & OPCODE_MASK) << OPCODE_SHIFT) |
           (imm27 & IMM27_MASK);
}

static inline u32 INST_2F13(u32 op, u32 a, u32 b)
{
    return ((op & OPCODE_MASK) << OPCODE_SHIFT) |
           ((a & FIELD13_MASK) << 13) |
           (b & FIELD13_MASK);
}

static inline u32 INST_MACRO(u32 op, u32 phase, u32 a, u32 b)
{
    return ((op & OPCODE_MASK) << OPCODE_SHIFT) |
           ((phase & 0x1u) << 26) |
           ((a & FIELD13_MASK) << 13) |
           (b & FIELD13_MASK);
}

/* ---------------- Single-word instructions ---------------- */
static inline u32 NOP(void)      { return INST_OP(OP_NOP);  }
static inline u32 BLD(void)      { return INST_OP(OP_BLD);  }
static inline u32 BSTR(void)     { return INST_OP(OP_BSTR); }
static inline u32 ILD(void)      { return INST_OP(OP_ILD);  }
static inline u32 ISTR(void)     { return INST_OP(OP_ISTR); }

static inline u32 XORLDA(u16 addr)   { return INST_IMM27(OP_XORLDA,  addr); }
static inline u32 XORLDB(u16 addr)   { return INST_IMM27(OP_XORLDB,  addr); }
static inline u32 XORSTR(u16 addr)   { return INST_IMM27(OP_XORSTR,  addr); }

static inline u32 ROTLDB(u8 rot)     { return INST_IMM27(OP_ROTLDB,  rot);  }
static inline u32 ROTLDS(u16 addr)   { return INST_IMM27(OP_ROTLDS,  addr); }
static inline u32 ROTSTR(u16 addr)   { return INST_IMM27(OP_ROTSTR,  addr); }

static inline u32 PSUMLDS(u16 addr)  { return INST_IMM27(OP_PSUMLDS, addr); }
static inline u32 PSUMSTR(u16 addr)  { return INST_IMM27(OP_PSUMSTR, addr); }

static inline u32 MAJLDL(u32 value)  { return INST_IMM27(OP_MAJLDL,  value); }
static inline u32 MAJLDS(u16 addr)   { return INST_IMM27(OP_MAJLDS,  addr); }
static inline u32 MAJSTR(u16 addr)   { return INST_IMM27(OP_MAJSTR,  addr); }

static inline u32 XORHmD(void)       { return INST_OP(OP_XORHMD); }
static inline u32 ROTHmD(void)       { return INST_OP(OP_ROTHMD); }
static inline u32 MAJHmD(void)       { return INST_OP(OP_MAJHMD); }

/* ---------------- Two-word macro instructions ---------------- */
/* phase = 0 word */
static inline u32 ROTLOOP_CFG(u16 src_addr, u16 rot_amount)
{
    return INST_MACRO(OP_ROTLOOP, 0, src_addr, rot_amount);
}

static inline u32 XORACC_CFG(u16 src_a_addr, u16 src_b_addr)
{
    return INST_MACRO(OP_XORACC, 0, src_a_addr, src_b_addr);
}

static inline u32 BINLOOP_CFG(u16 src_addr, u16 level)
{
    return INST_MACRO(OP_BINLOOP, 0, src_addr, level);
}

static inline u32 PSUMLOOP_CFG(u16 src_addr, u16 reserved)
{
    return INST_MACRO(OP_PSUMLOOP, 0, src_addr, reserved);
}

/* phase = 1 word */
static inline u32 ROTLOOP_RUN(u16 count, u16 dst_addr)
{
    return INST_MACRO(OP_ROTLOOP, 1, count, dst_addr);
}

static inline u32 XORACC_RUN(u16 count, u16 dst_addr)
{
    return INST_MACRO(OP_XORACC, 1, count, dst_addr);
}

static inline u32 BINLOOP_RUN(u16 count, u16 dst_addr)
{
    return INST_MACRO(OP_BINLOOP, 1, count, dst_addr);
}

static inline u32 PSUMLOOP_RUN(u16 count, u16 dst_addr)
{
    return INST_MACRO(OP_PSUMLOOP, 1, count, dst_addr);
}

#endif
