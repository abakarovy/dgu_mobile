// Copyright 2023, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import <Foundation/Foundation.h>

// Исходный файл был пустым (только комментарий) — линковщик предупреждал: dummy.o has no symbols.
// Одна неиспользуемая, но «used» символ-якорь убирает предупреждение, не меняя поведение плагина.
__attribute__((used)) void firebase_core_ios_dummy_anchor_symbol(void) {}
