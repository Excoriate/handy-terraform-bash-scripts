## Terraform automations scripts

All these scripts were made to be used either in an automated environment — let's say, a CICD job that runs in a given pipeline, a terminal alias, npm script, etc.

Even though, these scripts can be easily integrated on some `git hook` such as `husky` or `pre-commit` framework. They're agnostic to any specific tool — they're just bash scripts :)

## Scripts
| Hook                                              | Description                                                                                                                |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `terraform_validate.sh`                             | Validates all Terraform configuration files.                                                                               |
| `terraform_fmt`                                  | Format (check and fix) Terraform configuration following the canonical format.                                                          |
| `terraform_docs`                                 | Generate and keep up to date the documentation of terraform components. Re-write the `readme.md` file dynamically                                                      |
| `terraform_lint`                               | Use [TFLint](https://github.com/terraform-linters/tflint) to prevent bugs!                           |
| `terraform_clean`                                 | Get rid of the `.terraform` folder on local executions, after you've done all your local terraform commands. |
| `terraform_sec`                            | Validates all Terraform configuration from the security point of view. It uses [TFSec](https://github.com/liamg/tfsec)                       |
| `terraform_plan`                                | Execute terraform plan command onto specific terraform modules |
| `terraform_lifecycle`                                | Script that wraps the `terraform` licecycle: `init`, `plan`, `apply` and `destroy` |
| `terraform_modules_auth_gitlab`                                | Whether you're using Gitlab and you're using private `terraform` modules within Gitlab, this script allows you authenticate your child modules and download (`terraform get`) other called modules from within Gitlab |

## Example of use
### Add this scripts in `npm` scripts
```json
    "tf:init": "export ENVIRONMENT=test && ./scripts/automation/terraform_lifecycle.sh --command=init --dir=example --config=config/remote.config",
    "tf:plan": "export ENVIRONMENT=test && ./scripts/automation/terraform_lifecycle.sh --command=plan --dir=example --vars=config/terraform.tfvars --config=config/remote.config",
    "tf:apply": "export ENVIRONMENT=test && ./scripts/automation/terraform_lifecycle.sh --command=apply --dir=example --vars=config/terraform.tfvars --config=config/remote.config",
    "tf:destroy": "export ENVIRONMENT=test && ./scripts/automation/terraform_lifecycle.sh --command=destroy --dir=example --vars=config/terraform.tfvars --config=config/remote.config",
    "tf:clean": "export ENVIRONMENT=test && ./scripts/automation/terraform_lifecycle.sh --command=clean --dir=example && ./scripts/automation/terraform_lifecycle.sh --command=clean --dir=module",
    "tf:docs": "./scripts/hooks/terraform_docs.sh --dir=module",
    "tf:format": "./scripts/hooks/terraform_fmt.sh --dir=module",
```

### Use them standalone
```bash
    ./scripts/automation/terraform_lifecycle.sh --command=init --dir=example --config=config/remote.config
```

### Use in CICD (Example> Gitlab)
```yaml
    plan_infra:
    stage: plan
    variables:
      TF_VAR_environment: test
      AWS_DEFAULT_REGION: ${AWS_REG_TEST}
    script:
      - ./scripts/automation/terraform_lifecycle.sh --command=plan --dir=example --vars=config/terraform.tfvars --config=config/remote.config
    dependencies:
      - init_infra
```