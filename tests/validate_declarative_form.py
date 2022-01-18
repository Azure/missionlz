# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
A command-line utility for validating
a given Declarative Form Portal UI JSON template against
a given ARM Deployment Template JSON template
"""

import argparse
import json
from os import path
import sys


def main():
    """
    Parses arguments, loads JSON into memory, executes form validation
    """

    deployment_template_path, form_template_path = parse_args()

    validate_paths(deployment_template_path, form_template_path)

    template, form = load_json(
        deployment_template_path,
        form_template_path)

    validate_form(template, form)

    sys.exit(0)


def parse_args():
    """
    Parses arguments to return file paths for
    the deployment template (e.g. azuredeploy.json)
    and the Declarative Form UI template.

    See https://docs.python.org/3.11/howto/argparse.html for an example.

    Returns:
        - deployment_template_path (string)
        - form_file_path (string)
    """

    parser = argparse.ArgumentParser(description='Process some integers.')

    parser.add_argument("deployment_template_path",
                        help="the deployment template JSON file path")

    parser.add_argument("form_template_path",
                        help="the Declarative Form UI template JSON file path")

    args = parser.parse_args()

    return args.deployment_template_path, args.form_template_path


def validate_paths(*args):
    """
    Validates that files exist at a given path.
    If a file does not exist at the path, prints a message to stderr and exits code 1
    """
    for file_path in args:
        if not path.isfile(file_path):
            print(f"File could not be found: {file_path}", file=sys.stderr)
            sys.exit(1)


def load_json(deployment_template_path, form_template_path):
    """
    Loads JSON files into Python objects.

    See: https://docs.python.org/3/library/json.html#encoders-and-decoders

    Parameters:
        - template_file_path (string): the deployment template file path
        - form_file_path (string): the Declarative Form UI template file path

    Returns:
        - template_json (object): the deployment template as a Python object
        - form_json (object): the Declarative Form UI as a Python object
    """

    with open(deployment_template_path, 'r', encoding="UTF-8") as template_file:
        template = json.load(template_file)

    with open(form_template_path, 'r', encoding="UTF-8") as form_file:
        form = json.load(form_file)

    return template, form


def validate_form(template, form):
    """
    Validates a Declarative Form UI template
    and if any errors are encountered
    writes the errors to stderr and exits code 1

    Parameters:
        - template (Dict): the deployment template as a Python object
        - form (Dict): the Declarative Form UI template as a Python object
    """

    errors = []

    valid, messages = form_specifies_all_required_parameters(template, form)
    if not valid:
        errors.extend(messages)

    valid, messages = form_specifies_valid_parameters(template, form)
    if not valid:
        errors.extend(messages)

    if len(errors) > 0:
        for message in errors:
            print(message, file=sys.stderr)
        sys.exit(1)


def form_specifies_all_required_parameters(template, form):
    """
    Validates that a Declarative Form UI provides
    output for every required deployment template parameter

    Parameters:
        - template (Dict): the deployment template as a Python object
        - form (Dict): the Declarative Form UI template as a Python object

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


def form_specifies_valid_parameters(template, form):
    """
    Validates that a Declarative Form UI provides
    only deployment template parameters as output

    Parameters:
        - template (Dict): the deployment template as a Python object
        - form (Dict): the Declarative Form UI template as a Python object

    Returns:
        - valid (bool): if the form outputs only what is a deployment template parameter
        - errors (list): a list of outputs that are not found in the deployment template parameters
    """

    errors = []

    template_parameters = template["parameters"].keys()
    form_outputs = form["view"]["outputs"]["parameters"].keys()

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
