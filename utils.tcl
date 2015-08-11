package provide IxUtils  1.0

####################################################################################################
# utils.tcl--
#   This file implements some util functions for IxRepository.
#
# Copyright (c) Ixia technologies, Inc.
# Change made
# Version 1.0
# Judo Xu-- Create
#################################################################################################### 

namespace eval IXIA {
    #--
    # Simulate the Enumeration type in TCL 
    #--
    # Parameters:
    #       name: Enumeration veriable name
    #       values: Enmeration values
    # Return:
    #       None
    #--
    proc enum {name values} {
        interp alias {} $name: {} lsearch $values
        interp alias {} $name@ {} lindex $values
    }
}