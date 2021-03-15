# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# Provides a set of utility functions to be called from the primary API

# Resolves a dotted property name to a target in a dictionary
# Will step through and create parent branches if they don't exist
def dotted_write(prop_name, target_dict):
    if prop_name.contains("."):
        pass

