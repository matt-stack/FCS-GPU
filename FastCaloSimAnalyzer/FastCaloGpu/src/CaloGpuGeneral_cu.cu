/*
  Copyright (C) 2002-2021 CERN for the benefit of the ATLAS collaboration
*/

#include "CaloGpuGeneral_cu.h"
#include "GeoRegion.h"
#include "GeoGpu_structs.h"
#include "Hit.h"
#include "Rand4Hits.h"

#include "gpuQ.h"
#include "Args.h"
#include <chrono>

#ifdef USE_KOKKOS
#include <Kokkos_Core.hpp>
#include <Kokkos_Random.hpp>
#endif

#define BLOCK_SIZE 256

#define M_PI 3.14159265358979323846
#define M_2PI 6.28318530717958647692

static CaloGpuGeneral::KernelTime timing;
static bool first{true};

using namespace CaloGpuGeneral_fnc;

namespace CaloGpuGeneral_cu {

  __global__ void simulate_A( float E, int nhits, Chain0_Args args ) {

    long t = threadIdx.x + blockIdx.x * blockDim.x;
    if ( t < nhits ) {
      Hit hit;
      hit.E() = E;
      CenterPositionCalculation_d( hit, args );
      HistoLateralShapeParametrization_d( hit, t, args );
      HitCellMappingWiggle_d( hit, args, t );
    }
  }

  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  __global__ void simulate_ct( Chain0_Args args ) {

    unsigned long tid = threadIdx.x + blockIdx.x * blockDim.x;
    if ( tid < args.ncells ) {
      if ( args.cells_energy[tid] > 0 ) {
        unsigned int ct = atomicAdd( args.hitcells_ct, 1 );
        Cell_E       ce;
        ce.cellid           = tid;
        ce.energy           = args.cells_energy[tid];
        args.hitcells_E[ct] = ce;
      }
    }
  }

  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  __global__ void simulate_clean( Chain0_Args args ) {
    unsigned long tid = threadIdx.x + blockIdx.x * blockDim.x;
    if ( tid < args.ncells ) { args.cells_energy[tid] = 0.0; }
    if ( tid == 0 ) args.hitcells_ct[0] = 0;
  }

  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  __host__ void simulate_A_cu( float E, int nhits, Chain0_Args& args ) {
    int blocksize   = BLOCK_SIZE;
    int threads_tot = nhits;
    int nblocks     = ( threads_tot + blocksize - 1 ) / blocksize;
    simulate_A<<<nblocks, blocksize>>>( E, nhits, args );
  }

  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  __host__ void simulate_hits( float E, int nhits, Chain0_Args& args ) {

    cudaError_t err = cudaGetLastError();

    unsigned long ncells      = args.ncells;
    int           blocksize   = BLOCK_SIZE;
    int           threads_tot = args.ncells;
    int           nblocks     = ( threads_tot + blocksize - 1 ) / blocksize;

    auto t0 = std::chrono::system_clock::now();
    simulate_clean<<<nblocks, blocksize>>>( args );
    gpuQ( cudaGetLastError() );
    gpuQ( cudaDeviceSynchronize() );
    
    blocksize   = BLOCK_SIZE;
    threads_tot = nhits;
    nblocks     = ( threads_tot + blocksize - 1 ) / blocksize;

    auto t1 = std::chrono::system_clock::now();
    simulate_A<<<nblocks, blocksize>>>( E, nhits, args );
    gpuQ( cudaGetLastError() );
    gpuQ( cudaDeviceSynchronize() );

    nblocks = ( ncells + blocksize - 1 ) / blocksize;
    auto t2 = std::chrono::system_clock::now();
    simulate_ct<<<nblocks, blocksize>>>( args );
    gpuQ( cudaGetLastError() );
    gpuQ( cudaDeviceSynchronize() );
    
    int ct;
    auto t3 = std::chrono::system_clock::now();
    gpuQ( cudaMemcpy( &ct, args.hitcells_ct, sizeof( int ), cudaMemcpyDeviceToHost ) );
    gpuQ( cudaMemcpy( args.hitcells_E_h, args.hitcells_E, ct * sizeof( Cell_E ), cudaMemcpyDeviceToHost ) );

    auto t4 = std::chrono::system_clock::now();
    // pass result back
    args.ct = ct;


    CaloGpuGeneral::KernelTime kt( t1 - t0, t2 - t1, t3 - t2, t4 - t3 );
    if (first) {
      first = false;
    } else {
      timing += kt;
    }
    
  }

  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

  __host__ void Rand4Hits_finish( void* rd4h ) {
    if ( (Rand4Hits*)rd4h ) delete (Rand4Hits*)rd4h;

    if (timing.count > 0) {
      std::cout << "kernel timing\n";
      std::cout << timing;
    } else {
      std::cout << "no kernel timing available" << std::endl;
    }
  }


} // namespace CaloGpuGeneral_cu
