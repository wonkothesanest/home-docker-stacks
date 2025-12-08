Consolidate Home Lab Containers under Portainer Management
Summary

Create a clear plan and migration path to move all existing Docker containers in my home lab to be fully managed via Portainer stacks, using GitHub-backed Compose files wherever possible. This includes analyzing the current state, designing target stack definitions, and safely migrating any persistent data (volumes, bind mounts, configs) with minimal downtime.

Background / Current State

I have multiple Docker hosts in my home lab.

Some containers are:

Started manually via docker run on each host.

Deployed via Portainer stacks referencing a GitHub repo that already contains some docker-compose.yml files.

Over time, this has led to:

Inconsistent configuration (different flags/ports/env on different hosts).

Hard-to-reproduce setups (manual docker run commands not tracked in Git).

Unclear data locations, especially for containers using local bind mounts or anonymous volumes.

Goal:

Move to a single source of truth model where all containers are defined via Compose files in GitHub and deployed from Portainer stacks, with all persistent data preserved.

Objectives

Inventory & Analyze the existing stack across all hosts:

Identify all running containers, how they were started, and what they do.

Capture current configuration: images, ports, env vars, networks, volumes.

Design a Target State:

Define one or more Portainer-managed stacks per logical group of services.

Represent each stack as a Compose file in GitHub.

Standardize environment variable usage, networks, and volume naming.

Plan Data Migration:

Identify persistent data locations for each container (named volumes, bind mounts, config dirs).

Define safe migration steps so containers can be re-created via Portainer without data loss.

Execute Migration with Minimal Downtime:

For each container/service, stop the old instance and start the new Portainer-managed one.

Validate service behaviour and data integrity after migration.

Document & Automate Going Forward:

Document the final architecture (which host runs which stack).

Ensure future changes flow through Git → Portainer stacks, not ad-hoc docker run.

Scope

In scope:

All Docker containers currently running on home lab hosts:

Manually started (docker run)

Portainer stacks not yet backfilled into Git (if any)

Networks, volumes, and bind mounts associated with those containers.

Portainer stack definitions and configuration.

Data migration requirements for:

Databases (e.g., Postgres, MySQL, Redis)

Stateful services (e.g., media servers, dashboards)

Any app with local storage

Out of scope (for now):

Refactoring application code.

Full CI/CD pipeline design.

Deep security hardening (beyond basic best practices).

Detailed Requirements
1. Discovery & Analysis

For each host:

List all containers: docker ps --all.

For each container, capture:

Image name & tag

docker run (or equivalent) options:

Ports

Env vars

Networks

Volumes / bind mounts

Restart policies

Any host-specific files or configs it relies on.

Output: A structured inventory (YAML/Markdown/CSV) summarizing all services and their configs.

2. Target Stack Design

Group containers into logical stacks, for example:

core-infra (reverse proxy, monitoring, etc.)

media

dev-tools

home-automation

For each logical group:

Create or update a docker-compose.yml in the GitHub repo with:

Services and images

Networks (internal + external)

Volumes & bind mounts

Env vars (ideally via .env files)

Restart policies

Ensure the Compose file is Portainer-friendly:

Uses version supported by Portainer.

No host-specific quirks unless clearly documented.

3. Data Migration Planning

Identify all persistent volumes and bind mounts in use:

Map each container’s data paths to host directories or named volumes.

For each service:

Decide whether to:

Reuse existing named volumes.

Repoint Compose to the existing host paths.

Copy data into a newly named volume.

Define a migration checklist per service:

Backup strategy (e.g., docker cp, rsync, DB dumps).

Exact commands/steps to:

Stop old container.

Attach the same data to the new stack-defined service.

Start new container via Portainer stack.

Rollback steps if new stack fails.

4. Portainer Integration

Configure Portainer to:

Point to the GitHub repo for each stack definition.

Deploy stacks on the correct target endpoints (specific Docker hosts).

Standardize:

Naming of stacks.

Usage of environment templates or .env files per stack.

Validate:

Stacks can be redeployed from Git without manual tweaks on the host.

5. Migration Execution

For each service/stack:

Prepare

Ensure Compose + Portainer stack definition is ready and tested in a non-critical environment if possible.

Confirm data directories/volumes are mapped correctly.

Migrate

Stop the old container.

Deploy the new stack via Portainer.

Verify:

Logs

Service availability (web UI, API, etc.)

Data presence (no missing configs / DB contents).

Finalize

Remove old container definitions / orphan resources no longer needed.

Mark the service as "Portainer-managed" in documentation.

Success Criteria / Acceptance

✅ All previously manually started containers are now managed via Portainer stacks.

✅ Every running container has a corresponding Compose definition in GitHub.

✅ All persistent data has been preserved and verified post-migration.

✅ Portainer can re-deploy any stack from Git without host-level manual intervention.

✅ Documentation exists listing:

Each stack

Which host it runs on

Relevant volumes and networks

Basic recovery steps

# context

Plain-Text Documentation Links for Context
Docker Fundamentals

https://docs.docker.com/get-started/

https://docs.docker.com/engine/reference/run/

https://docs.docker.com/engine/reference/commandline/docker/

https://docs.docker.com/engine/reference/builder/

Docker Compose (core to Portainer stack migrations)

https://docs.docker.com/compose/

https://docs.docker.com/compose/compose-file/

https://docs.docker.com/compose/how-tos/migrate/

https://docs.docker.com/compose/how-tos/environment-variables/

https://docs.docker.com/storage/volumes/

Docker Volumes / Persistent Data (crucial for safe migration)

https://docs.docker.com/storage/

https://docs.docker.com/storage/volumes/

https://docs.docker.com/storage/bind-mounts/

https://docs.docker.com/storage/tmpfs/

https://docs.docker.com/engine/reference/commandline/volume_inspect/

https://docs.docker.com/engine/reference/commandline/volume_ls/

Exporting, Inspecting, and Reproducing Manually-Started Containers

https://docs.docker.com/engine/reference/commandline/inspect/

https://docs.docker.com/engine/reference/commandline/container_inspect/

https://docs.docker.com/engine/reference/commandline/container_ls/

https://docs.docker.com/engine/reference/commandline/run/

Useful third-party article on reverse-engineering docker run into Compose:
https://www.composerize.com/

Portainer Documentation (Stacks, GitHub integration, multi-host)
Core Docs

https://docs.portainer.io/

https://docs.portainer.io/user/docker/stacks/

https://docs.portainer.io/admin/endpoints/add/docker

https://docs.portainer.io/user/docker/external-endpoints

GitHub / Git-Based Stacks

https://docs.portainer.io/user/git/gitops

https://docs.portainer.io/user/git/stacks-from-git

Configuration Templates

https://docs.portainer.io/user/docker/templates

Portainer + Multi-Node / Multi-Host Context

(Useful because you have multiple hosts and a single control plane)

https://docs.portainer.io/admin/environments

https://docs.portainer.io/admin/environments/docker/agent

https://docs.portainer.io/user/docker/agent

Backup & Migration Guidance
Docker Official Backup Approaches

https://docs.docker.com/storage/backup-restore/

Volume backup strategies

https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes

Exporting and reimporting containers

https://docs.docker.com/engine/reference/commandline/container_export/

https://docs.docker.com/engine/reference/commandline/container_import/

Network Architecture Documentation
Docker Networking

https://docs.docker.com/network/

https://docs.docker.com/network/network-tutorial-overlay/

https://docs.docker.com/network/drivers/bridge/

https://docs.docker.com/network/drivers/overlay/

Multi-host considerations

https://docs.docker.com/network/network-tutorial-overlay/#use-the-overlay-driver-with-swarm-services

Useful Third-Party Resources for Migration Thinking
Convert docker run → docker-compose

https://www.composerize.com/

Multi-host best practices

https://www.portainer.io/blog/portainer-and-docker-swarm-the-best-way-to-manage-your-multi-host-docker-environment

⭐ Optional: Add context-specific documentation for future expansion

If the system will later build architecture around:

Traefik reverse proxy:

https://doc.traefik.io/traefik/

Tailscale:

https://tailscale.com/kb/

Cloudflare Tunnel:

https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/