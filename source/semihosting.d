module semihosting;

version (LDC)
{
    import ldc.llvmasm;
}

version(ARM_Thumb):
extern(C):
@nogc:
nothrow:

version (LDC)
{
    pragma(LDC_no_moduleinfo);
    pragma(LDC_no_typeinfo);
}

enum SYS : uint
{
    OPEN = 1,
    WRITE = 5,
}

enum MODE : uint
{
    W_TRUNC = 4,
}

int syscall(uint nr, const uint* arg) pure
{
    return __asm!int("bkpt 0xAB", "={r0}, ~{r0}, ~{r1}", nr, arg);
}

int open(in string name, MODE mode) pure
{
    const uint[3] arg = [cast(uint) name.ptr, mode, name.length - 1];
    return syscall(SYS.OPEN, arg.ptr);
}

int write(int fd, in ubyte* ptr, uint len) pure
{
    const uint[3] arg = [cast(uint) fd, cast(uint) ptr, len];
    return syscall(SYS.WRITE, arg.ptr);
}

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

void writeString(in string s)
{
    writeBuffer(cast(const ubyte[]) s);
}
