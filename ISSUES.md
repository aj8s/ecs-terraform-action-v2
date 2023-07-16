# Issues Post Deployment 

1. Skip ECR creation if already exists
2. Skip Build and Push if no changes in code
3. Safe deletion of target groups
4. Security group updates

## 1. Create ECR repositories in only one environment (e.g., stage) and skip them if they already exist, we need to modify the ecr.tf (in base infra) file as follows:

```
    resource "aws_ecr_repository" "microservices" {
    count = var.environment == "stage" ? length(var.microservices) : 0

    name                 = var.environment == "stage" ? var.microservices[count.index] : null
    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }

    lifecycle {
        ignore_changes = [
        image_tag_mutability,
        image_scanning_configuration
        ]
    }

    tags = {
        Name = var.environment == "stage" ? "${var.microservices[count.index]}-app" : null
    }
    }
```

## 2. In order to skip the build and push steps if no changes are detected in the src folder, we need to modify the .github/workflows/ci-pipeline.yml file as follows:
- A new step named "Check for changes in src folder" is added before the "Login to Amazon ECR" step.
- This step uses the git diff command to check for changes between the current branch (HEAD) and the origin/main branch.
- The "Login to Amazon ECR" and "Build, tag, and push image to Amazon ECR" steps are wrapped with if: steps.check-changes.outputs.changes conditions to execute them only if changes are detected in the src folder.

```
name: CI Workflow

on:
  release:
    types:
      - created
  workflow_dispatch:

env:
  AWS_REGION: us-east-1              # set this to your preferred AWS region, e.g. us-west-1
  ECR_REPOSITORY: coupon          # set this to your Amazon ECR repository name
  SERVICE_NAME: coupon          # set this to the name of the container in the

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
    < old code as it is >

    - name: Check for changes in src folder
      id: check-changes
      run: |
        git fetch --prune
        git diff --name-only origin/main..HEAD | grep "^src/" > changed_files.txt
        echo "::set-output name=changes::$(cat changed_files.txt)"

    - name: Login to Amazon ECR
      if: steps.check-changes.outputs.changes
      < old code as it is >
      

    - name: Build, tag, and push image to Amazon ECR
      if: steps.check-changes.outputs.changes
      < old code as it is >

  deploy-stage:
    runs-on: ubuntu-latest

    <old code as it is >

```


## 3. To facilitate smooth delete of ALB target groups we need to modify the "alb.tf" file in platforminfra directory as follows:
- Modify the aws_lb_target_group resource to depend on the aws_lb_listener_rule resource. This ensures that the target group is only deleted after the listener rule is removed.
```
    resource "aws_lb_target_group" "target_group" {
    ...

    depends_on = [aws_lb_listener_rule.listener_rule]

    ...
    }
```
- Before destroying the target group, de-register any targets that are associated with it. Add this block of code in alb.tf at the end.
```
    resource "aws_lb_target_group_attachment" "attachment" {
    count             = length(var.service.target_instances)
    target_group_arn  = aws_lb_target_group.target_group.arn
    target_id         = var.service.target_instances[count.index]
    }
```

## 4. Security group updates

- Still working on this.. 