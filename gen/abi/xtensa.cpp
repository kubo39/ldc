//===-- gen/abi-xtensa.cpp - Xtensa ABI description -----------*- C++
//-*-===//
//
//                         LDC – the LLVM D compiler
//
// This file is distributed under the BSD-style LDC license. See the LICENSE
// file for details.
//
//===----------------------------------------------------------------------===//
//
// ABI spec:
// https://www.cadence.com/content/dam/cadence-www/global/en_US/documents/tools/ip/tensilica-ip/isa-summary.pdf
// https://dl.espressif.com/github_assets/espressif/xtensa-isa-doc/releases/download/latest/Xtensa.pdf
//
//===----------------------------------------------------------------------===//

#include "gen/abi/abi.h"
#include "gen/abi/generic.h"
#include "gen/dvalue.h"
#include "gen/irstate.h"
#include "gen/llvmhelpers.h"
#include "gen/tollvm.h"

struct XtensaTargetABI : TargetABI {
private:
  IndirectByvalRewrite indirectByvalRewrite{};
  static const int MaxNumArgGPRs = 6;
  static const int MaxNumRetGPRs = 4;

public:
  auto returnInArg(TypeFunction *tf, bool) -> bool override {
    if (tf->isref()) {
      return false;
    }
    Type *rt = tf->next->toBasetype();
    if (!isPOD(rt)) {
        return true;
    }
    // As for return values, they are returned in registers
    // beginning from a2 till a5.
    return rt->size() > 16;
  }

  auto passByVal(TypeFunction *, Type *t) -> bool override {
    if (!isPOD(t)) {
      return false;
    }
    return t->size() > 16;
  }

  void rewriteFunctionType(IrFuncTy &fty) override {
    if (!skipReturnValueRewrite(fty)) {
      auto dtype = DtoType(fty.ret->type);
      uint64_t retSize = gDataLayout->getTypeSizeInBits(dtype);
      // As for return values, they are returned in registers beginning
      // from a2 till a5.
      // If there are more than 4 values to be returned, the caller
      // passes a pointer which is then populated by callee with all the
      // return values.
      if (retSize > 32) {
        int retGRPsLeft = MaxNumRetGPRs;
        classifyArgument(*fty.ret, &retGRPsLeft);
      }
    }

    int argGPRsLeft = MaxNumArgGPRs;
    for (auto arg : fty.args) {
      if (!arg->byref) {
        classifyArgument(*arg, &argGPRsLeft);
      }
    }
  }

  void classifyArgument(IrFuncTyArg &arg, int *argGPRsLeft) {
    if (arg.byref) {
      return;
    }

    // non-PODs should be passed in memory
    if (!isPOD(arg.type)) {
      indirectByvalRewrite.applyTo(arg);
      return;
    }

    auto dtype = DtoType(arg.type);
    uint64_t size = gDataLayout->getTypeSizeInBits(dtype);
    uint64_t neededAlign = DtoAlignment(arg.type) * 8;
    int neededArgGPRs = (size + 1) / 32;

    if (neededAlign == 64) {
      neededArgGPRs += (*argGPRsLeft % 2);
    }

    if ((neededArgGPRs > *argGPRsLeft) ||
        (neededAlign > 128) ||
        ((*argGPRsLeft < 6) && (neededAlign == 128))) {
      indirectByvalRewrite.applyTo(arg);
    }
    *argGPRsLeft -= neededArgGPRs;
  }
};

// The public getter for abi.cpp
TargetABI *getXtensaTargetABI() { return new XtensaTargetABI(); }
