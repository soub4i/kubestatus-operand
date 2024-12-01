

FROM golang:1.21.1-alpine AS builder
LABEL maintainer="Abderrahim Soubai-Elidrisi | @soub4i"
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /kubestatus-server


FROM gcr.io/distroless/base-debian10
WORKDIR /
COPY --from=builder /kubestatus-server /kubestatus-server
COPY --from=builder /app/static /static


EXPOSE 8080
ENTRYPOINT ["/kubestatus-server"]
