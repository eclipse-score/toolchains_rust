// *******************************************************************************
// Copyright (c) 2026 Contributors to the Eclipse Foundation
//
// See the NOTICE file(s) distributed with this work for additional
// information regarding copyright ownership.
//
// This program and the accompanying materials are made available under the
// terms of the Apache License Version 2.0 which is available at
// <https://www.apache.org/licenses/LICENSE-2.0>
//
// SPDX-License-Identifier: Apache-2.0
// *******************************************************************************

//! Tiny example crate used to smoke-test the Ferrocene toolchains.
//!
//! `classify` deliberately contains multiple branches so that the coverage
//! smoke test produces per-branch data, not just straight-line execution.

/// Classifies an integer as `"negative"`, `"zero"` or `"positive"`.
pub fn classify(n: i32) -> &'static str {
    if n < 0 {
        "negative"
    } else if n == 0 {
        "zero"
    } else {
        "positive"
    }
}

#[cfg(test)]
mod tests {
    use super::classify;

    #[test]
    fn classifies_all_branches() {
        assert_eq!(classify(-5), "negative");
        assert_eq!(classify(0), "zero");
        assert_eq!(classify(42), "positive");
    }
}
