<div align="center">
  <img src="https://icon.icepanel.io/Technology/svg/HashiCorp-Terraform.svg" title="Terraform" alt="Terraform" width="256" height="256" style="filter: url(#glow);" />

<svg xmlns="http://www.w3.org/2000/svg" version="1.1" height="0">
  <defs>
    <filter id="glow">
      <feGaussianBlur stdDeviation="15" result="coloredBlur"/>
      <feMerge>
        <feMergeNode in="coloredBlur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
</svg>

<link href="https://fonts.googleapis.com/css?family=Onest&display=swap" rel="stylesheet">

<h1 style="font-family: Onest, monospace; color: lightblue; ">Module Consumption Template</h1>
<h6>A repository template for consuming and deploying infrastructure using OpenTofu/Terraform modules.</h6>

</div>

---

This `README.md` provides step-by-step instructions for setting up and using the **`terraform-modules-template`** GitLab project. This project serves as a template for creating **infrastructure deployments** that consume pre-built Terraform/OpenTofu modules.

## Table of Contents

* [Getting Started](#getting-started)
* [Consumption Structure](#consumption-structure)
* [Continuous Integration Jobs and Variables](#continuous-integration-jobs-and-variables)
* [Deployment](#deployment)

---

## Getting Started

Follow these steps to set up and start using your new Python project based on this template.

### 1. Create a New GitLab Project from Template

1.  Navigate to your GitLab instance.
2.  Click on **"New project"**.
3.  Select **"Create from template"**.
4.  Choose **"Instance"** (if template is available instance-wide) or **"Group"** (if template is saved as a group template).
5.  Select this `terraform-modules-template` (or similar name if renamed).
6.  Give your new project a name and description, and set its visibility.
7.  Click **"Create project"**.

### 2. Clone the Repository

Once your new project is created, clone it to your local machine:

```bash
git clone https://<REPOSITORY_URL>
cd <YOUR_PROJECT_NAME>
```

---

## Consumption Structure

This template provides a standard structure for consuming Terraform/OpenTofu modules and includes files common to most open-source projects.

### Terraform/OpenTofu Artifacts

This section covers the directories and files essential for the deployment's logic and execution pipeline.

* **`main.tf`**: The **primary file** where you define the resources and, crucially, **call the modules** you intend to consume (e.g., `module "vpc" { source = "..." }`).
* **`variables.tf`**: Defines all **input variables** for this root configuration, typically used to parameterize the consumed modules.
* **`outputs.tf`**: Defines the **exported attributes** from this deployment, which can be useful for linking to other systems or configurations.
* **`providers.tf`**: Specifies the **providers** (e.g., AWS, Azure, Google) and their configurations required for the deployment.
* **`values/*.tfvars`**: Use these files to store **environment-specific values** (e.g., `pd.tfvars`, `dv.tfvars`).
    > **Note on CI/CD:** The default `tf-plan` and `tf-apply` jobs **do not** currently utilize an environment-specific `.tfvars` file. They execute with only the variables defined in the repository's CI/CD settings. To use environment-specific `.tfvars`, you must modify the `TF_PLAN_ADDITIONAL_PARAMETERS` and `TF_APPLY_ADDITIONAL_PARAMETERS` of the `tf-plan` and `tf-apply` jobs to include the `-var-file` flag (e.g., `-var-file=values/pd.tfvars`).
* **`.tflint.hcl`**: The configuration file for TFLint, used to define rules, enable plugins, and configure the linting process.
* **`.gitlab-ci.yml`**: The **CI/CD configuration file** that orchestrates the `init`, `plan`, and `apply` lifecycle using **OpenTofu** or **Terraform**

### Project Metadata and Documentation Files

You should edit the following files **as needed** to configure your specific project details:

* **`README.md`**: The primary documentation file for the project. You should update this to reflect your specific application details.
* **`.editorconfig`**: Configuration for consistent code style across editors.
* **`.gitignore`**: Specifies files and directories to be ignored by Git.
* **`AUTHORS`**: List of contributors to the project.
* **`CHANGELOG.md`**: A file to document notable changes for each release.
* **`CONTRIBUTING.md`**: Guidelines for how others can contribute to the project.
* **`LICENSE`**: The license under which the project is distributed.

---

## Continuous Integration Jobs and Variables

The **`.gitlab-ci.yml`** file uses **OpenTofu** (aliased as `tofu`) or **Terraform** to manage the infrastructure lifecycle. It is pre-configured to use the GitLab-managed **Terraform HTTP backend** for state management.

### Global Variables and Cache

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `TF_TOOL` | `"tofu"` | Toggle which IaC tool to use: terraform or tofu |
| `TF_STATE_NAME` | `"tfstate"` | Defines the prefix for the Terraform state file in the remote backend. |

The pipeline uses a shared cache tied to the commit reference slug (`$CI_COMMIT_REF_SLUG`) which targets the following paths:

* **`.terraform/`**: Stores downloaded provider plugins and modules.
* **`.terraform.lock.hcl`**: Ensures provider versions are consistent between runs.

Caching these paths speeds up subsequent runs by preventing repeated provider downloads during the **`terraform init`** phase.

### Pipeline Stages and Jobs

The table below outlines the included jobs, their stages, primary functions, and the custom GitLab CI/CD variables they utilize.

### CI/CD Jobs

| Job Name | Stage | Function | Key Variables & Defaults |
| :--- | :--- | :--- | :--- |
| **`tf-fmt`** | `pre-build` | Checks HCL code style. Runs the equivalent of `tofu fmt -check -diff` or `terraform fmt -check -diff`. | `TF_FMT_ADDITIONAL_PARAMETERS`: *`-recursive -check -diff`* |
| **`tflint`** | `pre-build` | Lints the configuration to find potential errors, anti-patterns, and violations of best practices. | `TFLINT_PARAMETERS`: *`--config=.tflint.hcl`* |
| **`tf-init`** | `pre-build` | **Initializes** the OpenTofu/Terraform working directory and explicitly configures the GitLab **HTTP backend** for state management. | `TF_INIT_ADDITIONAL_PARAMETERS`: *`null`* |
| **`tf-validate`** | `pre-build` | **Validates** the configuration. Checks syntax and internal consistency. | `TF_VALIDATE_ADDITIONAL_PARAMETERS`: *`null`* |
| **`tf-plan`** | `build` | Generates an **execution plan** (`tfplan` artifact). This step is essential for reviewing proposed changes before application. | `TF_PLAN_FILE_NAME`: *`tfplan`* <br> `TF_PLAN_ADDITIONAL_PARAMETERS`: *`null`* |
| **`tf-apply`** | `deploy` | **Applies** the pre-built `tfplan` artifact to provision or modify infrastructure. **Manual execution** is required. | `TF_PLAN_FILE_NAME`: *`tfplan`* <br> *HTTP Backend Variables (Explicitly Set):* <br> `TF_HTTP_ADDRESS`: *`${CI_API_V4_URL}/...`* <br> `TF_HTTP_LOCK_ADDRESS`: *`${CI_API_V4_URL}/.../lock`* <br> `TF_HTTP_UNLOCK_ADDRESS`: *`${CI_API_V4_URL}/.../lock`* <br> `TF_HTTP_USERNAME`: *`${TF_HTTP_USER}`* <br> `TF_HTTP_PASSWORD`: *`${TF_HTTP_PW}`* <br> `TF_HTTP_LOCK_METHOD`: *`POST`* <br> `TF_HTTP_UNLOCK_METHOD`: *`DELETE`* <br> `TF_HTTP_RETRY_WAIT_MIN`: *`5`* |

---

### Required CI/CD Variables

The OpenTofu/Terraform jobs rely on the following variables being securely configured in your GitLab project's **Settings > CI/CD > Variables**:

| Variable Name | Description | Used by Jobs |
| :--- | :--- | :--- |
| **`TF_HTTP_USER`** | Username for authenticating with the GitLab HTTP backend (typically a **Group or Project Access Token**). | `tf-init`, `tf-apply` |
| **`TF_HTTP_PW`** | Password/Token for authenticating with the GitLab HTTP backend. | `tf-init`, `tf-apply` |

> **⚠️ Disclaimer on Code Quality Scanning:** By utilizing this repository template, you acknowledge and agree that code quality scanning via **tflint** is pre-configured and included as a mandatory step within the continuous integration (CI) pipeline. This is intended to maintain a high standard of quality and consistency across all contributions.

---

## Deployment

### 1. Triggering a Plan

Any push to a branch or the creation of a Merge Request will trigger the initial **`pre-build`** and **`build`** stages, culminating in the creation of a `tfplan` artifact.

### 2. Manual Application

The **`tf-apply`** job is set to `when: manual` for safety. This prevents accidental changes and enforces a review before infrastructure is modified.

To execute the deployment:

1.  Navigate to **CI/CD > Pipelines** in your GitLab project.
2.  Find the pipeline that successfully ran the **`tf-plan`** job.
3.  Click the **play button** next to the **`tf-apply`** job in the `deploy` stage. This will execute the plan artifact and apply the infrastructure changes.

------