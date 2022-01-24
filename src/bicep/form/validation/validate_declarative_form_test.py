# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Tests the validation for declarative forms
"""

from io import StringIO
import tempfile
import unittest
from unittest.mock import patch
import validate_declarative_form


class TestValidateDeclarativeForm(unittest.TestCase):
    """
    Test the validation for declarative forms
    """

    missing_required_param = "resourcePrefix"
    extraneous_output = "fizz"

    parameters_with_some_default_values_specified = {
        "parameters": {
            missing_required_param: {
                "type": "string",
                "maxLength": 10,
                "minLength": 3
            },
            "resourceSuffix": {
                "type": "string",
                "defaultValue": "foo",
                "maxLength": 6,
                "minLength": 3
            }
        }
    }

    parameters_with_all_default_values_specified = {
        "parameters": {
            "resourcePrefix": {
                "type": "string",
                "defaultValue": "foo",
                "maxLength": 10,
                "minLength": 3
            },
            "resourceSuffix": {
                "type": "string",
                "defaultValue": "bar",
                "maxLength": 6,
                "minLength": 3
            }
        }
    }

    outputs_with_all_values_specified = {
        "view": {
            "outputs": {
                "parameters": {
                    "resourcePrefix": "[steps('basics').namingSection.resourcePrefix]",
                    "resourceSuffix": "[steps('basics').namingSection.resourceSuffix]",
                }
            }
        }
    }

    outputs_with_missing_required_parameter = {
        "view": {
            "outputs": {
                "parameters": {
                    "resourceSuffix": "[steps('basics').namingSection.resourceSuffix]",
                }
            }
        }
    }

    outputs_with_a_value_specified_not_in_parameters = {
        "view": {
            "outputs": {
                "parameters": {
                    "resourcePrefix": "[steps('basics').namingSection.resourcePrefix]",
                    "resourceSuffix": "[steps('basics').namingSection.resourceSuffix]",
                    extraneous_output: "buzz"
                }
            }
        }
    }

    invalid_json_file_content = "{{\"fizz\": \"buzz\"}"

    def test_form_specifies_all_required_parameters(self):
        """
        Test that all required parameters not output by the form return errors
        """

        validation, messages = validate_declarative_form.form_specifies_all_required_parameters(
            self.outputs_with_all_values_specified,
            self.parameters_with_some_default_values_specified)

        self.assertTrue(validation)
        self.assertIsNone(messages)

        validation, messages = validate_declarative_form.form_specifies_all_required_parameters(
            self.outputs_with_missing_required_parameter,
            self.parameters_with_some_default_values_specified)

        self.assertFalse(validation)
        self.assertEqual(len(messages), 1)
        self.assertEqual(
            messages[0],
            f"Required parameter '{self.missing_required_param}'"
            " not found in Declarative Form output")

    def test_form_specifies_valid_parameters(self):
        """
        Test that all form outputs exist as deployment template parameters
        """

        validation, messages = validate_declarative_form.form_specifies_valid_parameters(
            self.outputs_with_all_values_specified,
            self.parameters_with_some_default_values_specified)

        self.assertTrue(validation)
        self.assertIsNone(messages)

        validation, messages = validate_declarative_form.form_specifies_valid_parameters(
            self.outputs_with_a_value_specified_not_in_parameters,
            self.parameters_with_some_default_values_specified)

        self.assertFalse(validation)
        self.assertEqual(len(messages), 1)
        self.assertEqual(
            messages[0],
            f"Form output '{self.extraneous_output}' not found in deployment template parameters")

    def test_get_required_parameters(self):
        """
        Test that all deployment template parameters that do not have default values are returned
        """

        required_parameters = validate_declarative_form.get_required_parameters(
            self.parameters_with_some_default_values_specified["parameters"])

        self.assertEqual(len(required_parameters), 1)
        self.assertEqual(required_parameters[0], "resourcePrefix")

        no_required_parameters = validate_declarative_form.get_required_parameters(
            self.parameters_with_all_default_values_specified["parameters"])

        self.assertEqual(len(no_required_parameters), 0)

    @patch("sys.stderr", new_callable=StringIO)
    def test_validate_form_without_errors(self, mock_stderr):
        """
        Test that if there are no errors in the validation
        that there are no messages to stderr
        """

        validate_declarative_form.validate_form(
            self.outputs_with_all_values_specified,
            self.parameters_with_some_default_values_specified)

        self.assertEqual(mock_stderr.getvalue(), '')

    @patch("sys.stderr", new_callable=StringIO)
    def test_validate_form_captures_missing_required_parameter(self, mock_stderr):
        """
        Test that if there is a missing required template parameter
        that they are output to stderr and it exits code 1
        """

        with self.assertRaises(SystemExit) as system:
            validate_declarative_form.validate_form(
                self.outputs_with_missing_required_parameter,
                self.parameters_with_some_default_values_specified)

        self.assertEqual(system.exception.code, 1)
        self.assertEqual(
            mock_stderr.getvalue(),
            f"Required parameter '{self.missing_required_param}'"
            " not found in Declarative Form output\n")

    @patch("sys.stderr", new_callable=StringIO)
    def test_validate_form_captures_extraneous_form_output(self, mock_stderr):
        """
        Test that if there are extra form outputs that are not template parameters
        that they are output to stderr and it exits code 1
        """

        with self.assertRaises(SystemExit) as system:
            validate_declarative_form.validate_form(
                self.outputs_with_a_value_specified_not_in_parameters,
                self.parameters_with_some_default_values_specified)

        self.assertEqual(system.exception.code, 1)
        self.assertEqual(
            mock_stderr.getvalue(),
            f"Form output '{self.extraneous_output}' not found in"
            " deployment template parameters\n")

    @patch("sys.stderr", new_callable=StringIO)
    def test_validate_form_catches_invalid_template_json(self, mock_stderr):
        """
        Test that if invalid JSON is passed that load fails and
        that the failure to parse it is output to stderr and it exits code 1
        """

        with self.assertRaises(SystemExit) as system:
            with tempfile.NamedTemporaryFile() as file:
                file.write(bytes(self.invalid_json_file_content, "utf-8"))
                validate_declarative_form.load_json(file.name)

        self.assertEqual(system.exception.code, 1)
        self.assertIn(
            f"Unable to parse JSON from file {file.name}",
            mock_stderr.getvalue())

if __name__ == '__main__':
    unittest.main()
