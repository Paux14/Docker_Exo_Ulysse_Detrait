variable "VERSION" {
  default = "dev"
}

variable "GIT_SHA" {
  default = "unknown"
}

variable "REGISTRY" {
  default = "localhost:5000"
}

group "default" {
  targets = ["api", "worker"]
}

target "_common" {
  platforms = ["linux/amd64", "linux/arm64"]
  labels = {
    "org.opencontainers.image.version"  = VERSION
    "org.opencontainers.image.revision" = GIT_SHA
    "org.opencontainers.image.vendor"   = "Shop SAS"
  }
  args = {
    VERSION = VERSION
    GIT_SHA = GIT_SHA
  }
}

target "api" {
  inherits   = ["_common"]
  context    = "../TP1"
  tags       = ["${REGISTRY}/shop-api:${VERSION}"]
  cache-from = ["type=registry,ref=${REGISTRY}/cache:api"]
  cache-to   = ["type=registry,ref=${REGISTRY}/cache:api,mode=max"]
}

target "worker" {
  inherits   = ["_common"]
  context    = "shop-worker"
  secret     = ["id=pipconf,src=shop-worker/pip.conf"]
  tags       = ["${REGISTRY}/shop-worker:${VERSION}"]
  cache-from = ["type=registry,ref=${REGISTRY}/cache:worker"]
  cache-to   = ["type=registry,ref=${REGISTRY}/cache:worker,mode=max"]
}

target "worker-test" {
  inherits   = ["worker"]
  target     = "test"
  platforms  = ["linux/amd64"]
  tags       = []
  cache-to   = []
  output     = ["type=cacheonly"]
}
