# GitHub Copilot Instructions for Home Network Infrastructure Project

This repository defines the infrastructure and applications for a self-hosted home network solution, using Raspberry Pis and Docker. The setup includes ad-blocking (Pi-hole), internal-only Python/Streamlit apps, parental internet access controls, and network monitoring dashboards. All components are intended to be version-controlled and automated.

## Code Style and Structure Guidelines

- Use **Docker Compose** for service orchestration.
- Keep each service in its own folder with its `docker-compose.yml`, `.env`, and any config files.
- Use **YAML** over JSON where both are supported.
- Prefer **lightweight**, **readable**, and **idempotent** configuration.
- Provide example `.env.example` files but do not commit sensitive values.
- Use consistent naming: lowercase, underscores for folders and variables (e.g., `streamlit_apps/`, `ntopng_config/`).

## Key Services and Directories

- `pi-hole/`: DNS-level ad blocking using Pi-hole with optional Unbound.
- `ntopng/`: Traffic monitoring and per-device network insights.
- `streamlit-apps/`: Folder of internal Python dashboards.
- `grafana-monitoring/`: (Optional) Use Prometheus + Grafana for system-level metrics.
- `ansible/`: For optional config management across hosts.
- `.github/workflows/`: Contains CI/CD for deploying updates (e.g., pushing Docker images or configs to devices via SSH or rsync).

## Copilot Behaviour Preferences

### When Writing Docker Compose Files
- Suggest ports, volumes, and health checks.
- Always include container name, restart policy, and service dependencies.
- For Pi-hole, set `DNSMASQ_USER=pihole`, expose DNS on port 53 and web on 80.

### When Writing Streamlit Apps
- Suggest clean and minimal layouts.
- Use session state if multiple users could use the app concurrently.
- Use filesystem or S3 file read/write, not a database.

### When Writing GitHub Actions
- Focus on CI/CD for deploying config changes to Raspberry Pis.
- Use workflows like `on: push` to `main`, trigger `scp` or `rsync`.
- Prefer reusability and self-hosting aware deployment (no cloud required).

### When Writing Parental Controls (OpenWRT/pfSense)
- Use UCI or API commands for automation.
- Include examples for time-based rules.
- Scripts should be written in Bash or Python, run headless, and deploy via SSH.

## General Preferences

- Comment code where config options may be unclear.
- Output only the required code/config snippet unless asked for full setup.
- Assume this is a **local-network only** setup unless stated otherwise.
- Avoid recommending solutions that rely on external cloud services.

