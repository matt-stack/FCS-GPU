// Copyright (C) 2002-2020 CERN for the benefit of the ATLAS collaboration

#ifndef FASTCALOSYCL_SIMHIT_H_
#define FASTCALOSYCL_SIMHIT_H_

#include <FastCaloSycl/SimHit.h>

#include <CL/sycl.hpp>

class SimHit {
 public:
  SimHit()
      : eta_x_(0.0),
        phi_y_(0.0),
        z_(0.0),
        energy_(0.0),
        is_fcal_(false),
        center_r_(0.0),
        center_z_(0.0),
        center_eta_(0.0),
        center_phi_(0.0) {}

  SimHit(float eta, float phi, float energy)
      : eta_x_(eta),
        phi_y_(phi),
        z_(0.0),
        energy_(energy),
        is_fcal_(false),
        center_r_(0.0),
        center_z_(0.0),
        center_eta_(0.0),
        center_phi_(0.0) {}
  SimHit(float x, float y, float z, float energy)
      : eta_x_(x),
        phi_y_(y),
        z_(z),
        energy_(energy),
        is_fcal_(true),
        center_r_(0.0),
        center_z_(0.0),
        center_eta_(0.0),
        center_phi_(0.0) {}

  ~SimHit() {}

  SYCL_EXTERNAL inline void set_be_hit(float eta, float phi, float z,
                                       float energy) {
    eta_x_ = eta;
    phi_y_ = phi;
    z_ = z;
    energy_ = energy;
    is_fcal_ = false;
  }
  SYCL_EXTERNAL inline void set_fcal_hit(float x, float y, float z,
                                         float energy) {
    eta_x_ = x;
    phi_y_ = y;
    z_ = z;
    energy_ = energy;
    is_fcal_ = true;
  }
  inline void reset() {
    eta_x_ = 0.0;
    phi_y_ = 0.0;
    z_ = 0.0;
    energy_ = 0.0;
    is_fcal_ = false;
    center_r_ = 0.0;
    center_z_ = 0.0;
    center_eta_ = 0.0;
    center_phi_ = 0.0;
  }
  SYCL_EXTERNAL inline float eta() { return eta_x_; }
  SYCL_EXTERNAL inline float phi() { return phi_y_; }
  SYCL_EXTERNAL inline float x() { return eta_x_; }
  SYCL_EXTERNAL inline float y() { return phi_y_; }
  SYCL_EXTERNAL inline float z() { return z_; }
  SYCL_EXTERNAL inline float E() { return energy_; }
  SYCL_EXTERNAL inline float r() {
    if (is_fcal_) {
      return cl::sycl::sqrt(eta_x_ * eta_x_ + phi_y_ * phi_y_);
    } else {
      return z_ / cl::sycl::sinh(eta_x_);
    }
  }
  SYCL_EXTERNAL inline void set_E(float energy) { energy_ = energy; }
  SYCL_EXTERNAL inline void set_phi(float phi) { phi_y_ = phi; }
  SYCL_EXTERNAL inline void set_center_r(float r) { center_r_ = r; }
  SYCL_EXTERNAL inline void set_center_z(float z) { center_z_ = z; }
  SYCL_EXTERNAL inline void set_center_eta(float eta) { center_eta_ = eta; }
  SYCL_EXTERNAL inline void set_center_phi(float phi) { center_phi_ = phi; }
  SYCL_EXTERNAL inline float center_r() { return center_r_; }
  SYCL_EXTERNAL inline float center_z() { return center_z_; }
  SYCL_EXTERNAL inline float center_eta() { return center_eta_; }
  SYCL_EXTERNAL inline float center_phi() { return center_phi_; }

 private:
  float eta_x_;  // eta in barrel and end-caps; x in FCal
  float phi_y_;  // phi in barrel and end-caps; y in FCal
  float z_;
  float energy_;
  bool is_fcal_;  // Working in Cartesian coordinates or not
  // Variables for extrapolated position
  float center_r_;
  float center_z_;
  float center_eta_;
  float center_phi_;
};
#endif  // FASTCALOSYCL_SIMHIT_H_
