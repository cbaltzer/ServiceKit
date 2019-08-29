
FROM swift:latest

RUN apt-get update
RUN apt-get install -y --fix-missing libssl-dev

WORKDIR /sourcekit

COPY Package.swift ./
RUN swift package update

COPY Sources ./Sources
COPY Tests ./Tests

RUN swift test
RUN swift build --configuration release 

EXPOSE 5000
CMD [".build/release/Demo"]