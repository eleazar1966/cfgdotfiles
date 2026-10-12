# System Profile — Gentoo Linux (eleazar)

> Base context for configuration, maintenance, and upgrade work on this machine.
> Captured 2026-09-24. Re-verified 2026-10-12 after a deep audit + maintenance pass
> (`@world` 0 pending, GLSA 0, btrfs 0 errors); values marked "verified 2026-10-12"
> were checked against the live system. Re-verify before acting on them.
> Later on 2026-10-12: **podman 6.1.2 (rootless) installed** and a **Tryton 8.2
> test environment in containers** (isolated from `miventas`) — see the
> "Container runtime (Podman, rootless)" and "Tryton 8.2 test environment" sections.
> The user speaks Spanish (Rioplatense); reply in Spanish in conversation, but keep
> generated artifacts in English unless the user explicitly asks otherwise.

## At a glance

- **Distro**: Gentoo Base System release 2.18, Portage 3.0.82.2 (python 3.14.8, gcc-16, glibc-2.44-r3), profile `default/linux/amd64/23.0/no-multilib`, testing (`~amd64` accepted)
- **Hostname**: `supertux` · **User**: `eleazar` · **Locale**: `es_VE.UTF-8`, keymap `us`
- **Init**: OpenRC (NO systemd — never use `systemctl`, use `rc-service` / `rc-update`)
- **Compositor**: niri 26.04 (live build `-116-g66d04a7d-modified`, `gui-wm/niri-9999`)
- **Shell UI**: DankMaterialShell (DMS) on quickshell 0.3.1 — config in `~/.config/DankMaterialShell`
- **Terminal**: kitty 0.49.2 (default terminal; use `kitty -e <cmd>` in desktop entries, `Terminal=true` does not work from the DMS menu)
- **Arch**: x86_64, UEFI, GRUB efi-64, AMI BIOS 3636 on ASUS PRIME B450M-A
- **Packages installed**: 1700 · in `@world`: 1012 · in `@system`: 50 (verified 2026-10-12)
- **Repos**: `gentoo` (enabled), `guru` (installed), `tryton` (enabled — mercurial overlay, not git)

## Second Gentoo install — chroot at `/mnt/gentoo`

A complete Gentoo system from **another machine** is mounted as a chroot at `/mnt/gentoo`
and is updated **from this host** to take advantage of its CPU/RAM.

- `/dev/sdb2` btrfs → `/mnt/gentoo` (and `/mnt/gentoo/home`), `/dev/sdb1` ext4 → `/mnt/gentoo/boot`
- It has its **own** `/var/lib/portage` and its **own** `/var/log/portage`. Host portage logs are untouched by a chroot emerge — check file dates to tell them apart.
- **Distinguish chroot from host processes**: `sudo readlink /proc/<pid>/root` returns `/mnt/gentoo` for the chroot, `/` for the host. A chroot `emerge` shows up in `ps` with PPID 1.
- The two Portage instances ignore each other (separate state dirs) but **compete for the 16 threads and RAM**. During a host update with the chroot also building, load average reached 20.45/16 and RAM free dropped to 349 MiB (no OOM kill). The host emerge throttles itself via `--load-average=8.0`.
- The user is aware of and accepts this contention.
- Host portage lock: `/var/lib/portage/.ipc_lock` (absent when idle). Always confirm it is free before launching a host emerge.
- **`/mnt/gentoo` and `/mnt/esp` are ordinary (empty) mountpoint directories when `/dev/sdb*` is not mounted.** Do not assume a filesystem is there.

## Hardware

### CPU
- AMD Ryzen 7 5700G (Zen 3, Cezanne), 8 cores / 16 threads, 1 socket, 1 NUMA node
- Boost up to 4673.8 MHz; microcode `0xa500014`
- Caches: L1d 256 KiB + L1i 256 KiB + L2 4 MiB (8×512 KiB), L3 16 MiB
- Flags: `avx avx2 fma bmi1 bmi2 sse4a sha_ni vaes vpclmulqdq xsavec` — **no AVX-512**
- Virtualization: AMD-V (`svm avic npt tsc_scale v_spec_ctrl`); Gather data sampling / Ghostwrite: Not affected

### Memory and tmpfs layout
- 30 GiB RAM total; swap: zram0 4 GiB, zstd, 4 streams, priority 16383 (init script `/etc/init.d/zram-init`, service `zram-init` started)
- **Portage builds run in RAM.** `PORTAGE_TMPDIR="/var/tmp"` in make.conf, and Portage **appends the `/portage` suffix**, so the real build root is `/var/tmp/portage` — which is a 24 GiB tmpfs. Observed live: `/var/tmp/portage/<category>/<pkg>/work/`.
  - **`/var/tmp` itself is NOT a mount point** — it is on the btrfs disk. Do not conclude "builds go to disk" from that; check the `/var/tmp/portage` subpath.
  - `sudo portageq get_portage_tmpdir` returns **empty** on this box and is a red herring.
  - The user's tmpfs pattern is to mount tmpfs at **subdirectories**, not over whole directories.
- Mounted tmpfs (verified 2026-10-03): `/var/tmp/portage` 24G (portage build root), `/var/tmp/tmpfs` 15.3G (opencode workspace), `/tmp` 4G, `/dev/shm` 15.3G, `/run` 15.3G, `/run/user/1000` 3.1G
- Consequence: `--jobs=1` in `actualizar.sh` is deliberate — parallel heavy packages can exhaust the 24 GiB tmpfs. A thunderbird-157.0.1 build peaked at 8.7 GiB of 24 GiB (38%).

### GPU / Graphics
- Integrated: AMD Radeon Vega 8 (Cezanne `gfx90c`), driver `amdgpu` (VIDEO_CARDS="amdgpu radeonsi")
- Mesa `media-libs/mesa-26.2.3`, radeonsi DRI; AMDGPU_TARGETS `gfx90c`
- Vulkan via RADV (installed stack); `glxinfo`/`vulkaninfo` not installed

### Storage
- `nvme0n1` CT1000P2SSD8 931.5G — p1 vfat 1.5G (ESP, **/boot not auto-mounted**), p2 btrfs 930G → `/` and `/home` (btrfs, single fs; `compress=zstd:3`, `nodiscard`)
- `sda` KINGSTON SV300S37A120G 111.8G, btrfs → `/mnt/ssd`
- `sdb` → the `/mnt/gentoo` chroot (see above)
- Usage: `/` 409G/931G (45%), `/mnt/ssd` 35G/112G (32%) (verified 2026-10-12)
- **`/mnt/valery` was REMOVED on 2026-10-12.** It was a full copy of another machine ("tux", user `valery`) sitting as a plain directory *inside* the root btrfs (NOT a subvolume, NOT a mount), 313G of which 292G was `home/`. Deleting it took `/` from 77% → 45% (~305G freed). If a similar stray tree appears, check `findmnt` and `btrfs subvolume show` before deleting.
- Health scripts: `btrfs-salud.sh` in `~/.local/bin`
- Verified 2026-10-12: 0 corruption/read/write/flush IO errors on `/` (nvme0n1p2) and `/mnt/ssd` (sda); scrub reports no errors.

### Networking
- `enp9s0` (Realtek RTL8111/8168/8211/8411): UP, **192.168.200.22/24** (DHCP, dynamic — was .20 previously) + IPv6, qdisc fq_codel — managed by NetworkManager ("Conexión cableada 1")
- `wlp8s0` (Intel Wi-Fi 6 AX200): present, currently DOWN/disconnected
- **Firewall**: nftables, service `nftables` active. Rules live in **`/var/lib/nftables/rules-save`** (there is NO `/etc/nftables.conf`); `NFTABLES_SAVE` in `/etc/conf.d/nftables`, loaded by the init script's `start_pre`. Input policy `drop`; established/related accepted; **SSH (22) rate-limited 5/min**; LocalSend (53317 tcp/udp, 40000), mDNS (5353). Added 2026-10-12: **qBittorrent 28263 tcp/udp** inbound. Edit via `nft -c -f` (check) then `nft -f` (apply). Saved `ct state` values are numeric (0x2 established, 0x4 related, 0x8 new).
- **Do not confuse the TP-Link XX530v2 with this host's network**: the user stated it is a *test router*, NOT part of their network, and is not needed for anything. Ignore it in any networking reasoning.
- **Sysctl hardening** (`/etc/sysctl.d/99-hardening.conf`): kptr_restrict=1, dmesg_restrict=1, unprivileged_bpf_disabled=2, ptrace_scope=1, syncookies=1, rp_filter=1 (v4 redirects=0, send_redirects=0, log_martians=1), and — added 2026-10-12 — **IPv6 `accept_redirects=0` (all + default)**.

### Audio
- PipeWire + WirePlumber, PulseAudio compat layer
- Sink: analog stereo; source analog stereo MUTED by default
- Bluetooth active (Blueman client); controllers: AMD Renoir/Cezanne HDMI/DP + Ryzen HD Audio

### Display
- DP-1: Samsung S19B300, 1366x768 @ 59.790 Hz (custom/preferred modeline — EDID from Realtek adapter is unreliable), physical 410×230 mm, scale 1, 16 bpc, no VRR
- DVI-D-1 and HDMI-A-1 disconnected. **1366x768 is the native panel resolution — do not push arbitrary custom modes**

### Firmware / Power
- UEFI boot; BIOS AMI 3636; GRUB_GFXMODE `1366x768x32,1366x768,auto` + `video=DP-1:1366x768` on kernel cmdline
- Desktop (no battery)

## Software stack

### Kernel
- `7.2.10-gentoo-Ryzen7-5700G` #1 SMP PREEMPT_DYNAMIC, custom build (2026-10-11) (verified 2026-10-12)
- `/usr/src/linux` → `linux-7.2.10-gentoo`; only source tree installed
- `/boot` holds **two** kernels: 7.2.9 and 7.2.10 (`vmlinuz-*`, `initramfs-*.img`, `System.map-*`, `config-*`); `eclean-kernel -n 2` keeps both, so the older artifacts are retained though not tracked by portage
- Kernel build workflow script: `kernel-do.sh` in `~/.local/bin` (invoked automatically by `actualizar.sh` when it detects newer sources)

### Toolchain (verified 2026-10-12)
- gcc 16.2.1_p20260926 (slot `x86_64-pc-linux-gnu-16`, active) · clang 23.1.3 · python 3.14.8 · node v26.11.1 · go 1.27.2 · rustc 1.99.0 · glibc 2.44-r3
- `RUSTFLAGS="-C target-cpu=znver3 -C opt-level=3"` · LLVM_TARGETS `AMDGPU X86`

### Portage profile specifics
- `COMMON_FLAGS="-march=native -O3 -pipe -flto=8"`; `CFLAGS`/`CXXFLAGS` both = `${COMMON_FLAGS}`
- CPU_FLAGS_X86: `aes avx avx2 bmi1 bmi2 f16c fma3 mmx mmxext pclmul popcnt rdrand sha sse* ssse3 vaes vpclmulqdq`
- MAKEOPTS `-j16 -l15.5`
- EMERGE_DEFAULT_OPTS `--jobs=1 --load-average=16.0 --autounmask=y --autounmask-write=y --with-bdeps=y --complete-graph=y --quiet-build=y`
- ACCEPT_LICENSE `*`; PORTAGE_COMPRESS zstd -19; BINPKG_FORMAT gpkg; PORTAGE_NICENESS 19
- **ccache**: enabled (FEATURES), `cache_dir = /var/tmp/ccache` (on the btrfs disk, not tmpfs), **`max_size = 25.0G`** (raised from 10G on 2026-10-12 — at 10G it sat at 99.9% with 5000+ cleanups). Config: `/etc/ccache.conf`.
- Key USE flags: `X wayland niri vulkan pipewire pulseaudio jack vaapi vdpau hwaccel screencast btrfs grub dracut cet elogind pam seccomp qt6 java python rust npm llvm lm-sensors amf bluetooth wifi nftables webdav nfs`
- Update helper: `actualizar.sh`, `gentoo.sh`, `ordena_uses.sh` in `~/.local/bin`
- **`/etc/portage/package.mask` is a DIRECTORY** holding **four** active masks (do not `cat` it as a file):
  - `tree-sitter-0.27` → `=dev-libs/tree-sitter-0.27.0` (neovim 0.12.5-r2 needs `=0.26*`)
  - `libdisplay-info-0.4` → `=media-libs/libdisplay-info-0.4.0` (niri-9999 + mesa need subslot 0/3)
  - `edk2-pin` → `>sys-firmware/edk2-bin-202408`
  - `rust-bin` → `dev-lang/rust-bin` (source `dev-lang/rust` is the toolchain of record; added 2026-10-07)

### Desktop audio/video apps (verified 2026-10-12)
- firefox 157.0 (dock opens private via `firefox-private` wrapper), neovim 0.12.5-r2, kitty 0.49.2, thunderbird 157.0.1, mesa 26.2.3, quickshell 0.3.1, niri 9999, **qbittorrent 5.2.4** (`net-p2p/qbittorrent`, incoming port 28263)
- git 2.56.0, curl
- No: VS Code, mpv, spotify, gh, docker, flatpak, nix (no docker — **podman 6.1.2 rootless is installed**, see Container runtime)
- Jackett runs as a service but is **not in portage** (`qlist -Iv` does not list it) — likely installed another way; listens on `0.0.0.0:9117`
- npm globals: `codegraph`, `http-server`, `markdown-pdf` (in `~/.npm-global/bin`)

### Services (OpenRC default runlevel, 47 started, 0 failed — verified 2026-10-12)
- NetworkManager, bluetooth, chronyd, cronie, display-manager, display-manager-setup, gpm, lm_sensors, local, netmount, nftables, power-profiles-daemon, sshd, sysklogd
- `zram-init`, `user.eleazar`
- `trytond` (started — **database is initialized and operational**, see below)
- `carver-recuperacion` (disk-recovery service for the `/mnt/ssd` data)
- `jackett` (manual runlevel)
- System basics also present: devfs, udev, dmesg, cgroups, hwclock, modules, fsck, swap, localmount, sysctl, bootmisc, dbus, hostname, loopback, procfs, binfmt, termencoding, keymaps, seedrng

### Tryton stack (verified 2026-10-12)
- `app-office/trytond-8.0.11` + `app-office/tryton-8.0.9` (client) + `app-tryton/*` modules (account, sale, purchase, stock, party, …), overlay `tryton` (mercurial).
- **PostgreSQL 18.6** (`dev-db/postgresql`), service name is **`postgresql-18`** (NOT `postgresql`), running, listening on 127.0.0.1:5432. `pg_hba.conf` = `trust` for local/127.0.0.1/::1.
- `trytond` runs: `trytond --config /etc/trytond/trytond.conf --logconf /etc/trytond/log.conf --database miventas`. Web client (Sao) on **http://localhost:8000**.
- Database **`miventas`** is fully initialized (**254 tables**). Postgres roles `tryton` and `trytond` both exist (login + createdb). `/etc/conf.d/trytond` sets `DATABASES="miventas"`.
- `trytond.conf` uses `uri = postgresql://tryton@localhost/` (user **`tryton`**), whereas the ebuild creates a role named **`trytond`** — both exist, so it works; keep this in mind if touching permissions.

### Container runtime (Podman, rootless — installed 2026-10-12)
- `app-containers/podman` **6.1.2** in `@world` (with crun, conmon, netavark, aardvark-dns, pasta/passt, fuse-overlayfs, catatonit). **Rootless only** — no rootful daemon.
- subuid/subgid for `eleazar` = `100000:65536` in `/etc/subuid` + `/etc/subgid`.
- **`tun` module is mandatory for pasta** (rootless default network): `CONFIG_TUN=m`, NOT auto-loaded → added `tun` to `modules=` in **`/etc/conf.d/modules`** (OpenRC `modules` service; backup `modules.bak.20261012`). Without it, `podman run` fails with `pasta failed ... Failed to open() /dev/net/tun: No such device`.
- **No bridge networks and no pods on this box**: `podman network create` (bridge) fails with `Netlink error: Operation not supported`, and pod infra containers fail by rootless overlayfs-on-btrfs (`userxattr: no such device`). Use **`--network=host`** per container instead. Storage driver is `overlay` (native); only a benign warning about `/` not being a shared mount.
- Image-user gotcha: rootless containers run under the userns; a host file mounted `600` shows as `root:root 600` inside, so a container running as a **non-root uid cannot read it** (e.g. the Tryton image runs as uid 999). Use `644` for plain read-only secret mounts.

### Tryton 8.2 test environment (containers, isolated from `miventas`)

- **NOT the production instance** — it tests the latest Tryton release without touching `miventas` (which stays on host port 8000).
- Containers (podman, `--network=host`): **`tryton-pg`** (`docker.io/library/postgres:18-alpine`, host **port 5433**) and **`tryton82`** (`docker.io/tryton/tryton:8.2` = trytond **8.2.0**, gunicorn `--bind 0.0.0.0:8001 --timeout 600`); data volume `tryton82-pgdata`. The `--timeout 600` matters: `/etc/gunicorn.conf.py` in the image sets no timeout (gunicorn default 30 s), and activating several modules from the UI exceeds it — gunicorn kills the worker mid `load_modules` (`WORKER TIMEOUT` + `SystemExit: 1`) and the wizard aborts. Raise it by recreating: `podman run -d --name tryton82 --network=host -e DB_USER=tryton -e DB_PASSWORD=tryton -e DB_HOSTNAME=127.0.0.1 -e DB_PORT=5433 -e TRYTOND_CONFIG=/etc/trytond.conf docker.io/tryton/tryton:8.2 --bind 0.0.0.0:8001 --timeout 600` (args starting with `-` are appended to gunicorn by the entrypoint).
- Access: **http://localhost:8001** · database `tryton` · login **`admin`/`admin`**. Localhost-only (nftables doesn't expose 8001/5433).
- Init: `trytond-admin -d tryton --all` == `-u ir res` → only the **80 base tables**; the rest is activated from the web UI (menu *Módulos*). The admin email is read from stdin (empty line ok); the password comes from `TRYTONPASSFILE`.
- API verified: JSON-RPC at `POST /<db>/rpc/` (`common.db.list` → `["tryton"]`, `common.server.version` → `"8.2"`) and login at `POST /<db>/session/login` with body `{"params":["admin",{"password":"admin"}]}` (→ 200 + `tryton_session` cookie; wrong password → 401).
- Restart after reboot (no OpenRC unit; containers do not auto-start): `podman start tryton-pg tryton82`. Teardown: `podman rm -f tryton82 tryton-pg && podman volume rm tryton82-pgdata`.
- **Module activation must be done via CLI, not the UI wizard**: `podman run --rm --network=host -e DB_USER=tryton -e DB_PASSWORD=tryton -e DB_HOSTNAME=127.0.0.1 -e DB_PORT=5433 docker.io/tryton/tryton:8.2 trytond-admin -d tryton -u <mods> --activate-dependencies`. The CLI has no gunicorn timeout. Base init `--all` = `-u ir res` leaves only `ir`+`res` (80 tables); activating the accounting core (`account`, `account_invoice`, `account_statement`, `account_payment` + deps) gives **13 modules / ~198 tables** on a clean base. (An earlier 282-table state came from a non-clean initial DB that also had `sale`/`purchase`/`stock` marked.) Tryton 8.2 ships the chart-of-accounts templates **inside the core `account` module** (`account_chart_es.xml` = 135 accounts), so no `account_es` package is needed.
- The **Gentoo `tryton` overlay still lacks 8.2** (mercurial tip 2026-10-04, max trytond 8.0.11 — which predates the 2026-10-05 security fixes 15032/15035). The Docker Hub image is the way to test 8.2 here.

## User environment

- `~/.local/bin` (~30 scripts): `actualizar.sh`, `actualiza_gcc.sh`, `actualiza_git.sh`, `btrfs-salud.sh`, `conectar.sh`, `gentoo.sh`, `kernel-do.sh`, `respaldo.sh`, `ordena_uses.sh`, `limpiar_musica_unificado.sh`, `moc-theme-apply.sh`, `niri-hide-scratch`, `opencode-wrapper.sh`, `setup-tryton.sh`, `qemu-creator.sh`, `graba_video.sh`, and more
- `~/tryton82/` — files for the containerized **Tryton 8.2 test env** (see above), incl. `admin.pass`
- `~/.config`: DankMaterialShell, GIMP, Jackett, MusicBrainz, OpenRGB, Thunar, Vencord, beets, btop, cava, gtk-2/3/4, quickshell (via DMS)
- Games/emulators in `~/Documentos/Juegos`: RPCS3, SHADPS4 (AppImage), HollowKnight — emulator `.desktop` files live in `~/.local/share/applications`
- `~/Documentos`: personal documents (ISLR, familia Anzola, APN Digitel)
- `/mnt/ssd` holds a disk-recovery project (`carve/`, `recup/`, `ausentes-real.txt`, `rec_hashes.tsv`, …) managed by the `carver-recuperacion` service
- Backups: `~/backups-config-*` snapshots; `respaldo.sh` for user data
- Git identity: `eleazar1966` / `anzola@gmail.com`; no stored credentials
- Icon theme: Vivid-Dark-Icons; cursor: Nordzy-cursors
- CodeGraph is available via MCP; Engram memory is the persistent store (project `eleazar`)
- **`sudo` is passwordless for `eleazar`**: `/etc/sudoers` grants `(ALL : ALL) NOPASSWD: ALL`. Convenience/risk tradeoff the user accepts.

## Running the update workflow

`actualizar.sh` steps: mount `/boot` → `emerge --sync` → `emaint` check/fix → kernel/gcc
change detection (runs `kernel-do.sh` / `actualiza_gcc.sh` if needed) → `emerge -uDvN
--with-bdeps=y --keep-going --jobs=1 --load-average=8.0 @world` → `etc-update` →
`--depclean` + `@preserved-rebuild` → `eclean-dist --deep` + `eclean-kernel -n 2` →
`updatedb` → unmount `/boot`.

**Known fragility**: the script uses `set -e` (line 2). If `emerge` returns a non-zero
status for any reason, the script dies silently at step 4 and steps 5-9 — the entire
optimization/cleanup half — never run, leaving `/boot` mounted. The only symptom is the
absence of the final "Sistema completamente actualizado y optimizado" line, so a
half-finished run is indistinguishable from a failed one at the exit-code level. The
script writes a status file to `~/.local/state/gentoo-updates/last-run.status`
(`running <ts>` / `ok <ts>`) as the on-disk signal that distinguishes the two.

Verification recipe after any update:
- `sudo emerge -p -uDvN @world` → must report **`Total: 0 packages`** (this is the correct
  closure test, not the absence of errors in the emerge log)
- `sudo glsa-check -t all` → `This system is not affected by any of the listed GLSAs`
- `sudo btrfs device stats /` → `corruption_errs 0`
- `sudo rc-status --all` and check for `failed`/`crashed`
- `sudo dmesg -T | grep -iE 'out of memory|oom'` to rule out OOM during heavy builds

## Python & Bash — syntax, debugging, logic (machine-specific)

### Runtime versions (verified 2026-10-12)
- Bash: GNU bash 5.3.20 (x86_64-pc-linux-gnu) — `#!/bin/bash` is the interpreter for all shell scripts in `~/.local/bin`
- Python: 3.14.8 via `/usr/lib/python-exec/python3.14/python3` (Gentoo `python-exec` wrapper; no venv setup in path)
- Portage itself runs on `/usr/lib/python-exec/python3.12/python3`
- Linters/checkers available: `shellcheck` + `shfmt` + `flake8` (installed via nvim/mason at `~/.local/share/nvim/mason/bin/`)
- Missing tools (do not assume them): pylint, ruff, mypy, pdb3, ipython, bats
- Also present: `sqlite3` CLI, `curl`, `git` 2.56.0
- Package queries: `qlist -Iv` outputs `category/package-version` (grep for `/pkg-name-`, not `^pkg-name-`). There is no `pacman` on this box.

### Bash syntax correctness (Gentoo context)
- Scripts must use `#!/bin/bash` (no dash/posix-only assumptions).
- Always quote expansions: `"$var"`, `"$@"` — unquoted expansion is the #1 bug class in this user's scripts.
- Arrays are the idiomatic container: `arr=(a b c)`; iterate with `for x in "${arr[@]}"`.
- Use `set -euo pipefail` in robust scripts; but remember it can mask intent — disable locally with `set +e` when a failing command is expected.
- **Beware `set -e` + long automation scripts**: any non-zero exit silently truncates the run. For multi-step maintenance scripts, prefer an explicit success marker or per-step status file over bare `set -e`.
- Parameter expansion: `${var:-default}`, `${var#prefix}`, `${var%suffix}`, `${var//pat/repl}`, `${#var}`.
- Command substitution: prefer `$(...)` over backticks (nesting).
- Exit status: check immediately after the command (`$?`), never after another command ran.

### Bash debugging workflow
- First pass: `bash -n script.sh` (syntax check only), then `bash -x script.sh` (trace execution; prefix lines with `+`).
- For partial tracing: `set -x` / `set +x` around a region, or `PS4='+ ${BASH_SOURCE}:${LINENO}: ' bash -x` for file:line traces.
- `shellcheck --shell=bash` is installed — run it before claiming a script is correct. `shfmt` can format.
- To debug the user's own tools: `~/.local/bin/opencode-wrapper.sh` writes a debug log to `/var/tmp/tmpfs/opencode/opencode-debug.log`.
- Gentoo gotcha: commands installed via `npm -g` live in `~/.npm-global/bin` (e.g. `codegraph`, `markdown-pdf`); add it to PATH inside scripts that need them (the opencode wrapper already does this).

### Python logic & debugging
- Python 3.14: use modern idioms — f-strings, `pathlib` over `os.path`, dataclasses for data containers, `match` statement where it clarifies branching.
- Immutability: prefer tuples over lists for constants; copy with `list.copy()` / `deepcopy()` to avoid alias bugs.
- Debugging without pdb3 installed: `import pdb; pdb.set_trace()` still works (pdb ships with stdlib); or use `breakpoint()` (builtin, Python 3.7+).
- Quick sanity: `python3 -m py_compile file.py` for syntax; run modules with `python3 -m module` to be cwd-safe.
- Gentoo note: `python3` resolves through `python-exec`; if multiple slots exist, check `eselect python list`.
- flake8 (mason) is available for linting style/undefined names — `flake8 file.py`; do not invent ruff/mypy availability.
- Logic traps to watch: mutable default arguments (`def f(x=[])`), late-binding closures in loops, integer division (`/` vs `//`), and `is` vs `==` for singleton/equality comparisons.

### Shared cross-language debugging
- The fastest first step for "why does this fail": run the exact command the user would run, capture stderr, and quote it back with the fix. Never fix blind.
- Preserve the existing language in artifacts the user reads; English only for generated technical artifacts unless told otherwise.
- This machine is Gentoo/OpenRC — no systemd unit debugging; services are `rc-service` / `rc-update`.

## Known constraints and pending work

1. **Tryton — database initialization: RESOLVED (2026-10-12).** `emerge --config =app-office/trytond-8.0.11` is **non-interactive and idempotent**: it only checks/creates the Postgres role `trytond` (`pquery` via `psql -U postgres -d template1`, then `createuser --createdb trytond`); it asks nothing. The database `miventas` is already initialized (254 tables) and `trytond` is serving on `localhost:8000`. `setup-tryton.sh` in `~/.local/bin` targets this.
2. **DMS application menu**: desktop entries with `Terminal=true` do not launch. Wrap terminal apps as `kitty -e <cmd>` with `Terminal=false` instead.
3. **Icon set**: custom icons must be copied into `/usr/share/icons/Vivid-Dark-Icons/apps/{16,22,32,48,64}/` + `gtk-update-icon-cache -f -t` (sudo) + `dms restart` for menu updates.
4. **Display EDID unreliable** (Realtek adapter): the custom modeline for 1366x768@59.790 is intentional and required — keep it.
5. DMS wallpaper cycling uses `wallpaperCyclingMode: interval` (300s) in session.json; the internal scheduler can lose config on restart — a kernel of past fixes lives in Engram.
6. niri build is custom and uses `load-config-file` for reloads (no stock `reload-config` action).
7. **Four `package.mask` entries are load-bearing** and must not be removed casually: they hold back `tree-sitter-0.27.0`, `libdisplay-info-0.4.0`, `edk2-bin > 202408` and `dev-lang/rust-bin`. Removing them re-introduces the `@world` dependency deadlock. The tree-sitter deadlock that previously blocked `emerge --update --deep @world` is resolved (2026-10-01) via neovim 0.12.5-r2 + dropping `tree-sitter-markdown-inline`; the mask remains as a guard.
8. **Building the host while the `/mnt/gentoo` chroot also builds** saturates all 16 threads and pushes RAM to ~350 MiB free. It survives, but heavy parallel builds are risky. Prefer one build at a time.
9. **Engram session ambiguity**: multiple `opencode` processes running against `/home/eleazar` make the Engram MCP write tools fail with "multiple active runtime sessions match". Workaround that works: the CLI, `engram save <title> <msg> --type <t> --project eleazar`, which writes to the project's manual-save session.
10. **`notification-daemon` segfaults once per boot** (`x11-misc/notification-daemon-3.20.0-r1`, in `libX11`). It is benign: the daemon is D-Bus-activated, loses the `org.freedesktop.Notifications` name to DMS, and exits. It **cannot be cleanly uninstalled** — it is in `world` and satisfies `virtual/notification-daemon`, required by `x11-libs/libnotify` with no other provider installed. Leave it.
11. **Rootless podman on this box cannot do bridge networks or pods** (Netlink/overlayfs-on-btrfs limitations) — use `--network=host` per container, and keep the `tun` module in `/etc/conf.d/modules` for pasta. Details in the "Container runtime (Podman, rootless)" section.
