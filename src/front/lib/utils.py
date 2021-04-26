# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# Provides a set of utility functions to be called from the primary API
import os
import json
import re
from dominate.tags import *
from typing import Union

# Re-usable variable sets
env_match = re.compile("\${env:([0-9a-zA-Z_]+)}")

def dotted_write(prop_name: str, val: Union[int, str], target_dict: dict):
    """
    Purpose:  Function takes in a property value to be mapped that contains .'s in a string.
    These .'s are resolved to a position in the dictionary in which the value will be written.
    This function takes advantage of python's pass by value and embeds a value into an originating dictionary
    that will be re-jsonified and written back to it's location.

    :prop_name: a property value from a front end map dict
    :val:  the value to be written tot he target_dict
    :target_dict: the dictionary that the value will be written into
    """
    if "." in prop_name:
        write_name = "target_dict"
        nest_test = json.loads(json.dumps(target_dict))
        keys = prop_name.split(".")
        failed_test = False
        for loc in keys:
            if loc in nest_test:
                write_name += '["'+loc+'"]'
                nest_test = nest_test[loc]
            else:
                failed_test = True
        if not failed_test:
            exec(write_name + " = val")
    else:
        if prop_name in target_dict:
            target_dict[prop_name] = val


def find_config(dir_scan=['../core', '../modules'], extension=".front.json"):
    """
    Purpose: Function takes a list of directory names.  Performs an os.walk to find *.front.json files and returns a
    dictionary of file names and their contents.

     If .orig is in place on the file, it's removed.

    :dir_scan: the list of directories to be scanned.
    :extension: the extension to look for and return in the scan
    """
    config_files = {}
    for config_dir in dir_scan:
        walk = os.walk(os.path.join(os.getcwd(), config_dir))
        for root, _, files in walk:
            for f_name in files:
                if extension in f_name:
                    cur_file = os.path.join(root, f_name)
                    config_files[cur_file.replace(".orig", "")] = json.load(open(cur_file))

    return config_files


def build_form(form_doc: dict):
    """
    Purpose:  Function takes in a json document that describes a form, and returns the resulting dominate based
    form to be appended to the front end UI

    :form_doc: a dictionary derived from a loaded json
    """
    doc_form = form(id="terraform_config", action="/execute", method="post")
    doc_tabs = ul(cls="nav nav-tabs", id="myTab", role="tablist")
    doc_panels = div(cls="tab-content")
    for f_name, doc in form_doc.items():
        for title, config in doc.items():
            append_str = ""
            if "saca" in title:
                append_str = " active"
            doc_tabs.add(li(a(title, href="#" + title, cls="nav-link" + append_str, data_toggle="tab"), cls="nav-item",
                            role="presentation"))
            doc_panel = div(role="tabpanel", cls="tab-pane fade show custom-pane" + append_str, id=title)
            with doc_panel:
                for el_item in config["form"]:
                    with div(cls="form-elements"):
                        label(el_item["description"], cls="breadcrumb", label_for=el_item["varname"])
                        with div(cls="input-group input-group-sm mb-3"):
                            with div(cls="input-group-prepend"):
                                # Process environment options
                                if type(el_item["default_val"]) != bool:
                                    if "env:" in el_item["default_val"]:
                                        el_item["default_val"] = env_match.sub(environ_replace, el_item["default_val"])
                                span(el_item["varname"], cls="input-group-text")
                                if el_item["type"] == "text":
                                    input_(id=el_item["varname"], cls="form-control", value=el_item["default_val"], name=el_item["varname"])
                                elif el_item["type"] == "list":
                                    textarea("\n".join(el_item["default_val"]), id=el_item["varname"], cls="form-control", name="listinput:"+el_item["varname"], rows="4", columns="25")
                                elif el_item["type"] == "select":
                                    select((option(x, value=x) for x in el_item["options"]), cls="form-control",
                                               default=el_item["default_val"], name=el_item["varname"], id=el_item["varname"])
                                elif el_item["type"] == "boolean":
                                    span(
                                        input_(type="checkbox", default=bool(el_item["default_val"]), name=el_item["varname"], id=el_item["varname"])
                                        , cls="input-group-text")
            doc_panels.add(doc_panel)

    doc_form.add(doc_tabs)
    doc_form.add(doc_panels)

    with doc_form:
        input_(value="Execute Terraform", type="submit")

    return doc_form


def environ_replace(match_obj):
    """
    Purpose:  Iterate over the resulting match groups from a regex and return the matching environment variable
    form to be appended to the front end UI

    :form_doc: a dictionary derived from a loaded json
    """
    for x in match_obj.groups():
        return os.getenv(x)
