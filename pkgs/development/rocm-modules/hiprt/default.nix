{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  clr,
  python3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hiprt";
  version = "2.5.a21e075.3";

  src = fetchFromGitHub {
    owner = "GPUOpen-LibrariesAndSDKs";
    repo = "HIPRT";
    tag = finalAttrs.version;
    sha256 = "sha256-3yGhwIsFHlFMCEzuYnXuXNzs99m7f2LTkYaTGs0GEcI=";
  };

  # FIXME: hiprt> failed to execute: clang++  --offload-arch=gfx1100 --offload-arch=gfx1101 --offload-arch=gfx1102 --offload-arch=gfx1103 --offload-arch=gfx1030 --offload-arch=gfx1031 --offload-arch=gfx1032 --offload-arch=gfx1033 --offload-arch=gfx1034 --offload-arch=gfx1035 --offload-arch=gfx1036 --offload-arch=gfx1010 --offload-arch=gfx1011 --offload-arch=gfx1012 --offload-arch=gfx1013 --offload-arch=gfx900 --offload-arch=gfx902 --offload-arch=gfx904 --offload-arch=gfx906 --offload-arch=gfx908 --offload-arch=gfx909 --offload-arch=gfx90a --offload-arch=gfx90c --offload-arch=gfx940 --offload-arch=gfx941 --offload-arch=gfx942 --offload-arch=gfx1152 --offload-arch=gfx1200 --offload-arch=gfx1201 --offload-arch=gfx1150 --offload-arch=gfx1151 --hip-device-lib-path="/nix/store/plm56xq6khrs7b0xv3gwip70l8cqw8yr-rocm-device-libs-7.0.1/amdgcn/bitcode"  -x hip ../../hiprt/impl/hiprt_kernels_bitcode.h -O3 -std=c++17 -fgpu-rdc -c --gpu-bundle-output -c -emit-llvm -I../../contrib/Orochi/ -I../../ -DHIPRT_BITCODE_LINKING -ffast-math -parallel-jobs=15 -o "hiprt02005_7.0_amd_lib_linux.bc"

  postPatch = ''
    rm -rf contrib/easy-encrypt # contains prebuilt easy-encrypt binaries, we disable encryption
    substituteInPlace contrib/Orochi/contrib/hipew/src/hipew.cpp --replace-fail '"/opt/rocm/hip/lib/' '"${clr}/lib'
    substituteInPlace hiprt/hiprt_libpath.h --replace-fail '"/opt/rocm/hip/lib/' '"${clr}/lib/'
  '';

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    clr
  ];

  cmakeFlags = [
    (lib.cmakeBool "BAKE_KERNEL" false)
    (lib.cmakeBool "BAKE_COMPILED_KERNEL" false)
    (lib.cmakeBool "BITCODE" true)
    (lib.cmakeBool "PRECOMPILE" true)
    # needs accelerator
    (lib.cmakeBool "NO_UNITTEST" true)
    # we have no need to support baking encrypted kernels into object files
    (lib.cmakeBool "NO_ENCRYPT" true)
    (lib.cmakeBool "FORCE_DISABLE_CUDA" true)
  ];

  postInstall = ''
    mv $out/bin $out/lib
    ln -sr $out/lib/libhiprt*64.so $out/lib/libhiprt64.so
    install -v -Dm644 ../scripts/bitcodes/hiprt*_amd_lib_linux.bc $out/lib/
  '';

  meta = {
    homepage = "https://gpuopen.com/hiprt";
    description = "Ray tracing library for HIP";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      mksafavi
    ];
    teams = [ lib.teams.rocm ];
    platforms = lib.platforms.linux;
  };
})
