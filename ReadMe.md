# home-docker-stacks

This repository contains Docker Compose stacks organized by purpose and host:

## Host Overview

- **orangepi5b.local (Raspberry Pi)**:
  - Portainer Server (`infra/portainer`)
  - Zigbee2MQTT and Mosquitto (`iot/zigbee-stack`)

- **wonko.local (Local Workstation)**:
  - n8n, Postgres, and Editly (`apps/n8n-stack`)
  - Prefect Server (`apps/prefect-stack`)
  - Elasticsearch + Kibana (`data/search-stack`)

## Stack Configuration

Each stack includes:
- A `docker-compose.yml` file
- A `.env` file with configuration variables
- A `.env.example` file for safe Git tracking

## Usage

1. Copy `.env.example` to `.env` in each stack
2. Modify `.env` to suit your environment
3. Deploy via Docker Compose or Portainer

```bash
cd apps/n8n-stack
cp .env.example .env
docker compose up -d
```