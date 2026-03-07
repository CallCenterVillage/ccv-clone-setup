# CCV Clone Setup

Scripts for configuring each machine after Clonezilla deployment. Sets the hostname, installs AV, and registers the RMM agent.

---

## Files

| File | Description |
|---|---|
| `setup-clone.sh` | Main setup script — run this on each machine |
| `.env` | Config file containing your AV token and RMM URL |
| `*.deb` | SentinelOne installer — place this here before cloning |

---

## Preparing the Golden Image

Do this once before running Clonezilla.

### 1. Fill in `.env`

Open `.env` and add your credentials:

```
AV_SITE_TOKEN=your-sentinelone-site-token
RMM_INSTALL_URL=https://hostname/your-installer-url
```

### 2. Add the SentinelOne .deb installer

Download the Linux agent from the SentinelOne console (Settings > Updates > Linux) and place the `.deb` file in `/opt/clone-setup/`. The script will find it automatically.

### 3. Set permissions

```bash
chmod +x /opt/clone-setup/setup-clone.sh
```

Then proceed with Clonezilla as normal.

---

## Per-Machine Setup (after cloning)

Run this on each machine once it's booted and connected to the network:

```bash
cd /opt/clone-setup
sudo bash setup-clone.sh
```

The script will:
1. Prompt you for the hostname (e.g. `ccv02`, `ccv03`...)
2. Show a confirmation summary
3. Set the hostname
4. Install and register SentinelOne
5. Install and register the RMM agent

A log of each run is saved to `/opt/clone-setup/setup.log`.

---

## Hostnames

Please use `ccvNN` where `NN` is a two-digit number greater than `01`


### Reserved Hostnames

| Hostname | Notes |
|---|---|
| ccv01 | Master station (not cloned) |

