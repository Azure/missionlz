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

## Testing the Validator

```plaintext
cd src/bicep/form/validation
python3 -m unittest validate_declarative_form_test.py -v
```
