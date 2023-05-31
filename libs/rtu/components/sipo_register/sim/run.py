#!/usr/bin/env python3
from vunit import VUnit

# create VUnit project
prj = VUnit.from_argv()

# add OSVVM library
prj.add_osvvm()
prj.add_verification_components()

# add custom libraries
prj.add_library("rtu")
prj.add_library("rtu_test")

# add sources and testbenches
prj.library("rtu").add_source_file("../src/sipo_register.vhd")
prj.library("rtu").add_source_file("../tb/tb.vhd")
prj.library("rtu").add_source_file("../../../../rtu/pkg/data_types.vhd")

#prj.library("rtu").test_bench("tb").test("randomized").add_config(
#    name="data_width=8",
#    generics=dict(
#      DATA_WIDTH = 8,
#      RANDOMIZED_TEST_COUNT = 100))
#
#prj.library("rtu").test_bench("tb").test("randomized").add_config(
#    name="data_width=9",
#    generics=dict(
#      DATA_WIDTH = 9,
#      RANDOMIZED_TEST_COUNT = 100))
#
#prj.library("rtu").test_bench("tb").test("randomized").add_config(
#    name="data_width=10",
#    generics=dict(
#      DATA_WIDTH = 10,
#      RANDOMIZED_TEST_COUNT = 100))

# run VUnit simulation
prj.main()
