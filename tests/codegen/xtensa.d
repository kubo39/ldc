// REQUIRES: target_Xtensa

// RUN: %ldc --mtriple=xtensa-esp32-elf --betterC --output-ll -of=%t.ll %s && FileCheck %s < %t.ll

extern (C):

version (Xtensa) {} else static assert(0);

align(16) struct S16 { int[4] a; }

// CHECK: define{{.*}} void @callee_struct_a16b_1(%xtensa.S16 %{{.*}}) {{.*}} {
void callee_struct_a16b_1(S16 a) {}

// CHECK: define{{.*}} void @callee_struct_a16b_2(%xtensa.S16 %{{.*}}, i32 %{{.*}}) {{.*}} {
void callee_struct_a16b_2(S16 a, int b) {}

// CHECK: define{{.*}} void @callee_struct_a16b_3(i32 %{{.*}}, ptr {{.*}} align 16 {{.*}}) {{.*}} {
void callee_struct_a16b_3(int a, S16 b) {}


pragma(LDC_intrinsic, "llvm.xtensa.xt.float.s")
float llvm_xtensa_xt_float_s(int, int);

float test_float_s(int a)
{
    // CHECK: %{{.*}} = call float @llvm.xtensa.xt.float.s(i32 %{{.*}}, i32 immarg 1)
    return llvm_xtensa_xt_float_s(a, 1);
}

pragma(LDC_intrinsic, "llvm.xtensa.xt.ufloat.s")
float llvm_xtensa_xt_ufloat_s(int, int);

float test_ufloat_s(int a)
{
    // CHECK: %{{.*}} = call float @llvm.xtensa.xt.ufloat.s(i32 %{{.*}}, i32 immarg 1)
    return llvm_xtensa_xt_ufloat_s(a, 1);
}

pragma(LDC_intrinsic, "llvm.xtensa.xt.trunc.s")
int llvm_xtensa_xt_trunc_s(float, int);

int test_trunc_s(float a)
{
    // CHECK: %{{.*}} = call i32 @llvm.xtensa.xt.trunc.s(float %{{.*}}, i32 immarg 1)
    return llvm_xtensa_xt_trunc_s(a, 1);
}

pragma(LDC_intrinsic, "llvm.xtensa.xt.utrunc.s")
int llvm_xtensa_xt_utrunc_s(float, int);

int test_utrunc_s(float a)
{
    // CHECK: %{{.*}} = call i32 @llvm.xtensa.xt.utrunc.s(float %{{.*}}, i32 immarg 1)
    return llvm_xtensa_xt_utrunc_s(a, 1);
}

pragma(LDC_intrinsic, "llvm.xtensa.xt.add.s")
float llvm_xtensa_xt_add_s(float, float);

float test_add_s(float a, float b)
{
    // CHECK: %{{.*}} = call float @llvm.xtensa.xt.add.s(float %{{.*}}, float %{{.*}})
    return llvm_xtensa_xt_add_s(a, b);
}

pragma(LDC_intrinsic, "llvm.xtensa.xt.sub.s")
float llvm_xtensa_xt_sub_s(float, float);

float test_sub_s(float a, float b)
{
    // CHECK: %{{.*}} = call float @llvm.xtensa.xt.sub.s(float %{{.*}}, float %{{.*}})
    return llvm_xtensa_xt_sub_s(a, b);
}

pragma(LDC_intrinsic, "llvm.xtensa.xt.mul.s")
float llvm_xtensa_xt_mul_s(float, float);

float test_mul_s(float a, float b)
{
    // CHECK: %{{.*}} = call float @llvm.xtensa.xt.mul.s(float %{{.*}}, float %{{.*}})
    return llvm_xtensa_xt_mul_s(a, b);
}


struct RetVal { float val0; float* val1; }

pragma(LDC_intrinsic, "llvm.xtensa.xt.lsip")
RetVal llvm_xtensa_xt_lsip(float*, int);

pragma(LDC_inline, true)
float test_lsip(float** a)
{
    float* p = *a;
    // CHECK: %{{.*}} = call { float, ptr } @llvm.xtensa.xt.lsip(ptr %{{.*}}, i32 immarg 0)
    auto retval = llvm_xtensa_xt_lsip(p, 0);
    return retval.val0;
}

pragma(LDC_intrinsic, "llvm.xtensa.xt.lsxp")
RetVal llvm_xtensa_xt_lsxp(float*, int);

pragma(LDC_inline, true)
float test_lsxp(float** a0, int a1)
{
    float* p = *a0;
    // CHECK: %{{.*}} = call { float, ptr } @llvm.xtensa.xt.lsxp(ptr %{{.*}}, i32 {{.*}})
    auto retval = llvm_xtensa_xt_lsxp(p, a1);
    return retval.val0;
}


import ldc.llvmasm;

void test_inlineasm()
{
    // CHECK: {{.*}} = load float, ptr {{.*}}
    float f = void;
    // CHECK: call void asm sideeffect "", "f"(float {{.*}})
    __asm("", "f", f);
}


import ldc.attributes;

// CHECK: define{{.*}} void @test_near() [[NEAR:#[0-9]+]] {
@llvmAttr("near")
void test_near()
{
    test_short_call();
}

// CHECK: declare void @test_short_call() [[SHORTDECL:#[0-9]+]]
@llvmAttr("short-call")
void test_short_call();

// CHECK: attributes [[NEAR]] = { {{.*}} "near" {{.*}} }
// CHECK: attributes [[SHORTDECL]] = { {{.*}} "short-call" {{.*}} }
