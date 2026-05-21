# Infrastructure as Code Repository

This repository contains the Infrastructure as Code (IaC) configuration files
and related resources for the project infrastructure.

## Group G

| Name | Email |
| --- | --- |
| Michael Lang | <2510781033@hochschule-burgenland.at> |
| Nemanja Filipović | <2510781028@hochschule-burgenland.at> |
| Andreas Werschlan | <2510781034@hochschule-burgenland.at> |

## Local Linting

Install the required linters on macOS using Homebrew:

```bash
brew install yamllint markdownlint-cli2
```

Run YAML linting for the whole repository:

```bash
yamllint .
```

Run Markdown linting for the whole repository:

```bash
markdownlint-cli2 "**/*.md"
```

