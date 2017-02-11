# Integrated Commands

## Quickly scaffold an Integrated test

### Usage

```bash
box integrated create LoginSpec
# Creates tests/specs/integration/LoginSpec.cfc
box integrated create LoginSpec coldbox
# Specifies that the Integrated test should extend from the ColdBox Base Spec
```

### Customization

You can change the default spec directory (`tests/specs/integration`) by running `config set modules.integrated-commands.defaultSpecDirectory=my/custom/directory/path`.

You can change the template used by running `config set modules.integrated-commands.templatePath=/my/custom/template/path.txt` 