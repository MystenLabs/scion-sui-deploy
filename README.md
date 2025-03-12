# Deploy SCION, for Sui

Ansible playbooks for deploying SCION for Sui validators.

## Installation

Requires Python3 and Poetry. Poetry can be installed with

```bash
curl -sSL https://install.python-poetry.org | python3 -
```

Python dependencies, ansible, and playbook dependencies can then be installed within a Python virtual environment managed by poetry.

```bash
poetry install --no-root
poetry run ansible-galaxy install -r ansible/requirements.yml
```

## Configuration

See the [SCION for Sui Validators](https://mystenlabs.notion.site/SCION-for-Sui-Validators-6c191f0088d54425b4de4be1ba747ce3) document for more details on acquiring the files and configuration necessary for running the playbooks.

## Running the Playbook

Once configured, the playbook can be run using

```bash
poetry run ansible-playbook -i hosts.yml ansible/playbook.yml
```

## License

This project is licensed under the Apache License, Version 2.0 ([LICENSE](LICENSE) or
<https://www.apache.org/licenses/LICENSE-2.0>).
