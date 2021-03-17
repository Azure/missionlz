# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# Provides a set of utility functions to be called from the primary API
import os
import json
from dominate.tags import *

def dotted_write(prop_name, val, target_dict):
    """
    Purpose:  Function takes in a property value to be mapped that contains .'s in a string.
    These .'s are resolved to a position in the dictionary in which the value will be written.
    This function takes advantage of python's pass by value and embeds a value into an originating dictionary
    that will be re-jsonified and written back to it's location.

    prop_name: a property value from a front end map dict
    val:  the value to be written tot he target_dict
    target_dict: the dictionary that the value will be written into
    """

    if prop_name.contains("."):
        pass

def find_config(dir_scan=['core', 'modules'], extension=".front.json"):
    """
    Purpose: Function takes a list of directory names.  Performs an os.walk to find *.front.json files and returns a
    dictionary of file names and their contents.

    dir_scan: the list of directories to be scanned.
    extension: the extension to look for and return in the scan
    """
    config_files = {}
    for config_dir in dir_scan:
        walk = os.walk(os.join(os.getcwd(), config_dir))
        for root, _, files in walk:
            for f_name in files:
                if extension in f_name:
                    cur_file = os.join(root, name)
                    config_files["cur_file"] = json.load(cur_file)

    return config_files


def dotted_build_form(form_doc):
    """
    Purpose:  Function takes in a json document that describes a form, and returns the resulting dominate based
    form to be appended to the front end UI

    form_doc: a dictionary derived from a loaded json
    """
    pass