# Declarative-Form Tests

In this directory, you'll find a Python command-line utility for validating a given Declarative Form Portal UI JSON template against a given ARM Deployment Template JSON template.

## Running the Validator

Run the `--help` command to see the required arguments:

```plaintext
cd tests/declarative-form/
python3 validate_declarative_form.py -h
```

And you should get back some help:

```plaintext
usage: validate_declarative_form.py [-h] deployment_template_path form_template_path

Validate a Declarative Form UI template against an ARM Deployment Template.
```

So, execute it like:

```plaintext
# cd tests/declarative-form/
python3 validate_declarative_form.py ../../src/bicep/mlz.json ../../src/bicep/form/mlz.portal.json
```

### Success

If successful, you'll find this in the stdout:

```plaintext
Success! The Declarative Form UI template maps to the ARM deployment template.
```

### Failure

Any failure will print the errors to stderr and exit code 1.

Some example errors:

```plaintext
Required parameter 'resourcePrefix' not found in Declarative Form output
```

```plaintext
Form output 'fizzbuzz' not found in deployment template parameters
```

```plaintext
File could not be found: ../../src/bicep/form/mlz.portal.json2
```

## Debugging the Validator

### From Visual Studio Code

`//TODO (gmusa 20221019):` write up how to debug using launch.json in the dev container

## Testing the Validator

### From Visual Studio Code

`//TODO (gmusa 20210118):` write up how to execute tests in the dev container UI

### From the terminal

You can run the unit tests by calling the `unittest` module from Python like:

```plaintext
# cd tests/declarative-form/
python -m unittest validate_declarative_form_test.py -v
```

And you should get output similar to:

```plaintext
test_form_specifies_all_required_parameters (validate_declarative_form_test.TestValidateDeclarativeForm)
Test that all required parameters not output by the form return errors ... ok
test_form_specifies_valid_parameters (validate_declarative_form_test.TestValidateDeclarativeForm)
Test that all form outputs exist as deployment template parameters ... ok
test_get_required_parameters (validate_declarative_form_test.TestValidateDeclarativeForm)
Test that all deployment template parameters that do not have default values are returned ... ok
test_validate_form_captures_extraneous_form_output (validate_declarative_form_test.TestValidateDeclarativeForm)
Test that if there are any errors in validation ... ok
test_validate_form_captures_missing_required_parameter (validate_declarative_form_test.TestValidateDeclarativeForm)
Test that if there are any errors in validation ... ok
test_validate_form_without_errors (validate_declarative_form_test.TestValidateDeclarativeForm)
Test that if there are any errors in validation ... ok

----------------------------------------------------------------------
Ran 6 tests in 0.001s

OK
```
