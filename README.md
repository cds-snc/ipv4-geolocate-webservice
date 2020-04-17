# IPv4 Geolocate Webservice

## Purpose

The purpose of this webservice is to translate IP v4 (ex. `23.233.63.149`) into a geographic location. 

## Example 

<img src="https://user-images.githubusercontent.com/62242/79569843-6794cf00-8086-11ea-8609-de72a19ecf58.png" alt="Notify login example" width="500">


## Rational

As part of the security features in our products, we present users with a list of recent locations that they have logged in from. To increase the information value for end users, we translate their IP address into a physical location. Ex:

```
Last login on Sunday, November 9th, 2019 20:15 EST from Ottawa, ON, using Firefox 71.
```

While many commercial API services exist that will do this for you, we should not be sharing our user's IP addresses with them. The data used in this service is updated weekly.

## Running it yourself

```
docker pull gcr.io/cdssnc/ipv4-geolocate-webservice:latest
docker run -p 8080:8080 ipv4-geolocate-webservice
```

## Usage
To geocode an IP address call the API in the following way: `https://ipv4-geolocate-webservice-dn42lmpbua-uc.a.run.app/23.233.63.149`
An example response is shown below.
```
{
   "city":{
      "geoname_id":6094817,
      "names":{
         "de":"Ottawa",
         "en":"Ottawa",
         "es":"Ottawa",
         "fr":"Ottawa",
         "ja":"オタワ",
         "pt-BR":"Otava",
         "ru":"Оттава"
      }
   },
   "continent":{
      "code":"NA",
      "geoname_id":6255149,
      "names":{
         "de":"Nordamerika",
         "en":"North America",
         "es":"Norteamérica",
         "fr":"Amérique du Nord",
         "ja":"北アメリカ",
         "pt-BR":"América do Norte",
         "ru":"Северная Америка",
         "zh-CN":"北美洲"
      }
   },
   "country":{
      "geoname_id":6251999,
      "is_in_european_union":null,
      "iso_code":"CA",
      "names":{
         "de":"Kanada",
         "en":"Canada",
         "es":"Canadá",
         "fr":"Canada",
         "ja":"カナダ",
         "pt-BR":"Canadá",
         "ru":"Канада",
         "zh-CN":"加拿大"
      }
   },
   "location":{
      "latitude":45.4166,
      "longitude":-75.6904,
      "metro_code":null,
      "time_zone":"America/Toronto"
   },
   "postal":{
      "code":"K2P"
   },
   "registered_country":{
      "geoname_id":6251999,
      "is_in_european_union":null,
      "iso_code":"CA",
      "names":{
         "de":"Kanada",
         "en":"Canada",
         "es":"Canadá",
         "fr":"Canada",
         "ja":"カナダ",
         "pt-BR":"Canadá",
         "ru":"Канада",
         "zh-CN":"加拿大"
      }
   },
   "represented_country":null,
   "subdivisions":[
      {
         "geoname_id":6093943,
         "iso_code":"ON",
         "names":{
            "en":"Ontario",
            "fr":"Ontario",
            "ja":"オンタリオ州",
            "pt-BR":"Ontário",
            "ru":"Онтарио",
            "zh-CN":"安大略"
         }
      }
   ],
   "traits":null
}
```

## Data
Data is provided in form of a binary database provided under a [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) license. It includes GeoLite2 data created by MaxMind, available from [https://www.maxmind.com](https://www.maxmind.com).

## Under the hood
The webservice is built using the Rust programming language because of it's ability to compile to a small static binary and the [performance characteristics](https://www.techempower.com/benchmarks/#section=data-r18&hw=ph&test=json) of the [Hyper](https://github.com/hyperium/hyper) web server. The docker container itself is only 68 MB big, with 61 MB making up the data. Currently the mean response time is `17.838 [ms]` in a dockerised server.

Local server:
```
Concurrency Level:      200
Time taken for tests:   7.100 seconds
Complete requests:      1000
Failed requests:        0
Total transferred:      1336000 bytes
HTML transferred:       1201000 bytes
Requests per second:    140.84 [#/sec] (mean)
Time per request:       1420.037 [ms] (mean)
Time per request:       7.100 [ms] (mean, across all concurrent requests)
Transfer rate:          183.75 [Kbytes/sec] received
```

Dockerised server:
```
Concurrency Level:      200
Time taken for tests:   17.838 seconds
Complete requests:      1000
Failed requests:        0
Total transferred:      1336000 bytes
HTML transferred:       1201000 bytes
Requests per second:    56.06 [#/sec] (mean)
Time per request:       3567.669 [ms] (mean)
Time per request:       17.838 [ms] (mean, across all concurrent requests)
Transfer rate:          73.14 [Kbytes/sec] received
```
