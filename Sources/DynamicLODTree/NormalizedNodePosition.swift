//
//  NormalizedNodePosition.swift
//
// Copyright (c) 2019, Stefan Reinhold
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

public enum NormalizedNodePosition: UInt8, CaseIterable {
  case bottomLeft = 0, bottomRight, topLeft, topRight
}

public extension NormalizedNodePosition {
  var next: NormalizedNodePosition { NormalizedNodePosition(rawValue: (self.rawValue + 1) % 4)! }
  var isFirst: Bool { self == .bottomLeft }
  var isLast: Bool { self == .topRight }

  static var first: NormalizedNodePosition { NormalizedNodePosition(rawValue: 0)! }
}

/// Allow initializing an IntegerPosition2D type with a normalized node position
public extension IntegerPosition2D {
  init(_ pos: NormalizedNodePosition) {
    self.init(Scalar(pos.rawValue % 2), Scalar(pos.rawValue / 2))
  }
}
