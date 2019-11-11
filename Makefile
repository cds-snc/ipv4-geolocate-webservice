now=$(shell date +"%Y-%m-%d")

build:
	docker build -t gcr.io/cdssnc/ipv4-geolocate-webservice:latest -t gcr.io/cdssnc/ipv4-geolocate-webservice:${now} .

push:
	docker push gcr.io/cdssnc/ipv4-geolocate-webservice:latest &&\
	docker push gcr.io/cdssnc/ipv4-geolocate-webservice:${now}