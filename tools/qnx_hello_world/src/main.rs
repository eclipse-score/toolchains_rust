/********************************************************************************
* Copyright (c) 2025 Contributors to the Eclipse Foundation
*
* See the NOTICE file(s) distributed with this work for additional
* information regarding copyright ownership.
*
* This program and the accompanying materials are made available under the
* terms of the Apache License Version 2.0 which is available at
* https://www.apache.org/licenses/LICENSE-2.0
*
* SPDX-License-Identifier: Apache-2.0
********************************************************************************/

use axum::{response::Html, routing::get, Router};

// By using tokio and axum in this simpel example we can check that
// quite a lot of concepts and libraries (async, tokio runtime, network stack, axum)
// are actually working and there does not seem to be a huge immediate red
// flag for using rust on qnx. Also, building HTTP services with C++ is a pita,
// so being able to do that with Rust is an immediate win on QNX!
#[tokio::main]
async fn main() {
    // Build a simple application with a route
    let app = Router::new().route("/", get(handler));

    // Bind to port 3000 on all devices
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();

    // Ready to listen
    println!("listening on {}", listener.local_addr().unwrap());

    // Actually serve requests
    axum::serve(listener, app).await.unwrap();
}

async fn handler() -> Html<&'static str> {
    println!("responding to request");
    Html("<h1>Hello Eclipse! Rust on QNX is Fun!</h1>")
}
