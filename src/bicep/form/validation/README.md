# Declarative-Form Tests

In this directory, you'll find a Python command-line utility for validating that a given Declarative Form Portal UI JSON template emits outputs that can be used as parameter input to a given ARM Deployment Template JSON template.

```plaintext
Declarative Form Output => ARM Template Parameters
```

## Running the Validator

Run the `--help` command to see the required arguments:

```plaintext
cd src/bicep/form/validation
python3 validate_declarative_form.py -h
```

And you should get back some help:

```plaintext
usage: validate_declarative_form.py [-h] form_template_path deployment_template_path 

Validate a Declarative Form UI template against an ARM Deployment Template.
```

So, execute it like:

```plaintext
# cd src/bicep/form/validation
python3 validate_declarative_form.py ../mlz.portal.json ../../mlz.json
```

### Success

If successful, you'll find this in the stdout:

```plaintext
Success. The Declarative Form UI template <path> contains outputs that map to the ARM deployment template <path> parameters.
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

### Debugging in the IDE

There's `launch.json` editor settings specified that pass command line arguments to any active Python script:

- Open `validate_declarative_form.py` in the Codespace
- set a breakpoint
- and select "Run and Debug" (Ctrl + Shift + D) from the Application Menu to start debugging the validator script

See <https://code.visualstudio.com/docs/python/debugging/> for more information on how to debug Python from the Codespace.

## Testing the Validator

### Testing in the IDE

There's `settings.json` editor settings specified that inform where Python unit tests can be discovered:

- Select "Testing" from the Application menu (or open the Command Pallete (F1) and type `View: Show Testing`)
- Expand the `validation` directory and it's children to see all the unit tests
- You can run them all selecting the "Run Tests" button (or open the Command Pallete (F1) and type `Test: Run All Tests`)
- You can debug individual tests by setting a breakpoint in `validate_declarative_form.py` or `validate_declarative_form_test.py` and selecting `Debug Test` from the tests pane

### Testing from the terminal

You can run the unit tests by calling the `unittest` module from Python like:

```plaintext
# cd src/bicep/form/validation
python -m unittest validate_declarative_form_test.py -v
```

And you should get output similar to:

```plaintext
test_form_specifies_all_required_parameters (validate_declarative_form_test.ValidateDeclarativeFormTest)
Test that all required parameters not output by the form return errors ... ok
test_form_specifies_valid_parameters (validate_declarative_form_test.ValidateDeclarativeFormTest)
Test that all form outputs exist as deployment template parameters ... ok
test_get_required_parameters (validate_declarative_form_test.ValidateDeclarativeFormTest)
Test that all deployment template parameters that do not have default values are returned ... ok
test_validate_form_captures_extraneous_form_output (validate_declarative_form_test.ValidateDeclarativeFormTest)
Test that if there are extra form outputs that are not template parameters ... ok
test_validate_form_captures_missing_required_parameter (validate_declarative_form_test.ValidateDeclarativeFormTest)
Test that if there is a missing required template parameter ... ok
test_validate_form_catches_invalid_template_json (validate_declarative_form_test.ValidateDeclarativeFormTest)
Test that if invalid JSON is passed that load fails and ... ok
test_validate_form_without_errors (validate_declarative_form_test.ValidateDeclarativeFormTest)
Test that if there are no errors in the validation ... ok

----------------------------------------------------------------------
Ran 7 tests in 0.001s

OK
```
