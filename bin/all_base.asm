add r9,r20,r10
addi r1,r2,#-5
and r9,r3,r10
andi r20,r9,#8
lw r19,63(r8)
nop 
or r5,r3,r4
ori r5,r3,#342
sge r1,r2,r10
sgei r9,r20,#6
sle r13,r2,r4
slei r1,r3,#-4
sll r1,r2,r3
slli r4,r1,#5
sne r1,r2,r3
snei r3,r5,#4
srl r5,r7,r8
srli r7,r5,#2
sub r6,r12,r15
subi r7,r9,#-30
sw 63(r8),r19
xor r6,r12,r15
xori r6,r12,#1
j 0x00000000
jal 0x00000000
beqz r1,0x00000000
bnez r1,0x00000000

