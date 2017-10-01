/**
Semihosting for ARM Cortex-M processors.
 */
module semihosting;

version (LDC)
{
    import ldc.llvmasm;
}

version(ARM_Thumb):
@nogc:
nothrow:

version (LDC)
{
    pragma(LDC_no_moduleinfo);
    pragma(LDC_no_typeinfo);
}


/**
Semihosting's operations.

See_also:
  semihosting: http://www.keil.com/support/man/docs/armcc/armcc_pge1358787045051.htm
 */
enum SYS : uint
{
    OPEN = 0x01,
    CLOSE = 0x02,
    WRITEC = 0x03,
    WRITE0 = 0x04,
    WRITE = 0x05,
    READ = 0x06,
    READC = 0x07,
    ISERROR = 0x08,
    ISTTY = 0x09,
    SEEK = 0x0A,
    FLEN = 0x0C,
    TMPNAM = 0x0D,
    REMOVE = 0x0E,
    RENAME = 0x0F,
    CLOCK = 0x10,
    TIME = 0x11,
    SYSTEM = 0x12,
    ERRNO = 0x13,
    GET_CMDLINE = 0x15,
    HEAPINFO = 0x16,
    ENTERSVC = 0x17,
    REPORT_EXCEPTION = 0x18,
    ELAPSED = 0x30,
    TICKFREQ = 0x31
}


/**
open syscall mode params.
 */
enum MODE : uint
{
    R = 0,
    R_BINARY = 1,
    RW = 2,
    RW_BINARY = 3,
    W_TRUNC = 4,
    W_TRUNC_BINARY = 5,
    RW_TRUNC = 6,
    RW_TRUNC_BINARY = 7,
    W_APPEND = 8,
    W_APPEND_BINARY = 9,
    RW_APPEND = 10,
    RW_APPEND_BINARY = 11,
}


/**
Call semihosting's operations.
 */
int syscall(uint nr, const uint* arg) pure
{
    return __asm!int("bkpt 0xAB", "={r0}, ~{r0}, ~{r1}", nr, arg);
}


/**
Open file $(D name) with mode $(mode).
 */
int open(in string name, MODE mode) pure
{
    const uint[3] arg = [cast(uint) name.ptr, mode, name.length - 1];
    return syscall(SYS.OPEN, arg.ptr);
}


/**
Writes its arguments to host.
*/
int write(int fd, in ubyte* ptr, uint len) pure
{
    const uint[3] arg = [cast(uint) fd, cast(uint) ptr, len];
    return syscall(SYS.WRITE, arg.ptr);
}


/**
Open host's standard output and writes its arguments to.
*/
void writeBuffer(in ubyte[] buffer)
{
    auto fd = open(":tt\0", MODE.W_TRUNC);
    auto ptr = buffer.ptr;
    auto len = buffer.length;

    while (len > 0)
    {
        auto n = write(fd, ptr, len);
        if (n == -1)
            break; // TODO: panic.
        if (n == 0)
            break;
        len -= n;
        ptr += n;
    }
}


/// ditto
void write(in string s)
{
    writeBuffer(cast(const ubyte[]) s);
}


/**
Writes its arguments to host, followed by a newline.
*/
void writeln(in string s)
{
    writeBuffer(cast(const ubyte[]) s);
    const ubyte[1] lf = ['\n'];
    writeBuffer(lf);
}
