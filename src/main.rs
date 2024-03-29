#![deny(warnings)]

use std::env;

use std::convert::Infallible;
use std::net::SocketAddr;
use std::sync::Arc;

use http_body_util::Full;
use hyper::{ Request, Response, StatusCode };
use hyper::header::{ CONTENT_ENCODING, CONTENT_TYPE, HeaderValue };
use hyper::body::Bytes;
use hyper::server::conn::http1;
use hyper::service::service_fn;
use hyper_util::rt::TokioIo;
use maxminddb::{ geoip2, Reader };
use regex::Regex;
use std::str::FromStr;
use std::net::IpAddr;
use tokio::net::TcpListener;

async fn location(
    req: Request<hyper::body::Incoming>,
    reader: Arc<Reader<Vec<u8>>>
) -> Result<Response<Full<Bytes>>, Infallible> {
    let uri = req.uri().to_string();
    let set = Regex::new(r#"/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"#).unwrap();
    let ip_str;

    if uri == "/" {
        // TODO: Add in Remote IP
        ip_str = "127.0.0.1";
    } else if set.is_match(&uri) {
        ip_str = uri.trim_matches('/');
    } else {
        ip_str = "127.0.0.1";
    }

    let ip: IpAddr = FromStr::from_str(&ip_str).unwrap();
    let result: Result<geoip2::City<'_>, maxminddb::MaxMindDBError> = reader.lookup(ip);

    if let Err(_err) = result {
        let resp: Response<Full<Bytes>> = create_response(
            "{\"error\": \"No information found\"}".to_owned(),
            StatusCode::NOT_FOUND
        );

        return Ok(resp);
    } else {
        let city: geoip2::City = result.unwrap();
        let json = serde_json::to_string(&city).unwrap();
        let resp: Response<Full<Bytes>> = create_response(json, StatusCode::OK);

        return Ok(resp);
    }
}

fn create_response(body: String, status: StatusCode) -> Response<Full<Bytes>> {
    let byte_body = Bytes::from(body);
    let mut response = Response::new(Full::new(byte_body));
    *response.status_mut() = status;
    response.headers_mut().insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
    response.headers_mut().insert(CONTENT_ENCODING, HeaderValue::from_static("utf-8"));
    response
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    pretty_env_logger::init();

    let port: u16 = env::var("PORT").unwrap_or("8080".to_string()).parse().unwrap();
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = TcpListener::bind(addr).await?;
    println!("Listening on http://{}", addr);

    let path = env::var("MMDB_PATH").unwrap_or("./GeoLite2-City.mmdb".to_string());
    let reader = maxminddb::Reader::open_readfile(path.clone()).unwrap();
    let reader = Arc::new(reader);
    println!("Loaded maxmind city locations database from {}.", path);

    loop {
        let (stream, _) = listener.accept().await?;

        // Use an adapter to access something implementing `tokio::io` traits as if they implement
        // `hyper::rt` IO traits.
        let io = TokioIo::new(stream);
        let reader_clone = Arc::clone(&reader);

        // Spawn a tokio task to serve multiple connections concurrently
        tokio::task::spawn(async move {
            // Finally, we bind the incoming connection to our services
            if
                let Err(err) = http1::Builder::new().serve_connection(
                    io,
                    service_fn(move |req| location(req, Arc::clone(&reader_clone)))
                ).await
            {
                println!("Error serving connection: {:?}", err);
            }
        });
    }
}
