// RUN: %ldc -output-ll -of=%t.ll %s && FileCheck %s < %t.ll

// CHECK: align 16
align(16) void foo() {}
