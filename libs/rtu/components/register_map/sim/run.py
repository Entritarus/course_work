#!/usr/bin/env python3
from vunit import VUnit
import glob

# create VUnit project
prj = VUnit.from_argv()

# add OSVVM library
prj.add_osvvm()
prj.add_verification_components()

# add all source files using glob
for lib in ["rtu", "rtu_test", "edi"]:
  # add library
  prj.add_library(lib)

  # glob paths
  glob_path_packages   = "../../../../" + lib + "/pkg/*"
  glob_path_components = "../../../../" + lib + "/components/*/src/*.vhd"

  # add packages
  for pkg in glob.glob(glob_path_packages):
    prj.library(lib).add_source_file(pkg)

  # add components
  for component in glob.glob(glob_path_components):
    prj.library(lib).add_source_file(component)


# add testbench
prj.library("rtu").add_source_file("../tb/tb.vhd")

prj.library("rtu").test_bench("tb").add_config(
  name="RC=4;DW=8",
  generics=dict(
    REGISTER_COUNT = 4,
    DATA_WIDTH = 8))

prj.library("rtu").test_bench("tb").add_config(
  name="RC=7;DW=10",
  generics=dict(
    REGISTER_COUNT = 7,
    DATA_WIDTH = 10))


# run VUnit simulation
prj.main()
