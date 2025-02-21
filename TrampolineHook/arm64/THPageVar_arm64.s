#if defined(__arm64__)

// data page
.text
.align 14
.globl _th_dynamic_page_var

/*
 对应 simple 样式，这里有一些区别， 多开辟了 pre 8 字节 post 8 字节的空间
 */
interceptor:
.quad 0

pre:
.quad 0

post:
.quad 0

// code page

.align 14
_th_dynamic_page_var:

// entry 指令集也减少到了 10
_th_entry_var:

nop

// 当前 hook 的桥接地址
sub x12, lr,   #0x8

// 获取偏移的 原函数 IMP
sub x12, x12,  #0x4000

// 存储 IMP 值到 x10 寄存器
ldr x10, [x12]

ldr x8,  pre // pre函数地址保存到 x8
blr x8 // 跳转到 pre 然后创建堆空间并保存上下文环境到堆空间， 

ldr x8,  interceptor // interceptor 函数地址 保存到 x8
blr x8

ldr x8,  post  // post 函数地址保存到 x8， 恢复上下文寄存器并释放堆空间，内部调用了原函数的 IMP
br  x8

.rept 2043
mov x13, lr
bl _th_entry_var;
.endr

#endif


