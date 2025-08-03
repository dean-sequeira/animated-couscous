# Git Commit Message Guidelines

## Format
Use only a concise description line (50-72 characters max). No body or footer required.

```
<type>: <description>
```

## Types
- `feat`: new feature or capability
- `fix`: bug fix or correction
- `config`: configuration changes
- `docker`: docker-compose or container updates
- `docs`: documentation updates
- `refactor`: code restructuring without functionality changes
- `deps`: dependency updates
- `ci`: CI/CD pipeline changes
- `ansible`: ansible playbook or automation updates
- `monitoring`: grafana, ntopng, or metrics changes

## Examples
```
feat: add streamlit network dashboard
fix: pi-hole dns resolution timeout
config: update ntopng interface monitoring
docker: upgrade pi-hole to v5.18
docs: add raspberry pi setup instructions
refactor: reorganize streamlit app structure
deps: bump docker-compose to 2.24
ci: add automated config deployment
ansible: add user management playbook
monitoring: configure grafana prometheus data source
```

## Guidelines
- Start with lowercase after the colon
- Use imperative mood ("add" not "added" or "adding")
- No period at the end
- Be specific but concise
- Focus on what the change accomplishes
