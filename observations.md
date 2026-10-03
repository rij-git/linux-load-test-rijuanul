# Observations - DevOps Lab Assignment

**Name:** Rijuanul
**Course:** DevOps
**Topic:** Creating and managing a Linux service account (load testing, SSH access, cron jobs, logging, cleanup)
**Service account used:** `bgdsvc_tas`

---

## Part 1: Create a service account

**Commands used:**
```bash
id "$SVC_NAME"
getent passwd "$SVC_NAME"
```

**Observation:**
The service account `bgdsvc_tas` was created successfully. Running `id` on it showed UID 997 and GID 985, and `getent passwd` showed its home directory as `/home/bgdsvc_tas` with the login shell set to `/usr/sbin/nologin`. Since the shell is `nologin`, nobody can actually log into this account directly - it can only be used to run background services. This is the normal setup for a service account.

---

## Part 2: Create a tmpfs mount for the service account

**Commands used:**
```bash
sudo mkdir -p "/mnt/${SVC_NAME}_tmp"
sudo mount -t tmpfs -o size=256M tmpfs "/mnt/${SVC_NAME}_tmp"
sudo chown "$SVC_NAME:$SVC_NAME" "/mnt/${SVC_NAME}_tmp"
df -h "/mnt/${SVC_NAME}_tmp"
```

**Observation:**
A 256 MB tmpfs filesystem was created and mounted at `/mnt/bgdsvc_tas_tmp`. `df -h` confirmed the size (256M), with 0% used and all 256M available right after mounting. Ownership was given to `bgdsvc_tas` so the service account can write to it. Since tmpfs is memory-backed, anything stored here will disappear if the system restarts or the mount is removed - it is not permanent storage.

---

## Part 3.1: Fill the tmpfs with test files

**Commands used:**
```bash
for i in $(seq 1 20); do
  dd if=/dev/urandom of="/mnt/${SVC_NAME}_tmp/file_$i.dat" bs=1M count=10
  df -h "/mnt/${SVC_NAME}_tmp"
done
```

**Observation:**
This loop created 20 files of 10 MB each (random data) inside the tmpfs mount. After each file, `df -h` showed the used space going up by about 10 MB. By the time all 20 files were created, roughly 200 MB out of the 256 MB was used, leaving about 56 MB free. This shows how quickly a tmpfs can fill up since it is really just using RAM.

---

## Part 3.2: Install stress-ng and run a CPU stress test

**Commands used:**
```bash
sudo apt install stress-ng -y
sudo -u "$SVC_NAME" stress-ng --temp-path "/mnt/${SVC_NAME}_tmp" --cpu 2 --timeout 30s
```

**Observation:**
`stress-ng` was installed with apt without any issues. The first attempt to run it as the service account failed with `aborting: temp-path '.' must be readable and writeable`, because the service account's current folder is not writable. I also tried the flag `--tmp-path`, which doesn't exist - the correct flag is `--temp-path`. After pointing `--temp-path` at the tmpfs folder from Part 2, the CPU stress test ran successfully: 2 CPU workers ran for 30 seconds, 2 passed, 0 failed, 0 skipped.

**Lesson learned:** Always double check flag names with `stress-ng --help`, and remember that a service account with a restricted environment may need to be told explicitly where it is allowed to write temp files.

---

## Part 3.3: Run a memory (VM) stress test

**Commands used:**
```bash
sudo -u "$SVC_NAME" stress-ng --temp-path "/mnt/${SVC_NAME}_tmp" --vm 1 --vm-bytes 200M --timeout 30s
```

**Observation:**
My first try used `--vm1` which is not a valid option - it has to be `--vm 1` (with a space). I also made a typo using `${SERVICE_NAME}` instead of `${SVC_NAME}`, which produced an invalid empty path (`/mnt/_tmp`). After fixing both issues, the test ran successfully: 1 VM worker allocated 200 MB of memory out of 6.89 GB available, ran for about 30 seconds, and passed with 0 failures.

**Lesson learned:** Small typos in variable names can be hard to spot - the error message (`path '/mnt/_tmp'`) was actually a clue that a variable was empty.

---

## Part 3.4: Check system resources after the stress tests

**Commands used:**
```bash
free -h
top
dmesg | grep -i oom
```

**Observation:**
After the stress tests finished, `free -h` showed about 1.6 GiB used out of 7.7 GiB total RAM, with 6.1 GiB still available. Swap usage was about 893 MiB out of 2 GiB. `top` showed CPU at 100% idle, meaning no load was running anymore, and there were no stopped or zombie processes. Checking `dmesg | grep -i oom` showed no Out-Of-Memory messages, which means the stress tests used memory safely and did not push the system into an OOM (out-of-memory) situation.

---

## Part 4: Set up SSH key-based login for the service account

**Commands used:**
```bash
ssh-keygen -t ed25519 -f ~/.ssh/${SVC_NAME}_key
sudo mkdir -p "/home/$SVC_NAME/.ssh"
sudo cp ~/.ssh/${SVC_NAME}_key.pub "/home/$SVC_NAME/.ssh/authorized_keys"
sudo chown -R "$SVC_NAME:$SVC_NAME" "/home/$SVC_NAME/.ssh"
sudo chmod 700 "/home/$SVC_NAME/.ssh"
sudo chmod 600 "/home/$SVC_NAME/.ssh/authorized_keys"
```

**Observation:**
An ed25519 SSH key pair was generated for the service account. My first attempt to copy the public key failed because I typed `,ssh` instead of `.ssh` in the path by mistake. After fixing that typo, the key copied correctly into `authorized_keys`. I then set ownership to the service account and the correct permissions (`700` for the `.ssh` folder, `600` for `authorized_keys`) - SSH refuses to use a key if the permissions are too open, so this step is required.

I also tried to connect using a placeholder `<server-ip>` without actually replacing it with a real address, which obviously failed. After finding the real IP with `hostname -I`, the connection still failed with "Connection refused" - this was actually because the SSH **server** wasn't installed or running yet (see Part 5).

**Lesson learned:** Having a valid key is not enough - the SSH *server* also has to be installed, running, and reachable on the right port before any key will work.

---

## Part 5: Install and enable the SSH server

**Commands used:**
```bash
sudo apt install openssh-server -y
sudo systemctl enable --now ssh
sudo systemctl restart ssh
sudo ss -tlnp | grep ssh
```

**Observation:**
`sudo service ssh status` first reported `Unit ssh.service could not be found`, which told me the SSH server package wasn't installed at all. My first install attempt had a typo (`openssh -server` with a space), which apt rejected. After fixing it to `openssh-server`, the install worked, and `sudo systemctl enable --now ssh` started the service and enabled it to start on boot.

Once the server was running, connecting with the SSH key worked - the login banner appeared and no password was asked, which confirms key-based authentication was accepted. However, the session closed right away with the message `This account is currently not available`. This is expected: the service account's shell is `/usr/sbin/nologin`, so SSH authenticates it successfully but then refuses to give it an interactive shell, which is exactly the behaviour we want for a service account.

I later tried changing the SSH port to `2222` in `/etc/ssh/sshd_config`. After editing the file, `sudo sshd -T | grep '^port'` showed `port 2222`, but the actual running service was still listening on port 22 (confirmed with `ss -tlnp`). 

**Lesson learned:** `sshd -T` only tells you what the config file currently says, not what the already-running service is using. The service must be restarted with `systemctl restart ssh` for a config change to actually take effect, and it's always worth double-checking with `ss -tlnp` afterward to see the real listening port.

---

## Part 6: Create monitoring/cleanup scripts and schedule them with cron

**Commands used:**
```bash
sudo nano /usr/local/bin/${SVC_NAME}_monitor.sh
sudo chmod +x /usr/local/bin/${SVC_NAME}_monitor.sh
sudo nano /usr/local/bin/${SVC_NAME}_cleanup_old_files.sh
sudo chmod +x /usr/local/bin/${SVC_NAME}_cleanup_old_files.sh
sudo crontab -e -u "$SVC_NAME"
```

**Observation:**
Two scripts were created: one to monitor memory/disk usage (`bgdsvc_tas_monitor.sh`) and one to clean up old test files (`bgdsvc_tas_cleanup_old_files.sh`). Both were made executable with `chmod +x`. Along the way I made two typos - `chmd` instead of `chmod`, and `corntab` instead of `crontab` - both were easy to spot because the shell said "command not found".

When editing the service account's crontab, I had to pick an editor first, and my cron lines (`*/5 * * * * ...` and `0 2 * * * ...`) ended up accidentally typed in response to the "choose an editor" prompt instead of inside the actual crontab file. I fixed this by re-running `crontab -e` and confirming the two lines were saved correctly with `crontab -l`.

**Lesson learned:** When a prompt like "Choose 1-4 [1]:" is still showing, the terminal is still waiting for that input - anything typed goes to the prompt, not into the file you expect to be editing.

---

## Part 7: Set up logging and logrotate

**Commands used:**
```bash
sudo mkdir -p "/var/log/$SVC_NAME"
sudo chown "$SVC_NAME:$SVC_NAME" "/var/log/$SVC_NAME"
sudo nano "/etc/logrotate.d/$SVC_NAME"
sudo logrotate -f "/etc/logrotate.d/$SVC_NAME"
ls -lh "/var/log/$SVC_NAME/"
```

**Observation:**
A log directory `/var/log/bgdsvc_tas` was created and given to the service account. A logrotate configuration was written at `/etc/logrotate.d/bgdsvc_tas` so the log file gets rotated instead of growing forever. Running `logrotate -f` to force a test rotation completed with no errors, and `ls -lh` confirmed a `monitor.log` file existed, owned by `bgdsvc_tas`, at 481 bytes. This confirms the monitoring script (from Part 6) is actually writing logs, and that logrotate is configured correctly for it.

---

## Part 8: Clean up everything

**Commands used:**
```bash
sudo pkill -u "$SVC_NAME"
sudo crontab -r -u "$SVC_NAME"
sudo rm -f "/etc/logrotate.d/$SVC_NAME"
sudo rm -f "/usr/local/bin/${SVC_NAME}_monitor.sh"
sudo rm -f "/usr/local/bin/${SVC_NAME}_cleanup_old_files.sh"
sudo umount "/mnt/${SVC_NAME}_tmp"
sudo rmdir "/mnt/${SVC_NAME}_tmp"
sudo rm -rf "/var/log/$SVC_NAME"
sudo userdel -r "$SVC_NAME"
```

**Observation:**
Everything created during the assignment was removed, in this order: killed any leftover processes owned by the service account, removed its crontab, removed the logrotate config and the two `/usr/local/bin` scripts, unmounted and deleted the tmpfs folder, deleted the log folder, and finally deleted the user account itself with `userdel -r`.

I made one small typo - `unmount` instead of `umount` - the shell reminded me `umount` is the correct command. `userdel -r` also printed a harmless warning that the mail spool didn't exist, which is normal since this account never used mail. Afterwards, `id "$SVC_NAME"` confirmed the user no longer exists, and `mount | grep "$SVC_NAME"` showed nothing, confirming no leftover mount points remained.

---

## Overall Conclusion

This assignment walked through the full lifecycle of a Linux service account: creating it safely, giving it its own temporary storage, load-testing the system under CPU and memory pressure, setting up secure key-based SSH access, automating monitoring and cleanup with cron, configuring log rotation, and finally removing everything cleanly so the system is left in its original state.

Most of the mistakes I ran into were small things - typos in variable names or command names, flags that didn't exist, or forgetting to restart a service after changing its config. Reading the actual error message carefully was usually enough to figure out what had gone wrong and fix it on the next try.
