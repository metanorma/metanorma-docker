# Single source of truth for every version and digest this repository
# consumes. The Makefile includes this file; the Dockerfiles and CI
# workflows parse it with `cut -d' ' -f3` (keep the `KEY := value` shape).

# Image version: tracks the metanorma-cli release (metanorma/metanorma-cli),
# written by the release-tag workflow.
IMAGE_VERSION := 1.17.0

# Tebako toolchain (tamatebako/tebako GitHub release, without the "v" prefix).
TEBAKO_VERSION := 2.8.22

# Tebako CLI binary digests (release SHA256SUMS, asset tebako-<ver>-<triple>).
TEBAKO_CLI_SHA256_GNU_X86_64 := 63d1086dfe74887246aeb1e00ecbed53d1e183777026ae6bfba10808d1b37010
TEBAKO_CLI_SHA256_GNU_ARM64 := fc5f6c2f243c55b6c466bc62c0c85591ae1c5c188a8f3d66c84e468ebd42427b
TEBAKO_CLI_SHA256_MUSL_X86_64 := aaf87f0c2750efea535b439a77698cd2ceb675a28f749dc37de9ac9982d6c09e
TEBAKO_CLI_SHA256_MUSL_ARM64 := 726b7f1254cfe28dbd82e07e252cfc781cc6da3814b6e612b324d481e466c2d2

# Tebako dispatcher binary digests (asset tebako-shim-<ver>-<triple>).
TEBAKO_SHIM_SHA256_GNU_X86_64 := 5edbc39a5f3a85da4bd6f16f391bafb1b3343fa1341ae71b9106846249ba2257
TEBAKO_SHIM_SHA256_GNU_ARM64 := c03aaf44e3c9a358f23cc0a36971cc677f3abc30e31ea5939030ba55c4abcf85
TEBAKO_SHIM_SHA256_MUSL_X86_64 := 21e480a0630b6c3c7d5e74930ca43328f6c6e40df606541f39a2eae7ba399285
TEBAKO_SHIM_SHA256_MUSL_ARM64 := 4b021db9d05727a26f94b070ee7e5470c73cf8a3ce7dddba2b6bf0ea14736b22

# Payload pins (tebako-packages/* registries; digests are the registry's
# per-triplet sha256 anchors, asserted against the store after install).
METANORMA_VERSION := 1.17.0
METANORMA_SHA256_GNU_X86_64 := a8967b6527027d46c4d1ec63fe48adf9224fa0605a4a948c0c1600441e16912b
METANORMA_SHA256_GNU_ARM64 := 2aa1f29a9e04b9c6e6a9d6ccfe2fb3f77e64eafc60df7a937f67895bc02bd8ca
METANORMA_SHA256_MUSL_X86_64 := 773d9c73e1c7d85a1b36a36e162341bc8e9e8f64d9b34ac83d0ca2bb130950dc
METANORMA_SHA256_MUSL_ARM64 := 01f782b645a2ea023d49b899f4cb03b1293668748cea4b594f53a1ef72584140

INKSCAPE_VERSION := 1.4.3
XML2RFC_VERSION := 3.34.1
