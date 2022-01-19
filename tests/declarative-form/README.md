# Declarative-Form Tests

In this directory, you'll find a Python command-line utility for validating a given Declarative Form Portal UI JSON template against a given ARM Deployment Template JSON template.

## Running the Validator

Run the `--help` command to see the required arguments:

```plaintext
python3 validate_declarative_form.py -h
```

And you should get back some help:

```plaintext
usage: validate_declarative_form.py [-h] deployment_template_path form_template_path

Validate a Declarative Form UI template against an ARM Deployment Template.
```

So, execute it like:

```plaintext
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

## Testing the Validator

//TODO (gmusa 20210118): write up how to execute tests in the .devcontainer
