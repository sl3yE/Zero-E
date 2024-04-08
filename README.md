<p align="center">
<img src="https://github.com/Inscyght/Zero-E/blob/main/ZeroE-sticker.png" width="530" height="424" />
</p>

# Description
Host discovery and service enumeration are part of every network pentest and routine check. It's relatively straightforward, and we could all probably do it in our sleep (you will be with this tool), but doing it thoroughly is still tedious and wastes valuable time. Zero-E (ZrE) aims to automate the entire process in a fire-and-forget manner, from initial open port and live host discovery scans to in-depth scanning of only active hosts and open ports, to free up our attention to work on other things and save valuable time. It uses a thoughtful, extensively-tested methodology that balances accuracy and efficiency. It's zero effort, zero error network enumeration made easy with zero experience required. Among many other functions, it generates multiple files for various analysis purposes. So embrace your inner script kiddie, sit back in your reclining ergonomic chair, and take a nap while ZrE does your work for you.

Please consider supporting this project with [BuyMeACoffee](https://www.buymeacoffee.com/inscyght) or Bitcoin (wallet address: 37Gofs5XGv8zB8odoFTJLv8NZk9TvwSr3i)

# Features 
1. Performs initial discovery scans for alive hosts and open ports
2. Generates a file with alive hosts and a file with open TCP and UDP (if enabled) ports for reference
3. Performs in-depth TCP and UDP (if enabled) service scans against alive hosts and open ports from discovery scans
4. Includes a checkpoint system for resuming scans in case they're stopped before completion
5. Option for both external and internal scans, which changes scan methodology appropriately
6. Allows for enabling or disabling UDP scans
8. Detects, alerts on, and excludes from service scans, hosts with more than 100 ports open
    - It's highly unusual for a host to have this many ports open and indicates a possible deception host or firewall affecting scan results
9. Generates a file with open ports in Nessus-ready format for faster scanning
10. Accepts command switches, but reverts to interactive prompts if required switches are left out
11. Detects and informs you of invalid targets
12. Written in Bash for maximum compatibility and ease of use
13. Includes timestamps in terminal output and a log file for reference
14. On internal scans, which typically include more target hosts, detects the total number of hosts and adjusts scan speeds accordingly
15. Checks if running on MacOS and adjusts commands accordingly (untested)
16. Includes a `--count` option to calculate and display the total number of target IP addresses
17. Includes a  `--geniplist` option that generates a list of unique, single IP addresses from the IP addresses, ranges, and CIDRs in the passed file without needing ipcalc or prips
18. Includes a `--only` option to enable only UDP scanning and/or running only the specified stage/scan
     - Use case example: Initial run has UDP scans disabled for faster completion. Once completed, use --only and enable UDP to only run UDP scans while analyzing TCP results 
19. Includes a  `--ngineer` option that enables the entry of custom masscan and nmap options for each scan (experimental)

# Requirements
- Nmap
- Masscan
- iptables (pfctl for MacOS)
- dos2unix
- realpath
- A file containing the list of target IP addresses
    - Each single IP, range, and/or CIDR should be on a new line in typical Nmap/Masscan syntax

# How To

## Interactive Prompts (Default method)
1. `sudo ./zero-e.sh` 
2. At the prompts, enter:
    1. the stage to start at
    1. the scan type (e.g. [i]nternal or [e]xternal)
    1. whether to enable UDP scans
    1. the desired file path of the output directory for generated files
    1. the file path of the file containing the target IP addresses
    1. the file path of the file containing the IP addresses to exclude from scans, if any
3. Embrace your inner script kiddie, sit back in your reclining ergonomic chair, and take a nap while ZrE does your work for you

## Switches (Advanced)
1. `sudo ./zero-e.sh [-e || -i] [-o output_directory] [-t targets_file] [-x [excludes_file]] [-U || -u] [-S [stage] || -s] [--count filename] [--geniplist filename] [--ngineer] [--only]`
    - `--help`: Self-explanatory -- does not require sudo
    - `--count`: Calculates and displays the total number of target IP addresses -- does not require sudo
    - `--geniplist`: Generates a list of unique, single IP addresses from the IP addresses, ranges, and CIDRs in the passed file  -- does not require sudo
    - `--ngineer`: Enables entry of custom masscan and Nmap command options
	- `--only`: Only run UDP scans if enabled, and/or specified stage if provided -- does not apply to other options
    - `--defaults`: Runs ZrE using default settings -- using options with this will overwrite the default for that option
        - Default options are:
            - Stage (-S/-s) -- starts at initial alives scan
            - Targets file (-t) -- ./targets.txt
            - Output directory (-o) -- ./ZrE-output
            - Excluded targets (-x) -- none
            - UDP scans (-U/-u) -- enabled
    - `-e`: Tells ZrE to run external methodology scans -- cannot be used with -i
    - `-i`: Tells ZrE to run internal methodology scans -- cannot be used with -e
    - `-o`: Sets the output directory where generated files will be saved to
    - `-t`: Sets the file containing the target IP addresses -- each single IP, range, or CIDR must be on a new line
    - `-x`: Sets the file containing the IP addresses to exclude -- provide no argument to disable and not be prompted
    - `-U`: Enables UDP scans -- cannot be used with -u
    - `-u`: Disables UDP scans -- cannot be used with -U
    - `-S`: With no arguments, resumes from saved stage -- cannot be used with -s
        - Will skip to the specified stage, if provided -- valid stages are:
            - discovery-alives
            - discovery-openports
            - discovery-udp
            - discovery-lists
            - servicescan-tcp
            - servicescan-udp
    - `-s`: Disables stage resuming and selection and starts at initial alives scan -- cannot be used with -S
        - Stages are still saved for resuming later as ZrE runs
2. If required options aren't provided, Zero-E will revert to prompting the user for the missing option(s)
3. Embrace your inner script kiddie, sit back in your reclining ergonomic chair, and take a nap while ZrE does your work for you

## Install to $PATH
1. Add `zero-e.sh` to PATH, so it's able to be called as a command from anywhere
    - Run the included `installzre.sh`, which will add Zero-E to PATH for you; or use `-b` to specify a destination. 
    - If you prefer doing this manually, here's how I set mine up: I set up an alias (`zrepath`) in my shell (`~/.zshrc`) that quickly copies ZrE into the primary PATH directory (`/usr/local/bin`) as `zeroe` for quick updating when changes are made 
       - `alias zrepath='sudo cp /path/to/zero-e.sh /usr/local/bin/zeroe && sudo chmod +x /usr/local/bin/zeroe'`
    - It must be copied to _/usr/local/bin_ so it's runnable with _sudo_
    - Whenever you pull updates, rerun `installzre.sh` or your alias
2. Run Zero-E by calling it with `zeroe` if _zrepath.sh_ was used, or whatever you named it if set up manually, with or without options: `sudo zeroe [options]`
3. Embrace your inner script kiddie, sit back in your reclining ergonomic chair, and take a nap while ZrE does your work for you

## Stage system
- The stage function allows for resuming from the automatically saved stage, or from a specified stage
- If resuming a stage, it resumes both masscan and Nmap scans from exactly where they left off
### Resuming from a saved stage
1. Option 1: Pass the `-S` option with no arguments
2. Option 2: Run ZrE without any options
    - At the prompt, enter `y` to resume
### Restarting at a specified stage
- Skipping to a specific stage will only work if doing so after running ZrE up to that point, and specifying the previous output directory. Skipping will error if running ZrE at that stage for the first time, as certain stages require files that won't yet exist.
- ZrE will automatically create backups if it detects important output files that will be overwritten when running subsequent stages.

**Option 1:** 

- Pass the `-S` option with the desired stage name

**Option 2:** 

- Run ZrE without any options
    - At the prompt, enter the desired stage name

**Stages and explanations:**

- discovery-alives
    - The start of the external and internal scan process. 
        - External: runs an Nmap ping scan
        - Internal: runs masscan with variable (depending on the total number of initial targets)`--top-ports` to discover alive hosts
- discovery-openports 
    - External: runs masscan against all targets to discover alive hosts and open ports
    - Internal: runs masscan against all ports of alives only
- discovery-udp 
    - If UDP is enabled, runs Nmap against alives to discover open UDP ports
- discovery-lists 
    - Creates the alives list and open ports list
- servicescan-tcp 
     - Runs an in-depth Nmap service scan against alive hosts and open TCP ports 
- servicescan-udp 
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
    -Linux: `sudo iptables -A INPUT -p tcp --dport 55555 -j DROP`
    -Mac: `block drop in proto tcp from any to any port 55555" | sudo tee -a /etc/pf.conf >> $filepath/logs/mac-pfctl.log`
2. Masscan alive host discovery
    - `sudo masscan --rate=8000 --src-port=55555 --excludefile <$excludes_file> --include-file <$targets_file> -oG <$output_file>`
    - Detects total number of targets and adjusts --top-ports number accordingly to keep initial alives scan as quick as possible while remaining accurate
3. Masscan open ports discovery (customizable with `--ngineer`)
    - `sudo masscan --open-only -p 1-65535 --rate=8000 --src-port=55555 --excludefile <$excludes_file> --include-file <$targets_file> -oG`
4. UDP alive host/open port scan, if enabled (customizable with `--ngineer`)
    - `nmap -v -Pn -sU --open --min-rate 3000 --max-rate 5000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG <$output_file> --excludefile <$excludes_file> -iL <$targets_file>`
    - 15094 top ports is 99% effective. Reference [this chart](https://nmap.org/book/performance-port-selection.html) for --top-ports number effectiveness
5. Generates lists of alive hosts and open ports
6. Nmap TCP service scans (customizable with `--ngineer`)
    - `nmap -sC -sV -Pn -O -p <$open_ports> --open --reason -oA <$output_file> --excludefile <$excludes_file> -iL <$targets_file>`
7. Nmap UDP service scans, if enabled (customizable with `--ngineer`)
    - `nmap -v -sU -Pn -sV --open --min-rate 1000 --max-rate 3000 --reason -p <$open_ports> -oA <$output_file> --excludefile <$excludes_file> -iL <$targets_file>`
