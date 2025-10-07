<p align="center">
<img src="https://github.com/sl3yE/Zero-E/blob/main/wallpaper-ZeroE.png" width="530" height="424" />
</p>

# Description
Host discovery and service enumeration are part of every network pentest and routine network check. It's relatively straightforward, and some could probably do it while sleeping (you will be with this tool). But ensuring thoroughness and accuracy while maximizing efficiency is a tedious process that requires attentiveness and many manaul command entries. Zero-E (z0e) aims to automate this process in a fire-and-forget manner to free up your attention, enabling you to work on other things and save valuable time. It uses a thoughtful, extensively-tested methodology that balances thoroughness, accuracy, and efficiency. Among many other powerful functions, it generates multiple files for various analysis purposes and easy post-scan target acquisition. 

Zero in on your environment with zero experience required, taking you from zero to elite-- ...ok you get it. It's zero effort, zero error network enumeration made e-z. So embrace your inner script kiddie, sit back in your reclining ergonomic chair, and take a nap while Zero-E does your work for you.

Please consider supporting this project (especially if using it for commercial or business purposes) with Github Sponsor, [BuyMeACoffee](https://www.buymeacoffee.com/sl3yE), or Bitcoin (wallet address: 37Gofs5XGv8zB8odoFTJLv8NZk9TvwSr3i)

<p align="center">
<img src="https://github.com/sl3yE/Zero-E/blob/main/logo-ZeroE.png" width="300" height="101" />
</p>

# Features

Core automation
1. Full external & internal network enumeration workflow (alive discovery → port discovery → list consolidation → service enumeration) in a single fire‑and‑forget Bash script.
1. Dynamic methodology: external vs internal paths automatically choose different discovery strategies (Nmap batched -sn externally, tiered masscan / adaptive Nmap internally).
1. TCP & optional UDP coverage for both discovery and in‑depth service enumeration (with tuned default port sets and top‑ports logic for very large internal scopes).

Performance & efficiency
1. Batched Nmap `-sn` host discovery with auto chunk sizing and unified appendable output (resume-friendly ledger).
1. Tiered internal alive discovery: switches from Nmap to iterative masscan `--top-ports` sequences for massive (>25k) target sets.
1. Masscan resume support (paused.conf) with on‑the‑fly global `--rate` override (even mid‑resume) including automatic update of the saved config.
1. Grouped TCP service scans: hosts sharing identical open TCP port sets are scanned once (ports × group) then results are merged, dramatically reducing total Nmap runtime and host impact.
1. Automatic per‑host open port filtering and list normalization for subsequent targeted service scans (no re‑scanning closed space).

Resilience & safeguards
1. Checkpoint (stage) system with granular resume: resume entire workflow or jump to a later stage (with validations & automatic backups before destructive overwrites).
1. Session support: isolate multiple concurrent / historical scans under unique session names with independent stage files and canonical target expansions.
1. Detection & quarantine of "suspicious" hosts (>100 TCP open ports) to avoid skewing grouped scans and reduce false positives (flagged for analyst review, excluded from routine service scans).
1. DNS preflight test plus on‑demand hostname -> IPv4 resolution (via `getent`) with buffered mapping prior to output directory finalization; produces consolidated resolution log.
1. Input sanitation: merges multi‑source targets/excludes (files, CIDRs, ranges, single IPs, DNS) into normalized single‑IP canonical lists; validates syntax with rich error messages.
1. Ephemeral firewall rule insertion during internal masscan to suppress unwanted RSTs (`masscan --src-port 55555`) and safe removal afterward.
1. Output commit phase: automatic backup of important artifacts when re‑running or stage‑skipping; avoids accidental data loss.

Reporting & analysis
1. Primary output files include alive hosts, open ports, Nessus-compatible ports listing, Nmap service scan results
1. Nmap parsing helpers: Windows host extractor, IP ↔ hostname listing, targeted port presence queries, open port CSV for downstream tooling.
1. Timestamped colorized terminal output plus structured logs in `logs/` and `logs/processed/` for reproducibility & audit.

Customization & control
1. `--ngineer` mode for surgical override of default Nmap/masscan option blocks per stage while preserving mandatory include/exclude/output flags (unsafe flags sanitized).
1. `--rate` global override to force a new packet rate for all (new or resumed) masscan steps.
1. `--only` mode to run just the specified stage and/or UDP portions (e.g., follow‑on UDP enable after initial TCP‑only run).
1. Stage jump (`-S <stage>`) with validation to skip earlier phases when artifacts already exist.

Quality of life
1. Interactive prompt fallback when required primary options omitted (guided mode for newer users).
1. Rich progress spinners & realtime status for long Nmap/masscan phases; consolidated success/failure logging.
1. Single portable Bash script -- no Python, databases, or external orchestration layers required.
1. Built‑in notification support via [ntfy](https://github.com/binwiederhier/ntfy) (custom priority + self‑hosted/topic URLs) for long enterprise scans.
1. MacOS awareness (pfctl pathing) with graceful handling (core tuning primarily tested on Linux).
1. Extensive defensive checks to catch conflicting switches, malformed inputs, privilege issues, and environment gaps early.
1. Generates ephemeral working lists only when needed and cleans up safely on completion or interruption.

Analysis helpers (ad hoc)
1. Count total IPs (`--count-hosts`), generate single‑IP expansions from complex target spec (`--geniplist`), list Windows hosts, parse specific open port sets, create IP/hostname pair lists—all independent utilities available without running a full scan.

In short: Zero‑E focuses on accuracy first, then aggressive efficiency (grouped scans, adaptive batching), while maintaining auditability and useful analysis output generation.


# Requirements
- Nmap
- Masscan
- iptables (pfctl for MacOS)
- dos2unix
- realpath
- getent
- curl (if enabling ntfy notifications)


# How To

## Basic usage (interactive prompts)
1. `sudo ./zero-e` 
2. At the prompts, enter:
    1. the stage to start at
    1. the scan type (e.g. [i]nternal or [e]xternal)
    1. whether to enable UDP scans
    1. the desired file path of the output directory for generated files
    1. the file path of the file(s) containing the target IP addresses and/or single IP addresses, ranges, or CIDRs (comma-separated, e.g. targets.txt,1.1.1.1)
    1. the file path of the file(s) containing the IP addresses and/or single IP addresses, ranges, or CIDRs (comma-separated, e.g. targets.txt,1.1.1.1) to exclude from scans, if any
3. Embrace your inner script kiddie, sit back in your reclining ergonomic chair, and take a nap while z0e does your work for you

## Advanced usage
None of these switches are necessary to successfully run a full network enumeration scan. They only enable optional, but powerful, advanced features. This section explains how (and why) the notable switches alter behavior. For the exhaustive syntax at any time: `zeroe --help`.

### 1. Primary scan mode
Pick exactly one:
- `-e` External: conservative alive discovery with batched Nmap `-sn` + broad masscan port discovery.
- `-i` Internal: adaptive alive discovery (Nmap for <25k, tiered masscan for very large scopes) plus higher default rates.
- If neither provided, interactive prompts walk you through selection.

### 2. Targets & excludes
- `-t` Accepts: files, comma lists, CIDRs, single IPs, dash ranges, DNS names (all can be mixed). DNS entries are resolved and expanded to single IPs early.
- `-x` Same accepted syntax for exclusions. Supplying `-x` with no argument disables excludes and exclusion prompting.
- All sources are normalized into canonical single-IP lists; malformed lines are flagged before scans start.

### 3. Output directory & backups
- `-o <dir>` sets the working and artifact root. If omitted, defaults or prompt selects.
- On re-runs or stage skips that would overwrite critical outputs, a timestamped backup copy is made automatically (commit phase) unless disabled by context.

### 4. UDP enable / disable
- `-U` Force enable UDP.
- `-u` Force disable UDP.
- Later you can re-run with `--only -U` (or specify single UDP stages with `-S` `discovery-udp` or `services-udp`) to bolt on UDP after initial TCP work.

### 5. Stage & resume system
Stages: `discovery-hosts`, `discovery-ports`, `discovery-udp`, `discovery-lists`, `services-tcp`, `services-udp`.
- `-s` Fresh run from the top (still writes stage checkpoints for future use).
- `-S` with no value: resume from the saved stage (auto-detected).
- `-S <stage>` Skip forward (validated: prior artifacts must exist or it aborts). Auto backup if overwrite risk is detected.
- Zero-E will auto-detect existing stages if these options aren't provided

### 6. Sessions
- `--session <name>` Creates (or reuses) an isolated namespace under `/var/lib/zeroe/sessions/<name>/` holding stage, expanded targets, excludes, and variable files.
- Combine with `-S` to resume a particular historical run.
- `--session-list` enumerates existing sessions.

### 7. Performance tuning
- Automatic: Nmap `-sn` batching chooses chunk size based on target count; internal alive tier escalates masscan `--top-ports` sets; grouped TCP service scans eliminate redundant scanning.
- Manual: `--rate <pps>` sets (or overrides on resume) masscan packet rate globally; injects the new rate into masscan's _paused.conf file_, which enables changing masscan rates mid-engagement by stopping the scan, then resuming with `sudo zeroe -S --rate <nnnn>`.

### 8. ngineer mode (advanced customization)
- `--ngineer` prompts (once per stage) to append or replace predefined command option blocks.
- Enables customization of all nmap and masscan commands used throughout the methodology.
- Hard safety rails: cannot strip required persistence (`--excludefile`, `-iL`/`--include-file`, `-oA`), and risky options are sanitized.
- Good for experimentation (e.g., adjusting Nmap timing templates, adding script categories) without editing the core script.

### 9. Notifications via ntfy
- `--ntfy [priority,]<server/topic_url>` e.g. `--ntfy 3,https://ntfy.sh/myTopic`.
- Sends stage start/finish and completion messages; useful for overnight / large internal scopes.

### 10. Utility / analysis helpers (can be run standalone)
- `--count-hosts <spec>` Count total IPv4 addresses represented by a mixed target specification (files, CIDRs, ranges, IPs, DNS).
- `--count-ports <openPorts-file>` Count total distinct ports (TCP/UDP aware) in an existing Zero-E openPorts.txt results file.
- `--dns-ip <spec>` Resolve supplied DNS names (or mixed specs) to IPv4 only and output the flattened list (no scanning). Useful to validate DNS before a large run.
- `--geniplist <spec>` Emit a normalized single-IP list expansion of the mixed spec (files, ranges, CIDRs, DNS). No scanning performed.
- `--parseports <file.gnmap> <port,numbers,list>` Report which hosts have those ports open (supports comma-port list input).
- `--listwinhosts <file.nmap>` Identify probable Windows hosts (fingerprint / OS detection heuristics in Nmap output).
- `--listiphostnames <file.nmap>` Produce IP,hostname pairs extracted from service scan results.

### 11. One‑liner examples
External full run (prompts for anything missing):
```
sudo ./zero-e -e -t corp_targets.txt
```
Specify everything for an internal scan & disable UDP (faster first pass):
```
sudo ./zero-e -i -t prod.txt,10.10.0.0/22 -x legacy_excludes.txt -o /data/scan1 -u -s
```
Later run a full UDP-only enumeration after initial TCP: 
```
sudo ./zero-e -i --only -U -o /data/scan1 -s
```
Resume a previous session at the saved stage and raise masscan rate:
```
sudo ./zero-e --session q1internal -S --rate 12000
```
Count how many raw IPs a complex mixed target spec expands to:
```
./zero-e --count-hosts prod.txt,10.20.0.0/21,10.30.40.5-10.30.40.25,app.example.com
```
Resolve DNS names only (no scan) to a flat IP list:
```
./zero-e --dns-ip web1.example.com,api.example.com,targets.txt
```
Count distinct ports in a prior discovery output:
```
./zero-e --count-ports scan1/ext-openPorts.txt
```

For the full raw option list, exact flag syntax, and defaults: `zeroe --help`.

---
If required primary options aren't provided, Zero‑E will interactively prompt. Either way: embrace your inner script kiddie and let the automation work while you pivot to higher‑value analysis.

## Install to $PATH
1. Add `zero-e` to PATH, so it's able to be called as a command
    - Run the included `installz0e.sh`, which will add Zero-E to PATH for you; or use `-b` to specify a destination. 
    - If you prefer doing this manually, here's how I set mine up: I set up an alias (`z0epath`) in my shell (`~/.zshrc`) that quickly copies z0e into the primary PATH directory (`/usr/local/bin`) as `zeroe` for quick updating when changes are made 
       - `alias z0epath='sudo cp /path/to/zero-e /usr/local/bin/zeroe && sudo chmod +x /usr/local/bin/zeroe'`
    - It must be copied to _/usr/local/bin_ so it's runnable with _sudo_
    - Whenever you pull updates, rerun `installz0e.sh` or your alias
2. Run Zero-E by calling it with `zeroe` if _installz0e.sh_ was used, or whatever you named it if set up manually, with or without options: `sudo zeroe [options]`
3. Embrace your inner script kiddie, sit back in your reclining ergonomic chair, and take a nap while z0e does your work for you

## Stage system
The workflow is segmented into discrete, resumable stages. A lightweight checkpoint file records progress; resuming picks up exactly where a stage left off (masscan via its own `paused.conf`, Nmap via internal progress ledger / append output). Each session (`--session <name>`) maintains its own independent stage & variable files.

### Core concepts
- Forward-only progression: stages advance in the order shown below; you can resume or skip forward, but skipping requires prerequisite artifacts.
- Backups: If a skip or re-run would overwrite critical outputs, a timestamped backup directory is created before proceeding.
- Sessions: Provide isolation so simultaneous or historical engagements don't collide.

### Resuming
Two equivalent ways:
1. `-S` with no argument (and optional `--session <name>`): auto-detect saved stage and continue.
2. Run without the `-S` and choose Resume at the prompt (`r`).

### Specifying a stage
Use `-S <stage>` (optionally with `--session <name>`). The script validates required inputs (alive hosts list, open ports list, etc.). If anything is missing it aborts with guidance.

### Stages
Ordered progression:
1. discovery-hosts
   - Identify responsive hosts.
   - External path: batched Nmap `-sn` with tuned probes.
   - Internal path (<25k targets): Nmap `-sn` with tiered tuning; (>=25k) tiered masscan `--top-ports` with temporary firewall rule.
2. discovery-ports
   - External/Internal: masscan full 0-65535 ports against discovered alive targets.
3. discovery-udp (optional)
   - If UDP enabled: Nmap (external) or higher-rate Nmap (internal) enumerates candidate open UDP ports (default curated/top ports sets).
4. discovery-lists
   - Consolidate raw discovery output into canonical: alive hosts file, open TCP ports list, open UDP ports list (if enabled), Nessus-formatted ports list; filter >100 open TCP-port hosts.
5. services-tcp
   - In-depth Nmap service/version/OS scan across alive hosts & open TCP ports (grouped-port optimization).
6. services-udp (optional)
   - In-depth Nmap service/version scan across alive hosts & open UDP ports (when enabled).
7. methodology
   - Generate report-ready AsciiDoc methodology, appendices (ports, hosts, host→ports), DNS mapping.

### Quick reference: choosing an entry point
- Fresh start: omit `-S`/`-s` (or use `-s` explicitly) -> begins at discovery-hosts.
- Resume: `-S` with no value OR interactive resume prompt.
- Generate reporting only: `-S methodology --only` (after scans already completed) pointing at the existing output directory.
- Add UDP later: `--only -U`.

### Best practices
- Always supply the original output directory (`-o`) when skipping so derived files are found.
- Avoid skipping directly to services-* on a brand-new directory -- discovery artifacts must already exist.
- Use sessions for each distinct client/network to prevent accidental cross-contamination of stage files.

# Methodology
The methodology below reflects the current in-script logic (including dynamic adjustments, batching, resume support, and optional ngineer overrides). Angle brackets denote variable values determined at runtime.

## External
1. Alive host discovery (Nmap batched -sn)
    - Default command (batched automatically; may be split internally):
      - `nmap -n -sn --min-rate 400 --max-retries 1 --min-parallelism 32 --max-hostgroup 1024 -PE -PP -PS21,22,23,25,53,80,110,111,135,139,143,389,443,445,465,587,990,993,995,1025,1433,1521,1723,2049,2375,2376,3128,3306,3389,3690,4333,4500,5000,5432,5601,5672,5900,5985,5986,6001,6379,8000,8080,8081,8088,8181,8443,8888,9000,9200 -PA22,25,53,80,110,135,139,143,389,443,445,465,587,993,995,1433,1521,3306,3389,5900,5985,5986,8080,8443 --reason --stats-every 5m --excludefile <excludes_file> -iL <targets_file> -oA <outdir>/logs/<type>-nmapAlives-results`
    - If `--ngineer` custom options were supplied for external alives they completely replace the tuning flags (script appends required: `--excludefile -iL -oA`).
2. TCP port discovery (masscan)
    - Default (resume-aware via paused.conf, optional `--rate` override):
      - `sudo masscan --open-only -p 0-65535 --rate=5000 --excludefile <excludes_file> --include-file <alive_or_targets_list> -oG <outdir>/logs/processed/<type>-discoscan-masscan-tcp.txt`
    - If alive host list not yet present (e.g., stage jump) script falls back to original targets file. Custom ngineer options (except output/include/exclude) can override.
3. Optional UDP discovery (masscan) when UDP enabled and configured
    - Command (payloads enabled if nmap-service-probes found):
      - `sudo masscan --open-only -p <udp_ports_list> --rate=2000 [--nmap-payloads] --excludefile <excludes_file> --include-file <alive_or_targets_list> -oG <outdir>/logs/processed/<type>-discoscan-masscan-udp.txt`
    - `<udp_ports_list>` is a curated list (script variable) derived from default or ngineer override.
4. List generation
    - After discovery, the script consolidates unique alive hosts and open TCP/UDP ports; filters out hosts with >100 open TCP ports (written to `<type>-100port-hosts-tcp.txt`) and excludes them from service scans.
5. TCP service scans (Nmap)
    - For grouped port-set optimization (if enabled) hosts may be grouped, otherwise:
      - `nmap -sC -sV -Pn -O -p <csv_tcp_ports> --open --reason --excludefile <excludes_file> -iL <alive_hosts_file> -oA <outdir>/<type>-tcp-servicescan-results`
6. UDP service scans (Nmap, if UDP enabled)
    - `nmap -v -sU -Pn -sV --open --min-rate 1000 --max-rate 3000 --reason -p <csv_udp_ports> -oA <outdir>/<type>-udp-servicescan-results --excludefile <excludes_file> -iL <alive_hosts_file>`

## Internal
Internal logic bifurcates on total target count for alive host discovery (<25k uses Nmap; >=25k uses tiered masscan with adaptive `--top-ports`). All internal masscan-based steps insert a temporary firewall rule to suppress RSTs on `--src-port 55555`.

2. Alive host discovery
    - If total_hosts 1–24,999 (Nmap path): base command
      - `nmap -n -sn --max-retries 1 --min-parallelism 32 --reason -PR -PE -PP --excludefile <excludes_file> -iL <targets_file> -oA <outdir>/logs/<type>-nmapAlives-results [tiered tuning flags]`
         - Tiered tuning appended automatically:
            - 1–4,999: `--stats-every 5m --min-rate 400 --max-hostgroup 1024 -PS80,443,22,3389,8080,8443,25,587,993,995,3306,5432,445,135,139,143,110,53,1433,1521,2049,3128,5000,5601,5672,5900,5985,5986,6379,8000,8081,8888,9000,9200 -PA80,443,22,3389,445,135,25,587,993,995,3306,5432`
            - 5,000–9,999: `--min-rate 800 --max-hostgroup 2048 -PS80,443,22,3389,8080,8443,25,587,993,995,3306,5432,445,135,139,143,110,53,1433,1521,2049,3128,5000,5900,5985,5986 -PA80,443,22,3389,445,25,587,993,995`
            - 10,000–24,999: `--min-rate 1200 --max-hostgroup 2048 -PS80,443,22,3389,8080,8443,445,135,53,1433,1521,3306,5432,5900,5985,5986 -PA80,443,22,3389`
    - If total_hosts ≥ 25,000 (masscan path): iterative tiered top-ports sequence (runs one after another):
      - Base template: `sudo masscan --rate=8000 --src-port=55555 --ping --excludefile <excludes_file> --include-file <targets_file> -oG <outdir>/logs/processed/<type>-masscanalives-results.txt --top-ports <X>`
      - Top Port tiers selected based on size bracket (example sequence includes 1500,1000,500,250,150,50,20 as thresholds scale upward); exact thresholds from script blocks for progressively larger networks.
      - Set firewall rule:
          - Linux: `sudo iptables -A INPUT -p tcp --dport 55555 -j DROP`
    - Both paths support ngineer overrides (script still appends required include/exclude/output flags).
3. TCP port discovery (masscan) — alive host list preferred else original targets
    - `sudo masscan --open-only -p 0-65535 --rate=8000 --src-port=55555 --excludefile <excludes_file> --include-file <alive_or_targets_list> -oG <outdir>/logs/processed/<type>-discoscan-masscan-tcp.txt`
    - Resume supported via `masscan --resume paused.conf`; optional global `--rate` override updates paused.conf.
4. UDP discovery (Nmap) when enabled (higher internal rates)
    - `nmap -v -Pn -sU --open --min-rate 3000 --max-rate 5000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG <outdir>/logs/processed/<type>-discoscan-nmap-udp.gnmap --excludefile <excludes_file> -iL <alive_or_targets_list> -d`
5. List generation & filtering
    - Consolidates discovery results; removes >100 TCP-open hosts from service scans; converts port lists to Nessus & CSV formats.
6. Remove firewall rule (if it was set)
    - Linux: `sudo iptables -D INPUT -p tcp --dport 55555 -j DROP`
7. TCP service scans
    - `nmap -sC -sV -Pn -O -p <csv_tcp_ports> --open --reason -oA <outdir>/<type>-tcp-servicescan-results --excludefile <excludes_file> -iL <alive_hosts_file>`
    - May run in grouped-port mode (groups hosts sharing identical open-port sets) to reduce total Nmap invocations; merged afterward.
8. UDP service scans (if enabled)
    - `nmap -v -sU -Pn -sV --open --min-rate 1000 --max-rate 3000 --reason -p <csv_udp_ports> -oA <outdir>/<type>-udp-servicescan-results --excludefile <excludes_file> -iL <alive_hosts_file>`

Notes:
* `--ngineer` mode forbids overriding critical file/target flags; invalid or unsafe custom entries are sanitized.
* DNS names in targets are resolved early; mapping saved to `<outdir>/logs/<type>-dns-resolutions.txt`.
* Resume is supported for Nmap (-sn batches) via a progress ledger and for masscan via `paused.conf`.
* Hosts with extremely large open-port surfaces (>100 TCP) are segregated for analyst review to avoid distorting service scan timing.

<p align="center">
<img src="https://github.com/sl3yE/Zero-E/blob/main/logo-lazy-ZeroE.png" width=500" height="306" />
</p>
  
# To-do / Requests /  Ideas that might not make it

## To-do

- [ ] separate hosts that only respond to alive scans, but show no open ports from masscan. means they likely only responded to ping scans and don't actually have any open ports
- [ ] Nessus integration
- [ ] improve error logging
- docker-ization

## Requests

- [ ] --xtended option that references z0e-xtended script the runs tools like subfinder, gowitness, other common external and internal methodologies

## Ideas that might not make it

- [ ] GUI
- [ ] quiet/verbose mode
- [ ] add masscan speed check and adjust commands accordingly (tried this, no efficient way to do it)
