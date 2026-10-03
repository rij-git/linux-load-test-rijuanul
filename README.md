# DevOps Lab Assignment - Linux Service Account & Load Testing

This repo contains my work for the DevOps course assignment on creating and
managing a Linux service account, running load tests, setting up SSH access,
cron jobs, logging, and cleanup.

## Project structure

```
.
├── README.md             <- this file
├── observations.md       <- my write-up of what happened in each part
├── scripts/               <- one bash script per part of the assignment
│   ├── part1_create_service_account.sh
│   ├── part2_create_tmpfs.sh
│   ├── part3_1_fill_tmpfs.sh
│   ├── part3_2_cpu_stress_test.sh
│   ├── part3_3_memory_stress_test.sh
│   ├── part3_4_check_system_resources.sh
│   ├── part4_setup_ssh_key_auth.sh
│   ├── part5_setup_ssh_server.sh
│   ├── part6_setup_monitoring_cron.sh
│   ├── part7_setup_logging.sh
│   └── part8_cleanup_everything.sh
└── screenshots/           <- screenshots taken while running each part
```

## What each script does

| Script | Part | What it does |
|---|---|---|
| `part1_create_service_account.sh` | 1 | Creates the `bgdsvc_tas` service account. Checks first if the user already exists, so it is **safe to run more than once** (idempotent). |
| `part2_create_tmpfs.sh` | 2 | Creates a 256 MB tmpfs (RAM-based) mount for the service account to use. |
| `part3_1_fill_tmpfs.sh` | 3.1 | Fills the tmpfs with 20 x 10 MB test files and shows disk usage after each one. |
| `part3_2_cpu_stress_test.sh` | 3.2 | Installs `stress-ng` and runs a 30-second CPU load test as the service account. |
| `part3_3_memory_stress_test.sh` | 3.3 | Runs a 30-second memory (VM) load test as the service account. |
| `part3_4_check_system_resources.sh` | 3.4 | Checks memory, CPU, and the kernel log for any out-of-memory events after the load tests. |
| `part4_setup_ssh_key_auth.sh` | 4 | Generates an SSH key pair and sets up key-based login for the service account. |
| `part5_setup_ssh_server.sh` | 5 | Installs and enables the SSH server, and verifies which port it is listening on. |
| `part6_setup_monitoring_cron.sh` | 6 | Creates a monitoring script and a cleanup script, and schedules both with cron. |
| `part7_setup_logging.sh` | 7 | Sets up a log folder and a logrotate rule for the service account. |
| `part8_cleanup_everything.sh` | 8 | Undoes everything above - removes cron jobs, scripts, the tmpfs mount, logs, and finally the service account itself. |

## How to run

Each script can be run on its own, in order:

```bash
cd scripts
./part1_create_service_account.sh
./part2_create_tmpfs.sh
./part3_1_fill_tmpfs.sh
./part3_2_cpu_stress_test.sh
./part3_3_memory_stress_test.sh
./part3_4_check_system_resources.sh
./part4_setup_ssh_key_auth.sh
./part5_setup_ssh_server.sh
./part6_setup_monitoring_cron.sh
./part7_setup_logging.sh
```

Run the cleanup script last, once you are done and have taken your
screenshots, to put the system back the way it was:

```bash
./part8_cleanup_everything.sh
```

**Note:** All of the scripts use `sudo`, so they will ask for your password.
`part1` is the only one specifically written to be idempotent (safe to
re-run); the rest are meant to be run once in order, since Part 8 already
cleans everything up at the end.

## Screenshots

Screenshots for each part (terminal output, `df -h` results, `stress-ng`
output, SSH login, `crontab -l`, etc.) go in the `screenshots/` folder. Name
them by part number, for example `part1_id_output.png`, so they're easy to
match up with `observations.md`.

## Notes

- The service account used throughout this assignment is `bgdsvc_tas`.
- `observations.md` has a short write-up for every part, including the
  mistakes I made along the way and what I learned from fixing them.
