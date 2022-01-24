# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
A command-line utility for validating that
a given Declarative Form Portal UI JSON template contains outputs that
map to a given ARM Deployment Template JSON template input parameters
"""

import argparse
import json
from os import path
import sys


def main():
    """
    Parses arguments, loads JSON into memory, executes form validation
    """

    form_path, template_path = parse_args()

    print(f"Validating that Declarative Form UI template outputs from {form_path} "
          f"map to the ARM deployment template parameters at {template_path}...",
          file=sys.stdout)

    validate_paths(form_path, template_path)

    form = load_json(form_path)
    template = load_json(template_path)

    validate_form(form, template)

    print("Success!", file=sys.stdout)

    sys.exit(0)


def parse_args():
    """
    Parses arguments to return file paths for
    the deployment template (e.g. azuredeploy.json)
    and the Declarative Form UI template.

    See https://docs.python.org/3.11/howto/argparse.html for an example.

    Returns:
        - form_path (string)
        - template_path (string)
    """

    parser = argparse.ArgumentParser(
        description="Validate that Declarative Form UI template outputs "
                    "map to ARM deployment template parameters")

    parser.add_argument("form_path",
                        help="the path to the Declarative Form UI template JSON file")

    parser.add_argument("template_path",
                        help="the path to the ARM deployment template JSON file")

    args = parser.parse_args()

    return args.form_path, args.template_path


def validate_paths(*args):
    """
    Validates that files exist at a given path.
    If a file does not exist at the path, prints a message to stderr and exits code 1
    """
    for file_path in args:
        if not path.isfile(file_path):
            print(f"File could not be found: {file_path}", file=sys.stderr)
            sys.exit(1)


def load_json(json_file_path):
    """
    Loads JSON files into Python objects.

    See: https://docs.python.org/3/library/json.html#encoders-and-decoders

    Parameters:
        - json_file_path (string): the deployment template file path

    Returns:
        - json_as_object (object): the deployment template as a Python object
    """

    try:
        with open(json_file_path, 'r', encoding="UTF-8") as json_file:
            json_as_object = json.load(json_file)
    except Exception as exception:
        print(f"Unable to parse JSON from file {json_file_path} "
              f"with Exception: {exception}",
              file=sys.stderr)
        sys.exit(1)

    return json_as_object


def validate_form(form, template):
    """
    Validates a Declarative Form UI template
    and if any errors are encountered
    writes the errors to stderr and exits code 1

    Parameters:
        - template (Dict): the deployment template as a Python object
        - form (Dict): the Declarative Form UI template as a Python object
    """

    errors = []

    valid, messages = form_specifies_all_required_parameters(form, template)
    if not valid:
        errors.extend(messages)

    valid, messages = form_specifies_valid_parameters(form, template)
    if not valid:
        errors.extend(messages)

    if len(errors) > 0:
        for message in errors:
            print(message, file=sys.stderr)
        sys.exit(1)


def form_specifies_all_required_parameters(form, template):
    """
    Validates that a Declarative Form UI provides
    output for every required deployment template parameter

    Parameters:
        - form (Dict): the Declarative Form UI template as a Python object
        - template (Dict): the deployment template as a Python object

    Returns:
        - valid (bool): if the form outputs all required deployment template parameters
        - errors (list): a list of required deployment template parameters not found in form output
    """

    errors = []

    required_parameters = get_required_parameters(template["parameters"])
    form_outputs = form["view"]["outputs"]["parameters"].keys()

    required_parameters_not_in_form_outputs = set(
        required_parameters).difference(form_outputs)

    for required_parameter in required_parameters_not_in_form_outputs:
        errors.append(
            f"Required parameter '{required_parameter}' not found in Declarative Form output")

    if len(errors) > 0:
        return False, errors

    return True, None


def form_specifies_valid_parameters(form, template):
    """
    Validates that a Declarative Form UI provides
    only deployment template parameters as output

    Parameters:
        - form (Dict): the Declarative Form UI template as a Python object
        - template (Dict): the deployment template as a Python object

    Returns:
        - valid (bool): if the form outputs only what is a deployment template parameter
        - errors (list): a list of outputs that are not found in the deployment template parameters
    """

    errors = []

    form_outputs = form["view"]["outputs"]["parameters"].keys()
    template_parameters = template["parameters"].keys()

    form_outputs_not_in_template = set(
        form_outputs).difference(template_parameters)

    for output in form_outputs_not_in_template:
        errors.append(
            f"Form output '{output}' not found in deployment template parameters")

    if len(errors) > 0:
        return False, errors

    return True, None


def get_required_parameters(parameters):
    """
    Returns all the parameters of an deployment template that do not specify a default value
    """

    required_parameters = []

    for param in parameters:
        if not "defaultValue" in parameters[param]:
            required_parameters.append(param)

    return required_parameters


if __name__ == '__main__':
    main()
