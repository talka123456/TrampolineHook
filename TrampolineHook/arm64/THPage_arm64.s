#if defined(__arm64__)

/*
 .text 代表代码段
 .align 内存对齐， 这里 14 表示以 2^14 = 16kb 大小对齐， 16kb 正好是 iOS 中的一页内存的大小
 .global 定义 _th_dynamic_page 为全局符号， 即模块内可访问（代码也可以访问）
 */
.text
.align 14
.globl _th_dynamic_page

/*
 interceptor: 定义一个标签， 名字叫 interceptor
 .quad 0 开辟 8 字节的内存大小
 
 该命令的内存空间 用于保存自定义跳转函数 IMP， 拦截器函数的 IMP
 */
interceptor:
.quad 0

/*
 .align 14： 开辟一个新的内存页，
 _th_dynamic_page: 定义_th_dynamic_page 标签
 _th_entry:： 定义 _th_entry: 标签
 nop: 什么都不执行， 只是启到指令地址占位的作用
 */
.align 14
_th_dynamic_page:

/*
 _th_entry 中的内容是执行自定义操作并恢复现场，包含步骤为：
    - 通过偏移获取原 IMP 地址
    - 保存原来的 IMP 用的寄存器和栈空间 ，参数寄存器 x0 - x7、浮点寄存器 q0 - q7 、返回地址寄存器 lr
    - 调用 interceptor
    - 恢复 x0 - x7、q0 - q7、lr
    - 转到原 IMP 地址（不返回）
 */
_th_entry:

nop
nop
nop
nop
nop

sub x12, lr,   #0x8 // 将 lr 地址 - 0x8 获取到的是本次桥接的新的 IMP 地址，即.rept中 本次的 mov 指令地址
sub x12, x12,  #0x4000 // 通过偏移一整页大小， 获取到 data page中存储的原函数 IMP
mov lr,  x13 // 恢复 原函数的 lr 寄存器的值，跳转 origin func 后返回地址

ldr x10, [x12] // 取出原函数 IMP 地址

// 保存浮点寄存器 [sp, #-32]!： 是将 q0 和 q1 放到 sp - 32(0x20)的栈空间， 然后更新 sp 。sp = sp - 32(0x20)
// 最终结果为 : q0 q1 保存到 sp - 0x20; q2 q3 保存到 sp - 0x40;  q4 q5 保存到 sp - 0x60; q6 q7 保存到 sp - 0x80;
// 不理解的是，这里为什么每次要偏移 32 字节，占用这么大吗？？？（浮点值按'内部格式'存储并占用三个字(12 字节) ARM64里面 对栈的操作是16字节对齐的，所以给了 16 字节）
stp q0,  q1,   [sp, #-32]!
stp q2,  q3,   [sp, #-32]!
stp q4,  q5,   [sp, #-32]!
stp q6,  q7,   [sp, #-32]!

// 保存 lr 原函数 IMP x0 ~ x8 参数寄存器， 同样的道理，
stp lr,  x10,  [sp, #-16]!
stp x0,  x1,   [sp, #-16]!
stp x2,  x3,   [sp, #-16]!
stp x4,  x5,   [sp, #-16]!
stp x6,  x7,   [sp, #-16]!
str x8,        [sp, #-16]!

// 加载 自定义的 interceptor 拦截器函数的 IMP，并调用
ldr x8,  interceptor
// blr 指令和 bl 类似，但是要求跳转的目的地址从寄存器中获取， b/ bl 是通过rip(PC + offset偏移)计算获得， b 是直接跳转不返回，bl会更新 lr
blr x8

// 恢复寄存器，同保存逆序恢复
ldr x8,        [sp], #16
ldp x6,  x7,   [sp], #16
ldp x4,  x5,   [sp], #16
ldp x2,  x3,   [sp], #16
ldp x0,  x1,   [sp], #16
ldp lr,  x10,  [sp], #16

ldp q6,  q7,   [sp], #32
ldp q4,  q5,   [sp], #32
ldp q2,  q3,   [sp], #32
ldp q0,  q1,   [sp], #32

// 跳转原函数
br  x10

/*
 .rept 2032 ： 表示重复该代码段， 2032 表示次数
 .endr： 表示重复的结束标识
 
 所以代表重复 2032 次 指令：mov x13, lr 和指令： bl _th_entry;
 */
.rept 2032
mov x13, lr // 保存原来函数的 lr 寄存器， 这一条指令的地址，即为新的 trampoline 桥的地址，
bl _th_entry; // 开始调用 Entry，由于是 bl 指令， 更新 lr 为下一个指令地址（该处的下一条指定是 rept 中的 下一条 mov x13 lr）
.endr

#endif


