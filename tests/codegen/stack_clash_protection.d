// REQUIRES: atleast_llvm1200

// RUN: %ldc -output-ll -fstack-clash-protection -of=%t.ll %s && FileCheck %s < %t.ll

pragma(mangle, "foo")
void foo()
{
    // CHECK: attributes #0 = { {{.*}}"probe-stack"="inline-asm"{{.*}} }
}
