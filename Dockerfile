FROM golang:1.15.2 AS base
WORKDIR /src
COPY dependencies dependencies
COPY go.mod go.sum ./
RUN go mod download

FROM base AS build
ARG TARGETOS
ARG TARGETARCH
ARG IMG_RELEASE
RUN mkdir -p /config/
COPY . .
RUN IMG_VERSION=${IMG_RELEASE} \
    GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    COMPILE_OUTPUT="/out/otelcol-custom-istio-awsxray" \
    make compile

FROM alpine:latest as certs
RUN apk --update add ca-certificates

FROM scratch AS bin
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /out/otelcol-custom-istio-awsxray /app/otelcol-custom-istio-awsxray
COPY --from=build /config/ /config/

ENTRYPOINT ["/app/otelcol-custom-istio-awsxray"]
CMD ["--config", "/config/config.yaml"]
