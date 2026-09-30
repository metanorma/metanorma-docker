# Single source of truth for every version and digest this repository
# consumes. The Makefile includes this file; the Dockerfiles and CI
# workflows parse it with `cut -d' ' -f3` (keep the `KEY := value` shape).

# Image version: tracks the metanorma-cli release (metanorma/metanorma-cli),
# written by the release-tag workflow.
IMAGE_VERSION := 1.17.0

# Tebako toolchain (tamatebako/tebako GitHub release, without the "v" prefix).
TEBAKO_VERSION := 2.8.23

# Tebako CLI binary digests (release SHA256SUMS, asset tebako-<ver>-<triple>).
TEBAKO_CLI_SHA256_GNU_X86_64 := f4ab9222c94c9d73fe4ea8cfac19e4176e3ebd1ebe3ded5a101aad3e4499529e
TEBAKO_CLI_SHA256_GNU_ARM64 := 84ba99c0c2a7c48ae122034bcb42d03877cb4ff7cbb39750f02a711f83759a80
TEBAKO_CLI_SHA256_MUSL_X86_64 := cfc1f8feca8ff74f5601a32568dcfce155ee0aa6e932ede01efbc39e0e10c2d7
TEBAKO_CLI_SHA256_MUSL_ARM64 := 2982f51fc5f5bccd851a5a2bb399325fcaec80f8bdcb2ca3230874db435bf0d0

# Tebako dispatcher binary digests (asset tebako-shim-<ver>-<triple>).
TEBAKO_SHIM_SHA256_GNU_X86_64 := 8b4b51aac3d692d6c9b7e5cc65da368d7085cf9cc735970b13bf74d54e5bbbf8
TEBAKO_SHIM_SHA256_GNU_ARM64 := 8c620e14779edcafa4a348a8c044c9093f8fdef4ac2907505409c9ccd6d9a4e3
TEBAKO_SHIM_SHA256_MUSL_X86_64 := 8a39a84777db4f4f191c1b4ea8fe9e7e5bdc6a4870d7b4aca78da66869d87f03
TEBAKO_SHIM_SHA256_MUSL_ARM64 := 3f5ec323c3c2e22063b85290f47f3d08db8e6de1979c502b38d9cb9112d29d01

# Payload pins (tebako-packages/* registries; digests are the registry's
# per-triplet sha256 anchors, asserted against the store after install).
METANORMA_VERSION := 1.17.0
METANORMA_SHA256_GNU_X86_64 := a8967b6527027d46c4d1ec63fe48adf9224fa0605a4a948c0c1600441e16912b
METANORMA_SHA256_GNU_ARM64 := 2aa1f29a9e04b9c6e6a9d6ccfe2fb3f77e64eafc60df7a937f67895bc02bd8ca
METANORMA_SHA256_MUSL_X86_64 := 773d9c73e1c7d85a1b36a36e162341bc8e9e8f64d9b34ac83d0ca2bb130950dc
METANORMA_SHA256_MUSL_ARM64 := 01f782b645a2ea023d49b899f4cb03b1293668748cea4b594f53a1ef72584140

INKSCAPE_VERSION := 1.4.3
XML2RFC_VERSION := 3.34.1
