<p align="center">
<img src="https://github.com/Inscyght/Zero-E/blob/main/sticker-ZeroE.png" width="530" height="424" />
</p>

# Description
Host discovery and service enumeration are part of every network pentest and routine network check. It's relatively straightforward, and some could probably do it while sleeping (you will be with this tool). But ensuring thoroughness and accuracy while maximizing efficiency is a tedious process that requires attentiveness. Zero-E (z0e) aims to automate this process in a fire-and-forget manner to free up your attention, enabling you to work on other things and save valuable time. It uses a thoughtful, extensively-tested methodology that balances thoroughness, accuracy, and efficiency. Among many other functions, it generates multiple files for various analysis purposes and easy post-scan target acquisition. 

Zero in on your environment with zero experience required, taking you from zero to elite-- ...ok you get it. It's zero effort, zero error network enumeration made e-z. So embrace your inner script kiddie, sit back in your reclining ergonomic chair, and take a nap while Zero-E does your work for you.

Please consider supporting this project (especially if using it for commercial or business purposes) with Github Sponsor, [BuyMeACoffee](https://www.buymeacoffee.com/inscyght), or Bitcoin (wallet address: 37Gofs5XGv8zB8odoFTJLv8NZk9TvwSr3i)


# Features 
1. Performs initial discovery scans for alive hosts and open ports
1. Generates a file with alive hosts and a file with open TCP and UDP (if enabled) ports for reference
1. Performs in-depth TCP and UDP (if enabled) service scans against only the alive hosts and open ports from the discovery scans
1. Includes a checkpoint system for resuming scans in case they're stopped before completion
1. Supports sessions. Useful for saving multiple scan states or running simultaneous scans (not recommended)
1. Option for both external and internal scans, which changes scan methodology appropriately
1. Allows for enabling or disabling UDP scans
1. Detects, alerts on, and excludes from service scans hosts with more than 100 ports open
   - It's highly unusual for a host to have this many ports open and indicates a possible deception host or firewall affecting scan results
1. Accepts command options, but reverts to interactive prompts if required options are left out
1. Performs a plethora of checks and includes functions to prevent as many potential scan errors as possible
1. Integrated [ntfy](https://github.com/binwiederhier/ntfy) functionality for sending notifications to your devices
    - Useful for large networks with long scan times
1. For internal scans, which typically include more target hosts, detects the total number of hosts and adjusts scan speeds accordingly
1. Includes functions to calculate the total number of target IP addresses, and to generate a list of unique, single IP addresses from the provided file(s) and/or IP(s) without needing ipcalc or prips
1. Generates a file with open ports in Nessus-ready format for faster vulnerability scanning
1. Written as a single Bash script for maximum portability, compatibility, and ease of use
1. Includes timestamps in terminal output and a log file for reference
1. Checks if running on MacOS and adjusts commands accordingly (untested)
1. Includes an option to enable only UDP scanning and/or running only the specified stage/scan
   - Use case example: Initial run has UDP scans disabled for faster completion. Once completed, and while analyzing TCP results, use `--only` and enable UDP to only run UDP scans 
1. Has a function that enables the entry of custom masscan and nmap options for each step in the scanning process (experimental)
1. Includes functions that parse Nmap output and create lists for various analysis purposes, which also run automatically during scans.


# Requirements
- Nmap
- Masscan
- iptables (pfctl for MacOS)
- dos2unix
- realpath
- curl (if enabling ntfy notifications)


# How To

## Basic usage (interactive prompts)
1. `sudo ./zero-e` 
2. At the prompts, enter:
    1. the stage to start at
    1. the scan type ([i]nternal or [e]xternal)
    1. whether to enable UDP scans
    1. the desired file path of the output directory for generated files
    1. the file path of the file(s) containing the target IP addresses and/or single IP addresses, ranges, or CIDRs (comma-separated, e.g. targets.txt,1.1.1.1/24)
    1. the file path of the file(s) containing the IP addresses and/or single IP addresses, ranges, or CIDRs (comma-separated, e.g. excludes.txt,1.1.1.1/24) to exclude from scans, if any
3. Embrace your inner script kiddie, sit back in your reclining ergonomic chair, and take a nap while z0e does your work for you

## Advanced usage (switches)
1. 
````
sudo $(basename $0) [-e | -i] [-o <output_directory>] [-t <targets_file(s) and/or IP(s)>] [-x [excludes_file and/or IP(s)]]
                     [-U | -u] [-S [stage] | -s]
                     [--defaults] [--ngineer] [--only]
                     [--count <filename(s) and/or IP(s)>] [--geniplist <filename(s) and/or IP(s)>]
                     [--listwinhosts <StandardNmapFile> [OutputFile]]
                     [--parseports <GrepableNmapFile> <Comma,Separated,Ports> [OutputFileName]]
                     [--listiphostname <StandardNmapFile> [OutputFile]]
                     [--ntfy [priority,]<server/topic_url>] [--session <session_name>]
                     [--help] [--version]
	
PRIMARY OPTIONS (z0e will prompt for these if not provided):
  -e                      Run external assessment scans (cannot be used with -i)
  -i                      Run internal assessment scans (cannot be used with -e)
  -o <dir>                Set output directory for generated files
  -t <file(s) and/or IPs> Provide target IP addresses and/or files in a comma-separated list (file.txt,1.1.1.1)
                            Supports single IPs, ranges, or CIDR notation
  -x [file(s) and/or IPs] Provide target IP addresses and/or files to exclude in a comma-separated list (file.txt,1.1.1.1)
                            Supports single IPs, ranges, or CIDR notation -- Omit argument to disable exclusion prompt
  -U                      Enable UDP scans (cannot be used with -u)
  -u                      Disable UDP scans (cannot be used with -U)
  -S [stage]              If no stage provided, resume from saved stage (cannot be used with -s)
                            If stage provided, skip to the specified stage
                            Available stages:
                              - discovery-hosts (TCP-only)
                              - discovery-ports (TCP-only)
                              - discovery-udp
                              - discovery-lists
                              - services-tcp
                              - services-udp
  -s                      Start from the beginning (disables stage resuming but still saves stages for later resumption)

AUXILIARY OPTIONS (Enable additional functionality):
  --defaults                   Run z0e with default settings (overridden by explicitly provided options)
                                 Default settings:
                                   - Stage (-S/-s): Starts at initial alives scan
                                   - Targets file (-t): ./targets.txt
                                   - Output directory (-o): ./z0e-output
                                   - Excluded targets (-x): None
                                   - UDP scans (-U/-u): Enabled
  --ngineer                    Enable entry of custom command options
  --only                       Run only UDP scans (if enabled) and/or specified stage (does not apply to other options)
  --count <file(s) and/or IPs> Count total IP addresses in the provided comma-separated file(s) and/or IPs (does not require sudo)
  --geniplist <file(s) and/or IPs>
                               Generate a list of single IP addresses from the provided comma-separated file(s) and/or IPs
                                 (does not require sudo)
  --listwinhosts <NmapFile> [OutputFile]
                               Parse a standard Nmap file (.nmap) to list IP addresses of Windows hosts (does not require sudo)
  --parseports <GrepableNmapFile> <Comma,Separated,Ports> [OutputFileName]
                               Parse a grepable Nmap file (.gnmap) for hosts with specified open ports
                                 and output results in a readable format (does not require sudo)
  --listiphostnames <NmapFile> [OutputFile]
                               Parse a standard Nmap file (.nmap) to list IP address and hostname pairs
                                 (does not require sudo)
  --ntfy [priority,]<server/topic_url>
                               Enable ntfy notifications (priority 1-5 optional, followed by server/topic URL)
  --session <name>             Enable session functionality (provide a new or existing session name)
                                 To resume a session, provide the session name with the -S option
  --help                       Display this help message
  --version                    Display the version of Zero-E
````
2. If required options aren't provided, Zero-E will prompt you for the missing option(s)
3. Embrace your inner script kiddie, sit back in your reclining ergonomic chair, and take a nap while z0e does your work for you

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
- The stage function allows for resuming from the automatically saved stage, or from a specified stage
- If resuming a stage, it resumes both masscan and Nmap scans from exactly where they left off
- If creating a session with `--session`, each session will have its own saved stage
### Resuming from a saved stage
1. Option 1: Pass the `-S` option with no arguments
    - Also include `--session <session_name>` if the initial scan was in a session
2. Option 2: Run z0e without any options (or with `--session <session_name>`)
    - At the prompt, enter `r` to resume
### Starting at a specified stage
- Skipping to a specific stage will only work if doing so after running z0e up to that point, and specifying the previous output directory. Skipping will error if running z0e at that stage for the first time, as certain stages require files that won't yet exist.
- z0e will automatically create backups if it detects important output files that will be overwritten when running subsequent stages.

**Option 1:** 

- Pass the `-S` option with the desired stage name

**Option 2:** 

- Run z0e without any options
    - At the prompt, enter the desired stage name

**Stages and explanations:**

- discovery-hosts
    - The start of the external and internal scan process. 
        - External: runs an Nmap ping scan
        - Internal: runs masscan with variable (depending on the total number of initial targets) `--top-ports` to discover alive hosts
- discovery-ports 
    - External: runs masscan against all targets to discover alive hosts and open ports
    - Internal: runs masscan against all ports of alives only
- discovery-udp 
    - If UDP is enabled, runs Nmap against alives to discover open UDP ports
- discovery-lists 
    - Creates the alives list and open ports list
- services-tcp 
     - Runs an in-depth Nmap service scan against alive hosts and open TCP ports 
- services-udp 
    - Runs an in-depth Nmap service scan against alive hosts and open UDP ports 

# Methodology
## External
1. Nmap alive host discovery
   - `sudo nmap -n -vv -sn -oG - --excludefile <$excludes_file> -iL <$targets_file>`
2. Masscan open port/alive host discovery (customizable with `--ngineer`)
   - `sudo masscan --open-only -p 1-65535 --rate=5000 --excludefile <$excludes_file> --include-file <$targets_file> -oG <$output_file>`
3. UDP alive host/open port scan, if enabled  (customizable with `--ngineer`)
   - `sudo nmap -v -Pn -sU --open --min-rate 1000 --max-rate 3000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG <$output_file> --excludefile <$excludes_file> -iL <$targets_file> -d`
   - 15094 top ports is 99% effective. Reference [this chart](https://nmap.org/book/performance-port-selection.html) for --top-ports number effectiveness
4. Generates lists of alive hosts and open ports
5. Nmap TCP service scans (customizable with `--ngineer`)
   - `sudo nmap -sC -sV -Pn -O -p <$open_ports> --open --reason --excludefile <$excludes_file> -iL <$targets_file> -oA <$output_file>`
6. Nmap UDP service scans, if enabled (customizable with `--ngineer`)
   - `sudo nmap -v -sU -Pn -sV --open --min-rate 1000 --max-rate 3000 --reason -p <$open_ports> -oA <$output_file> --excludefile <$excludes_file> -iL <$targets_file>`
  
## Internal
1. Creates a firewall rule to prevent RST packets from interfering with scans
    - Linux: `sudo iptables -A INPUT -p tcp --dport 55555 -j DROP`
    - Mac: `cp "/etc/pf.conf" "$filepath/logs/pf.conf.bak-prescript" && block drop in proto tcp from any to any port 55555" | sudo tee -a /etc/pf.conf && sudo pfctl -f /etc/pf.conf` (untested)
2. Masscan alive host discovery
    - `sudo masscan --rate=8000 --src-port=55555 --top-ports <variable> --excludefile <$excludes_file> --include-file <$targets_file> -oG <$output_file>`
    - Detects total number of targets and adjusts `--top-ports` number accordingly to keep initial alives scan as quick as possible while remaining accurate
3. Masscan open ports discovery (customizable with `--ngineer`)
    - `sudo masscan --open-only -p 1-65535 --rate=8000 --src-port=55555 --excludefile <$excludes_file> --include-file <$targets_file> -oG`
4. UDP alive host/open port scan, if enabled (customizable with `--ngineer`)
    - `nmap -v -Pn -sU --open --min-rate 3000 --max-rate 5000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG <$output_file> --excludefile <$excludes_file> -iL <$targets_file>`
    - 15094 top ports is 99% effective. Reference [this chart](https://nmap.org/book/performance-port-selection.html) for `--top-ports` number effectiveness
5. Removes the firewall rule
   - Linux: `sudo iptables -D INPUT -p tcp --dport 55555 -j DROP`
   - Mac: `cp "/etc/pf.conf" && sudo sed -i "/block drop in proto tcp from any to any port 55555/d" /etc/pf.conf && sudo pfctl -f /etc/pf.conf` (untested)
   	 - If `pfctl` was originally disabled: `sudo pfctl -d`
5. Generates lists of alive hosts and open ports
6. Nmap TCP service scans (customizable with `--ngineer`)
    - `nmap -sC -sV -Pn -O -p <$open_ports> --open --reason -oA <$output_file> --excludefile <$excludes_file> -iL <$targets_file>`
7. Nmap UDP service scans, if enabled (customizable with `--ngineer`)
    - `nmap -v -sU -Pn -sV --open --min-rate 1000 --max-rate 3000 --reason -p <$open_ports> -oA <$output_file> --excludefile <$excludes_file> -iL <$targets_file>`
  
# Planned improvements
- Stuff I happen to think of
- Docker-ization
- Option to automate launching Nessus scans
