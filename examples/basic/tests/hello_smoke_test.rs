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

use std::path::{Path, PathBuf};
use std::process::Command;

fn find_hello_binary() -> PathBuf {
    // 1. Check direct relative paths (standard when cwd is workspace root or /persistent/unit_tests in QNX VM)
    let direct_paths = [
        PathBuf::from("examples/basic/hello"),
        PathBuf::from("./examples/basic/hello"),
    ];
    for p in &direct_paths {
        if p.is_file() {
            return p.clone();
        }
    }

    // 2. Check Bazel TEST_SRCDIR runfiles
    if let Ok(srcdir) = std::env::var("TEST_SRCDIR") {
        for prefix in &["score_toolchains_rust", "_main", ""] {
            let candidate = Path::new(&srcdir)
                .join(prefix)
                .join("examples/basic/hello");
            if candidate.is_file() {
                return candidate;
            }
        }
    }

    // 3. Check Bazel RUNFILES_DIR
    if let Ok(runfiles) = std::env::var("RUNFILES_DIR") {
        for prefix in &["score_toolchains_rust", "_main", ""] {
            let candidate = Path::new(&runfiles)
                .join(prefix)
                .join("examples/basic/hello");
            if candidate.is_file() {
                return candidate;
            }
        }
    }

    // 4. Sibling directory of current test executable
    if let Ok(mut current) = std::env::current_exe() {
        current.pop();
        let candidate = current.join("hello");
        if candidate.is_file() {
            return candidate;
        }
    }

    panic!("Could not locate the :hello binary in runfiles or working directory");
}

#[test]
fn test_hello_world_execution() {
    let hello_path = find_hello_binary();
    println!("Executing binary: {}", hello_path.display());

    let output = Command::new(&hello_path)
        .output()
        .unwrap_or_else(|err| panic!("Failed to execute {:?}: {}", hello_path, err));

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    println!("--- Captured stdout ---\n{stdout}");
    if !stderr.is_empty() {
        println!("--- Captured stderr ---\n{stderr}");
    }

    assert!(
        output.status.success(),
        "Binary {:?} exited with non-zero status: {:?}",
        hello_path,
        output.status
    );

    assert!(
        stdout.contains("Hello, World from QNX AArch64!"),
        "stdout did not contain expected greeting 'Hello, World from QNX AArch64!'. Got:\n{stdout}"
    );

    assert!(
        stdout.contains("0 is zero") && stdout.contains("1 is positive") && stdout.contains("-1 is negative"),
        "stdout did not contain expected classification output. Got:\n{stdout}"
    );
}
