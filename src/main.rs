#![deny(warnings)]
extern crate hyper;
extern crate maxminddb;
extern crate pretty_env_logger;
extern crate regex;
extern crate serde_json;

use hyper::{Body, Request, Response, Server, StatusCode};
use hyper::header::{CONTENT_ENCODING, CONTENT_TYPE, HeaderValue};
use hyper::service::service_fn_ok;
use hyper::rt::{self, Future};
use maxminddb::geoip2;
use regex::Regex;
use std::env;
use std::net::IpAddr;
use std::str::FromStr;

fn main() {
    pretty_env_logger::init();

    let port: u16 = env::var("PORT").unwrap_or("8080".to_string()).parse().unwrap();
    let addr = ([0, 0, 0, 0], port).into();

    let server = Server::bind(&addr)
        .serve(|| {
          service_fn_ok(move |req: Request<Body>| {

            let ip_str;
            let path = env::var("MMDB_PATH")
              .unwrap_or("./GeoLite2-City.mmdb".to_string());
            let reader = maxminddb::Reader::open_readfile(path).unwrap();
            let set = Regex::new(r#"/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"#).unwrap();
            let uri = req.uri().to_string();

            if uri == "/" {
              // TODO: Add in Remote IP
              ip_str = "127.0.0.1";
            } else if set.is_match(&uri) {
              ip_str = uri.trim_matches('/')
            } else {
              ip_str = "127.0.0.1";
            }
            
            let ip: IpAddr = FromStr::from_str(&ip_str).unwrap();
            let r = reader.lookup(ip);

            if let Err(_err) = r {
              let mut resp = Response::new(Body::from("{\"error\": \"No information found\"}"));
              resp.headers_mut().insert(CONTENT_ENCODING, HeaderValue::from_static("utf-8"));
              resp.headers_mut().insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
              *resp.status_mut() = StatusCode::NOT_FOUND;
              return resp
            } else {
              let city: geoip2::City = r.unwrap();
              let mut resp = Response::new(Body::from(serde_json::to_string(&city).unwrap()));
              resp.headers_mut().insert(CONTENT_ENCODING, HeaderValue::from_static("utf-8"));
              resp.headers_mut().insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
              return resp
            }
          })
        })
        .map_err(|e| eprintln!("server error: {}", e));

    println!("Listening on http://{}", addr);

    rt::run(server);
}
