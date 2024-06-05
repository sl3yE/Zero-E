#!/usr/bin/env bash
version="Zero-E (ZrE) v1.0.3"

###Functions added update check (public) | 
function updatecheck { #Check version and update the script
	URL="https://raw.githubusercontent.com/inscyght/zero-e/main/zero-e.sh"
    #Function to get the latest version string from the script on GitHub
    get_latest_version() {
        curl -s $URL | grep -m 1 '^version=' | awk -F'"' '{print $2}'
    }
    #Function to update the script
    update_script() {
        curl -o zero-e.sh $URL
        chmod +x zero-e.sh
    }
    latest_version=$(get_latest_version)
    if [ "$version" != "$latest_version" ]; then
        echo "A new version of Zero-E is available: $latest_version"
        read -p "Do you want to update to the latest version? <y/n>: " response
        if [ "$response" == "y" ]; then
            echo "Updating..."
            update_script
            echo "Zero-E updated to version $latest_version -- please re-run ZrE"
            exit 0
        else
            echo "Continuing with the local version"
			echo ""
        fi
    fi
}

function settype { #Set external or internal
	if [ "$e_opt" = true ] || [ "$i_opt" = true ]; then
		if [ "$e_opt" = true ]; then
			typevar="ext"
			i_opt=false
		elif [ "$i_opt" = true ]; then
			typevar="int"
			e_opt=false
		fi
	else
		echo "[?] Are you performing an <e>xternal or <i>nternal scan?"
		while true; do
			read -e -p " [>] " type
			if [ "$type" = "E" ] || [ "$type" = "e" ] || [ "$type" = "external" ] || [ "$type" = "External" ] || [ "$type" = "Ext" ] || [ "$type" = "ext" ]; then
				typevar="ext"
				e_opt=true
				break
			elif [ "$type" = "I" ] || [ "$type" = "i" ] || [ "$type" = "internal" ] || [ "$type" = "Internal" ] || [ "$type" = "Int" ] || [ "$type" = "int" ]; then
				typevar="int"
				i_opt=true
				break
			else
				echo -e "\e[31m [X] Error: You must enter 'e' for external or 'i' for internal \e[0m"
			fi
		done
	fi
}

function output {
	if [ -z "$o_opt" ] && [ "$defaults" = true ]; then
		filepath="./zre-output"
	elif [ -n "$o_opt" ]; then
		filepath="$o_opt"
	else
		echo "[?] Enter the output directory path:"
		while true; do
			read -e -p " [>] " filepath
			if [ -f "$filepath" ]; then
				echo -e "\e[31m [X] Error: File exists with the same name \e[0m"
			elif [ -z "$filepath" ]; then
				echo -e "\e[31m [X] Error: You must enter a directory name or path \e[0m"
			elif [[ "$filepath" == "-"* ]]; then
				echo -e "\e[31m [X] Error: Directory names starting with '-' may cause issues with commands \e[0m"
			elif [[ "$filepath" == *" "* ]]; then
				echo -e "\e[31m [X] Error: To proactively avoid errors, whitespace is not allowed in file names \e[0m"
			elif [ -n "$filepath" ]; then
				break
			fi
		done
	fi
	if [ "$filepath" = "." ]; then
		filepath=$(pwd)
	elif [ "$filepath" = "~" ]; then
		filepath="/home/$SUDO_USER"
	elif [[ "$filepath" = '~/'* ]]; then
		filepath=${filepath/#\~/"/home/$SUDO_USER"}
		if [ ! -d "$filepath" ];then
			mkdir -p "$filepath"
		fi
	else
		if [ ! -d "$filepath" ];then
			mkdir -p "$filepath"
		fi
	fi

	###Create backup of output dir if scans have already ran
    local shouldBackup=false
    # Check for specific files in the $filepath and $filepath/reporting directories
    if [ "$typevar" = "ext" ] && [ "$(find $filepath -maxdepth 1 -type f \( -name 'ext-*' \) 2>/dev/null)" ]; then # ||	[ "$typevar" = "ext" ] && [ "$(find $filepath/reporting -maxdepth 1 -type f -name '' 2>/dev/null)" ]
        shouldBackup=true
    elif [ "$typevar" = "int" ] && [ "$(find $filepath -maxdepth 1 -type f \( -name 'int-*' \) 2>/dev/null)" ]; then # || [ "$typevar" = "int" ] && [ "$(find $filepath/reporting -maxdepth 1 -type f -name '' 2>/dev/null)" ]
        shouldBackup=true
    fi
    # Proceed with backup if necessary
    if [ "$shouldBackup" = true ]; then
        # The directory contains specific files indicating significant script activity,
        # find the next available ZrEscan#.bak name for backup
        local baseDir=$(dirname "$filepath")
        local name=$(basename "$filepath")
        local prefix="${name}-ZrE"
        local suffix=".bak"
        local idx=1
        while true; do
            if [ ! -d "$baseDir/$prefix$idx$suffix" ]; then
                break
            fi
            ((idx++))
        done
        local newDir="$baseDir/$prefix$idx$suffix"
        echo "     ZrE results files detected in output directory -- backing up '$filepath' to '$newDir'"
        cp -r "$filepath" "$newDir"
    fi

	mkdir -p $filepath/logs/
	mkdir -p $filepath/logs/misc-files/
	#mkdir -p $filepath/reporting/

	o_opt="$(realpath $filepath)"
	filepath="$(realpath $filepath)"
}

function targets {	
	if [[ -z "$t_opt" && "$defaults" = true ]]; then
		ips="targets.txt"
		if [[ ! -f "$ips" ]]; then
			echo -e "\e[31m [X] Error: The default targets file (./targets.txt) does not exist \e[0m"
			exit 1
		elif [ ! -s "$ips" ]; then #Check if the file is empty
        	echo -e "\\e[31m [X] Error: $ips is empty \\e[0m"
			exit 1
		fi
		checkfile="$ips"
		checkinvalidips #Check targets file for invalid entries
	elif [ -n "$t_opt" ]; then
		if [[ "$t_opt" == "-"* ]]; then
			echo -e "\e[31m [X] Error: File names starting with '-' may cause issues with commands \e[0m"
			exit 1
		elif [[ "$t_opt" == *" "* ]]; then
			echo -e "\e[31m [X] Error: To proactively avoid errors, whitespace is not allowed in file names \e[0m"
			exit 1
		elif [ ! -s "$t_opt" ]; then #Check if the file is empty
        	echo -e "\\e[31m [X] Error: $t_opt is empty \\e[0m"
			exit 1
		fi
		ips="$t_opt"
		checkfile="$ips"
		checkinvalidips #Check targets file for invalid entries
	else
		echo "[?] Enter the target IP addresses file -- each single IP, range, or CIDR must be on a new line: "
		while true; do
			read -e -p " [>] " ips
			if [[ -z "$ips" ]] || [[ ! -f "$ips" ]]; then
				echo -e "\e[31m [X] Error: You must pass an existing file containing the IP addresses (e.g. targets.txt) \e[0m"
			elif [ ! -s "$ips" ]; then #Check if the file is empty
        		echo -e "\\e[31m [X] Error: $ips is empty \\e[0m"
			else
				if [[ "$ips" == "-"* ]]; then
					echo -e "\e[31m [X] Error: File names starting with '-' may cause issues with commands \e[0m"
				elif [[ "$ips" == *" "* ]]; then
					echo -e "\e[31m [X] Error: To proactively avoid errors, whitespace is not allowed in file names \e[0m"
				else
					checkfile="$ips"
					checkinvalidips #Check targets file for invalid entries
					if [[ $allvalid = 1 ]]; then
						t_opt="$ips"
						break
					fi
				fi
			fi
		done
	fi

	t_opt="$(realpath $ips)"
	ips="$(realpath $ips)"
	echo "     Generating temporary list of single IP addresses for targets..."
	geniplist "$ips" > /tmp/zeroe/targets-single-ips.zre
	ips="/tmp/zeroe/targets-single-ips.zre"
	t_opt="/tmp/zeroe/targets-single-ips.zre"
}

function excludes {
	if [ -z "$x_opt" ] && [ "$defaults" = true ]; then
		mkdir -p /tmp/zeroe
		touch /tmp/zeroe/nullexcludes.zre
		nostrikes="/tmp/zeroe/nullexcludes.zre"
	elif [ -n "$x_opt" ]; then
		if [[ "$x_opt" == "-"* ]]; then
			echo -e "\e[31m [X] Error: File names starting with '-' may cause issues with commands \e[0m"
			exit 1
		elif [[ "$x_opt" == *" "* ]]; then
			echo -e "\e[31m [X] Error: To proactively avoid errors, whitespace is not allowed in file names \e[0m"
			exit 1
		elif [ ! -s "$x_opt" ]; then #Check if the file is empty
        	echo -e "\\e[31m [X] Error: $x_opt is empty \\e[0m"
			exit 1
		fi
		nostrikes="$x_opt"
		checkfile="$nostrikes"
		checkinvalidips #Check excludes file for invalid entries
	else
		echo "[?] Enter the excluded IP addresses file -- if none, press <enter>: "
		while true; do
			read -e -p " [>] " nostrikes
			if [[ -z "$nostrikes" ]]; then
				mkdir -p /tmp/zeroe
				touch /tmp/zeroe/nullexcludes.zre
				nostrikes="/tmp/zeroe/nullexcludes.zre"
				break
			elif [[ ! -f "$nostrikes" ]]; then
				echo -e "\e[31m [X] Error: You must pass an existing file containing the list of IP addresses to exclude (e.g. exclude.txt) \e[0m"
			elif [ ! -s "$nostrikes" ]; then #Check if the file is empty
        		echo -e "\\e[31m [X] Error: $nostrikes is empty \\e[0m"
			else
				if [[ "$nostrikes" == "-"* ]]; then
					echo -e "\e[31m [X] Error: File names starting with '-' may cause issues with commands \e[0m"
				elif [[ "$nostrikes" == *" "* ]]; then
					echo -e "\e[31m [X] Error: To proactively avoid errors, whitespace is not allowed in file names \e[0m"
				else
					checkfile="$nostrikes"
					checkinvalidips #Check targets file for invalid entries
					if [[ $allvalid = 1 ]]; then
						x_opt="$nostrikes"
						break
					fi
				fi
			fi
		done
	fi

	if [[ $nostrikes != "/tmp/zeroe/nullexcludes.zre" ]]; then
		x_opt="$(realpath $nostrikes)"
		nostrikes="$(realpath $nostrikes)"
		echo "     Generating temporary list of single IP addresses for excludes..."
		geniplist "$nostrikes" > /tmp/zeroe/excludes-single-ips.zre
		nostrikes="/tmp/zeroe/excludes-single-ips.zre"
		x_opt="/tmp/zeroe/excludes-single-ips.zre"
	fi
}

function enableudp {
	if [[ "$u_opt" = false && "$U_opt" = false && "$defaults" = true ]]; then
		udp="y"
		U_opt=true
	elif [ "$U_opt" = true ]; then
		udp="y"
	elif [ "$u_opt" = true ]; then
		udp="n"
	else
		echo "[?] Enable UDP scans? <y/n>"
		while true; do
			read -e -p " [>] " udp
				if [ "$udp" = "y" ] || [ "$udp" = "yes" ] || [ "$udp" = "n" ] || [ "$udp" = "no" ]; then
					break
				else
					echo -e "\e[31m [X] Error: You must enter 'y', 'yes', 'n', or 'no' \e[0m"
				fi
		done
		if [ "$udp" = "y" ] || [ "$udp" = "yes" ]; then
			U_opt=true
			u_opt=false
		elif [ "$udp" = "n" ] || [ "$udp" = "no" ]; then
			U_opt=false
			u_opt=true
		fi
	fi

	if [[ "$u_opt" = true || "$udp" = "n" ]] && [[ "$S_opt" = *"udp" || "$stage" = *"udp" ]]; then #If UDP scans are disabled, but UDP stage is selected
		echo -e "\e[31m [X] Error: A UDP stage cannot be selected if UDP scans are disabled \e[0m"
		exit 1
	fi

	#if [[ "$only_flag" == true ]] && ([[ "$U_opt" == true ]] || [[ "$udp" == "y" ]]) && [[ "$stage" == "methodology" ]]; then
	#	echo -e "\e[31m [X] Error: UDP scans are not used in report generation \e[0m"
	#	exit 1
	#fi

	if [[ "$only_flag" == true ]] && ([[ "$U_opt" == true ]] || [[ "$udp" == "y" ]]) && [[ "$S_opt" != *"udp"* && "$stage" != *"udp"* ]] && [[ "$stage" != "script-start" && "$stage" != "discovery-lists" ]]; then #If only UDP scans are enabled, but TCP stage is selected
		echo -e "\e[31m [X] Error: A TCP stage cannot be selected if only UDP scans are enabled \e[0m"
		exit 1
	fi
}	

function filtersusips {
    #Use awk to count the occurrences of each IP and print those with <= 100 entries to the output file
    #[ -e "$susips" ] && rm "$susips" #2>>"$filepath/logs/$typevar-errors.log"
    #[ -e "$susoutput" ] && rm "$susoutput" #2>>"$filepath/logs/$typevar-errors.log"
    awk '
    {
        ip[$4]++;
    }
    END {
        for (i in ip) {
            if (ip[i] > 100) {
                print i >> "'"$susips"'";
                sus_ips[i] = 1;
            }
        }
    }' "$susinput" #2>>"$filepath/logs/$typevar-errors.log"
    #Check if sus_ips.txt exists before trying to read it
    if [ -f "$susips" ]; then
        #Then filter out the sus IPs from the input file
        awk 'FNR==NR {sus_ips[$0]=1; next} !($4 in sus_ips)' "$susips" "$susinput" >> "$susoutput" #2>>"$filepath/logs/$typevar-errors.log"
    else
        cat "$susinput" >> "$susoutput" #2>>"$filepath/logs/$typevar-errors.log"
    fi
}

function singleportstorange { #Converts individual sequential port numbers into a range
	awk '
	BEGIN{start=end=""}
	{
	    if(start == ""){
	        start=end=$1;
	    }
	    else if($1 == end+1){
	        end=$1;
	    }
	    else{
	        if(start == end)
	            print start;
	        else
	            print start"-"end;
	        start=end=$1;
	    }
	}
	END{
	    if(start == end)
	        print start;
	    else
	        print start"-"end;
	}' <(sort -n "$filepath/rangetemp.txt") >> $rangeout
	rm "$filepath/rangetemp.txt"
	#sed -i '/^[ \t]*$/d' "$checkfile" #cant remember why i had $checkfiles here. its only ever set to $ips and $nostrikes
	sed -i '/^[ \t]*$/d' "$rangeout" #Removes blank lines and lines that only contain spaces
	sort -u -o "$rangeout" "$rangeout"
}

function checkinvalidips { #Checks targets file for invalid entries
	dos2unix -q "$checkfile" #Converts target files created on Windows to unix format to remove hidden characters
	sed -i '/^[ \t]*$/d' "$checkfile" #Removes blank lines and lines that only contain spaces
	sed -i 's/^[[:space:]]*//; s/[[:space:]]*$//' "$checkfile" #Removes whitespace from the beginning and end of each line

	#Regex pattern to match single IPv4 addresses
	ip_single='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
	#Regex pattern to match full IPv4 address ranges
	ip_range_full='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])-(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
	#Regex pattern to match IPv4 CIDR notations
	ip_cidr='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\/([0-9]|[1-2][0-9]|3[0-2])$'
	#Regex pattern to match IPv4 address ranges that cannot be parsed by masscan
	ip_range_anyoct='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)-(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$|^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)-(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$|^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)-(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$|^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])-(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

	#Read file line by line, checking for invalid entries
	anyinvalid=0
	while IFS= read -r line || [[ -n "$line" ]]; do #Condition after the || ensures last line of file is checked even if it's not a newline
		if [[ $line =~ $ip_single ]]  || [[ $line =~ $ip_cidr ]] || [[ $line =~ $ip_range_full ]]; then
			:
		elif [[ $line =~ $ip_range_anyoct ]]; then
			#echo -e "\e[31m [X] Error: $ips contains an entry that masscan cannot parse -- $line \e[0m"
			echo -e "\e[31m [X] Error: $checkfile contains an entry that masscan cannot parse -- $line \e[0m"
			anyinvalid=1
		else
			echo -e "\e[31m [X] Error: $checkfile contains an invalid entry -- $line \e[0m"
			anyinvalid=1
		fi
	done <"$checkfile"

	if [ $anyinvalid -ne 0 ]; then
		allvalid=0
		if [[ -z "$t_opt" && "$defaults" = true ]] || [ -n "$t_opt" ] || [[ "$countopt" == "y" ]] || [[ "$geniplistopt" == "y" ]]; then
			exit 1
		fi
	else
  		allvalid=1
	fi
}

function stageinit { #The checkpoint system
	mkdir -p /tmp/zeroe

	function checkinvalidstage { #Defines the function to check for invalid stage
		if [[ "$stage" = "script-start" || "$stage" = "discovery-ports" || "$stage" = "discovery-alives" || "$stage" = "discovery-udp" || "$stage" = "discovery-lists" || "$stage" = "services-tcp" || "$stage" = "services-udp" ]]; then # || "$stage" = "methodology"
			return 0
		else	
			echo -e "\e[31m [X] Error: Invalid stage '$stage' -- check help or README for valid stages \e[0m"
			return 1
		fi
	}

	if [[ "$s_opt" = false && "$S_opt" = "disabled" && "$defaults" = true ]]; then #If only using --defaults option
		#echo "script-start" > /tmp/zeroe/stage.zre
		stage="script-start"
		echo "$(pwd)" > /tmp/zeroe/initdir.zre
		stage_cont=true
		only_flag=false
	elif [[ "$s_opt" = true ]]; then #If stage disabled
		#echo "script-start" > /tmp/zeroe/stage.zre
		stage="script-start"
		echo "$(pwd)" > /tmp/zeroe/initdir.zre
		stage_cont=true
		#only_flag=false
	elif [[ ! -f "/tmp/zeroe/stage.zre" && "$S_opt" = "disabled" ]] || [[ -f "/tmp/zeroe/stage.zre" && "$(cat /tmp/zeroe/stage.zre)" = "script-start" ]]; then #If the stage file does not exist and stage option is disabled OR stage file exists and saved stage is script-start
		echo "[?] Start a new scan <y>, or start from a specific stage? -- see README or --help for stage options"
		while true; do
			read -e -p " [>] " stage
			if [[ "$stage" = "y" ]]; then
				#echo "script-start" > /tmp/zeroe/stage.zre
				stage="script-start"
				echo "$(pwd)" > /tmp/zeroe/initdir.zre
				stage_cont=true
				#only_flag=false
				break
			else
				#echo "$stage" > /tmp/zeroe/stage.zre
				echo "$(pwd)" > /tmp/zeroe/initdir.zre
				if checkinvalidstage; then
					if [[ "$only_flag" = false ]]; then
						stage_cont=true
					fi
					break
				fi
			fi
		done
	elif [ -f "/tmp/zeroe/stage.zre" ] && [[ -z "$S_opt" ]]; then #Load stage if it exists and resume stage option is enabled
	  	stage=$(cat /tmp/zeroe/stage.zre)
		resume="y"
	elif [[ ! -f "/tmp/zeroe/stage.zre" ]] && [[ -z "$S_opt" ]]; then #If the stage file does not exist and resume stage option is enabled
		echo -e "\e[31m [X] Error: No saved stage exists \e[0m"
		echo "[?] Start a new scan <y>, or start from a specific stage? -- see README or --help for stage options"
		while true; do
			read -e -p " [>] " stage
				if [[ "$stage" = "y" ]]; then
					#echo "script-start" > /tmp/zeroe/stage.zre
					stage="script-start"
					echo "$(pwd)" > /tmp/zeroe/initdir.zre
					stage_cont=true
					#only_flag=false
					break
				else
					#echo "$stage" > /tmp/zeroe/stage.zre
					echo "$(pwd)" > /tmp/zeroe/initdir.zre
					if checkinvalidstage; then
						if [[ "$only_flag" != true ]]; then
							stage_cont=true
						fi
						break
					fi
				fi
		done
	elif [ -f "/tmp/zeroe/stage.zre" ] && [[ "$S_opt" = "disabled" ]] && [[ "$(cat /tmp/zeroe/stage.zre)" != "script-start" ]] && [[ -f "/tmp/zeroe/stage.zre" ]]; then #If the stage file exists and the stage option is disabled and saved stage is not script-start
		echo "[?] Resume from '$(cat /tmp/zeroe/stage.zre)' <y/n>, or start from a specific stage? -- see README or --help for stage options"
		while true; do
			read -e -p " [>] " stage
			if [[ "$stage" != "script-start" && "$stage" != "discovery-ports" && "$stage" != "discovery-alives" && "$stage" != "discovery-udp" && "$stage" != "discovery-lists" && "$stage" != "services-tcp" && "$stage" != "services-udp" && "$stage" != "y" && "$stage" != "n" ]]; then #  && "$stage" != "methodology"
				echo -e "\e[31m [X] Error: Invalid stage '$stage' -- check help or README for valid stages \e[0m"
			elif [[ "$stage" = "n" ]]; then
				stage="script-start"
				#echo "script-start" > /tmp/zeroe/stage.zre
				echo "$(pwd)" > /tmp/zeroe/initdir.zre
				stage_cont=true
				break
			elif [[ "$stage" = "y" ]]; then
				resume="y"
				stage=$(cat /tmp/zeroe/stage.zre)
				#echo "$stage" > /tmp/zeroe/stage.zre
				break
			else #Specifying a stage
				#echo "$stage" > /tmp/zeroe/stage.zre
				if checkinvalidstage; then
					echo "$(pwd)" > /tmp/zeroe/initdir.zre
					if [[ "$only_flag" == true && "$stage" == "discovery-udp" ]]; then
						stage_cont=false
					elif [[ "$only_flag" != true ]]; then
						stage_cont=true
					fi
					break
				fi
			fi
		done
	elif [ -n "$S_opt" ]; then #Start at the specified stage
		if [[ "$S_opt" = "script-start" || "$S_opt" = "discovery-ports" || "$S_opt" = "discovery-alives" || "$S_opt" = "discovery-udp" || "$S_opt" = "discovery-lists" || "$S_opt" = "services-tcp" || "$S_opt" = "services-udp" ]]; then #  || "$S_opt" = "methodology"
			stage="$S_opt"
			#echo "$stage" > /tmp/zeroe/stage.zre
			echo "$(pwd)" > /tmp/zeroe/initdir.zre
			if [[ "$only_flag" == true && "$S_opt" == "discovery-udp" ]]; then
				stage_cont=false
			elif [[ "$only_flag" != true ]]; then
				stage_cont=true
			fi
		else
			echo -e "\e[31m [X] Error: Invalid stage '$S_opt' -- check help or README for valid stages \e[0m"
			exit 1
		fi
	fi
}

function stagefilescheck { #Checks if required files are present for the specified stage
    local missing_files=()

    function checkstagefiles {
        for file in "$@"; do
            if [ ! -f "$file" ]; then
                missing_files+=("$file")
            fi
        done
    }
	#Defines required files for each stage
	if [[ "$e_opt" = true || "$type" = "E" || "$type" = "e" || "$type" = "external" || "$type" = "External" || "$type" = "Ext" || "$type" = "ext" ]]; then
    	case "$stage" in
    		"discovery-alives")
    			checkstagefiles "$nostrikes" "$ips"
    			;;
    		"discovery-ports")
    			checkstagefiles "$nostrikes" "$ips" "$filepath/logs/misc-files/$typevar-discoscan-masscan-tcp.txt"
    			;;
    		"discovery-udp")
    			checkstagefiles "$nostrikes" "$ips"
    			;;
    		"discovery-lists")
    			# Check for $filepath/$typevar-alives.txt
    			checkstagefiles "$filepath/logs/misc-files/$typevar-discoresults.txt"
    			if ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; }; then
    			    # Check for $filepath/$typevar-openports.txt and $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt
    			    checkstagefiles  "$filepath/logs/misc-files/$typevar-discoscan-masscan-tcp-nosusips.txt"
    			fi
    			if [[ "$udp" = "y" || "$udp" = "yes" || "$U_opt" = true ]]; then
    			    if [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ]; then
    			        # Check for $filepath/logs/misc-files/$typevar-discoscan-nmap-udp-nosusips.txt and $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt
    			        checkstagefiles "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp-nosusips.txt"
    			    else
    			        # Check for $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap and $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt
    			        checkstagefiles "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap"
    			    fi
    			fi
    			;;
    		"services-tcp")
    			checkstagefiles "$nostrikes" "$filepath/$typevar-alives.txt" "$filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt"
    			;;
    		"services-udp")
    			checkstagefiles "$nostrikes" "$filepath/$typevar-alives.txt" "$filepath/logs/misc-files/$typevar-portsfornmap-udp.txt"
    			;;
    		#"methodology")
    		#	checkstagefiles "$ips" "$filepath/logs/misc-files/$typevar-discoscan-masscan-tcp.txt" "$filepath/$typevar-tcp-servicescan-results.nmap" "$filepath/$typevar-alives.txt"
    		#	;;
    	esac
  	elif [[ "$i_opt" = true || "$type" = "I" || "$type" = "i" || "$type" = "internal" || "$type" = "Internal" || "$type" = "Int" || "$type" = "int" ]]; then
    	case "$stage" in
    		"discovery-alives")
    			checkstagefiles "$nostrikes" "$ips"
    			;;
    		"discovery-ports")
    			checkstagefiles "$nostrikes" "$filepath/logs/misc-files/$typevar-discoresults.txt"
    			;;
    		"discovery-udp")
    			if [ -f "$filepath/logs/misc-files/$typevar-discoresults.txt" ]; then
    				checkstagefiles "$nostrikes" "$filepath/logs/misc-files/$typevar-discoresults.txt"
    			else
    				checkstagefiles "$nostrikes" "$ips"
    			fi
    			;;
    		"discovery-lists")
    			# Check for $filepath/$typevar-alives.txt
    			checkstagefiles "$filepath/logs/misc-files/$typevar-discoresults.txt"
    			if ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; }; then
    			    # Check for $filepath/$typevar-openports.txt and $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt
    			    checkstagefiles  "$filepath/logs/misc-files/$typevar-discoscan-masscan-tcp-nosusips.txt"
    			fi
    			if [[ "$udp" = "y" || "$udp" = "yes" || "$U_opt" = true ]]; then
    			    if [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ]; then
    			        # Check for $filepath/logs/misc-files/$typevar-discoscan-nmap-udp-nosusips.txt and $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt
    			        checkstagefiles "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp-nosusips.txt"
    			    else
    			        # Check for $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap and $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt
    			        checkstagefiles "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap"
    			    fi
    			fi
    			;;
    		"services-tcp")
    			checkstagefiles "$nostrikes" "$filepath/$typevar-alives.txt" "$filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt"
    			;;
    		"services-udp")
    			checkstagefiles "$nostrikes" "$filepath/$typevar-alives.txt" "$filepath/logs/misc-files/$typevar-portsfornmap-udp.txt"
    			;;
    		#"methodology")
    		#	checkstagefiles "$ips" "$filepath/logs/misc-files/$typevar-discoresults.txt" "$filepath/logs/misc-files/$typevar-discoscan-masscan-tcp.txt" "$filepath/$typevar-tcp-servicescan-results.nmap" "$filepath/$typevar-alives.txt"
    		#	;;
    	esac
  	fi
	if [ ${#missing_files[@]} -ne 0 ]; then
        #echo -e "\e[31m [X] Error: The following required files are missing for the '$stage' stage:"
        #for file in "${missing_files[@]}"; do
        #    echo -e "  - $file"
        #done
		if [[ -f /tmp/zeroe/stage.zre ]]; then
        	echo -e "\e[31m [X] Error: Required ZrE files for $stage stage do not exist"
			echo -e "            Resume ZrE from the saved $(cat /tmp/zeroe/stage.zre) stage, or restart ZrE \e[0m"
        	exit 1
		else
			echo -e "\e[31m [X] Error: Required ZrE files for $stage stage do not exist"
			echo -e "            Correct output directory if repeating stage, or restart ZrE \e[0m"
        	exit 1
		fi
    fi
}


function nessusports { #Formats open ports as Nessus-compatible for easy copy/pasting
	rm $filepath/$typevar-portsfornessus.txt #Prevents duplicate entries
	#Outputs TCP ports in Nessus-compatible format (T:#,)
	awk '{printf "T:%s,", $0}' $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt | sed 's/,$/\n/' >> $filepath/$typevar-portsfornessus.txt
	if grep -q "\S" "$filepath/logs/misc-files/$typevar-portsfornmap-udp.txt"; then
		#Outputs UDP ports in Nessus-compatible format (U:#,)
		awk '{printf "U:%s,", $0}' $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt | sed 's/,$/\n/' >> $filepath/$typevar-portsfornessus.txt
		#Joins TCP and UDP ports into single line
		sed -i -z 's/\n/,/' $filepath/$typevar-portsfornessus.txt
	fi
}

function totaltargets { #Counts total number of hosts in a targets file

	calculate_cidr_hosts() { #Function to calculate number of hosts in a CIDR
	    local cidr="$1"
	    local mask="${cidr#*/}"
	    local num_hosts=$((2**(32-mask)))
	    echo "$num_hosts"
	}

	
	calculate_ip_range_hosts() { #Function to calculate number of hosts in an IP range
	    local ip_range="$1"
	    local IFS='-'
	    read -r start end <<< "$ip_range"

	    # Convert IPs to 32-bit numbers
	    local start_long=$(echo $start | awk -F'.' '{print ($1*(2^24))+($2*(2^16))+($3*(2^8))+$4}')
	    local end_long=$(echo $end | awk -F'.' '{print ($1*(2^24))+($2*(2^16))+($3*(2^8))+$4}')
	
	    local num_hosts=$(($end_long - $start_long + 1))
	    echo "$num_hosts"
	}

	total_hosts=0

	while read line || [[ -n "$line" ]]; do
	    if [[ $line == *"/"* ]]; then
	        # CIDR notation
	        hosts=$(calculate_cidr_hosts "$line")
	    elif [[ $line == *"-"* ]]; then
	        # IP range
	        hosts=$(calculate_ip_range_hosts "$line")
	    else
	        # Single IP
	        hosts=1
	    fi
	    total_hosts=$((total_hosts + hosts))
	done < "$checkfile"
}

function geniplist { #generates a list of single IP addresses from targets file

	# Function to convert CIDR to IP range
	cidr_to_ip_range() {
    	local ip cidr netmask
    	IFS=/ read -r ip cidr <<< "$1"
    	netmask=$(( 0xffffffff ^ ((1 << (32 - cidr)) - 1) ))
	
    	local start_ip end_ip
    	IFS=. read -r i1 i2 i3 i4 <<< "$ip"
    	start_ip=$(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 & netmask ))
    	end_ip=$(( start_ip | ((1 << (32 - cidr)) - 1) ))
	
    	echo "$(int_to_ip $start_ip)-$(int_to_ip $end_ip)"
	}

	# Function to convert integer IP to dotted-decimal format
	int_to_ip() {
	    local ip=$1
    	local octet1=$(( ip >> 24 & 255 ))
    	local octet2=$(( ip >> 16 & 255 ))
    	local octet3=$(( ip >> 8 & 255 ))
    	local octet4=$(( ip & 255 ))
    	echo "$octet1.$octet2.$octet3.$octet4"
	}

	# Function to expand IPs
	expand_ips() {
	    while IFS= read -r ip || [[ -n "$ip" ]]; do
        	if [[ $ip == *"/"* ]]; then
        	    # Handle CIDR notation
        	    range=$(cidr_to_ip_range "$ip")
        	    IFS=- read start end <<< "$range"
        	    start=$(printf '%d\n' $(echo "$start" | awk -F. '{print ($1*256^3) + ($2*256^2) + ($3*256) + $4}'))
        	    end=$(printf '%d\n' $(echo "$end" | awk -F. '{print ($1*256^3) + ($2*256^2) + ($3*256) + $4}'))
        	    for ((i=start; i<=end; i++)); do
        	        int_to_ip "$i"
        		done
	        elif [[ $ip == *"-"* ]]; then
	            # Handle IP range
	            IFS=- read start end <<< "$ip"
	            start=$(printf '%d\n' $(echo "$start" | awk -F. '{print ($1*256^3) + ($2*256^2) + ($3*256) + $4}'))
	            end=$(printf '%d\n' $(echo "$end" | awk -F. '{print ($1*256^3) + ($2*256^2) + ($3*256) + $4}'))
	            for ((i=start; i<=end; i++)); do
	                int_to_ip "$i"
	            done
	        else
	            # Handle single IP address
	            echo "$ip"
	        fi
	    done < "$1"
	}
	expand_ips "$checkfile" | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | uniq
}

function statusnmap {
	indicator="^-_-^"
		# Start a background process to cat the last line of the file every 15 minutes
		(
		    while kill -0 $pid >/dev/null 2>&1; do
		        sleep 900  # 15 minutes
		        printf "\r%-${#indicator}s\r" "" # Clear continuous status line
		        echo ""
				echo ""
				tail -n 5 "$periodicfile"
				echo ""
		    done
		) &
		status_pid=$! #Capture the PID of the status process

		while kill -0 $pid >/dev/null 2>&1; do
			i=$(( (i+1) % 4 ))
			printf "\r${indicator:$i:1} $contstatus"
			sleep 0.2
		done
		printf "\r%-${#indicator}s\r" "" #Clears status indicator line

		kill $status_pid #Kill the status process when done
}

function statusmasscan {
	indicator="^-_-^"
		# Start a background process to cat the last line of the file every 15 minutes
		(
		    while kill -0 $pid >/dev/null 2>&1; do
		        sleep 900  # 15 minutes
		        echo ""
				echo ""
				tail -n 5 "$periodicfile"
		        echo ""
				echo ""
		    done
		) &
		status_pid=$! #Capture the PID of the status process

		while kill -0 $pid >/dev/null 2>&1; do
			i=$(( (i+1) % 4 ))
			printf "\r${indicator:$i:1} $contstatus"
			sleep 0.2
		done
		printf "\r%-${#indicator}s\r" "" #Clears status indicator line

		kill $status_pid #Kill the status process when done
}

function errorcheck {
	errorlog="/logs/$typevar-errors.log"

	if [ $exitstatus -ne 0 ]; then
		echo "--------" >> "$errorlog"
		echo "COMMAND: $checked_cmd" >> "$errorlog"
		echo "===================================" >> "$errorlog"
		echo '' >> "$errorlog"
		echo -e "\e[31m [X] Error occured -- check logs in $errorlog \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
	fi
}

function sedescape { #prevents special characters from being interpreted as sed metacharacters - used in methodology
    			echo "$1" | sed -e 's/[]\/$*.^[]/\\&/g'
}

function whenstopped {
	#Kill the periodic status process if it's running
    if [[ -n $status_pid ]] && kill -0 $status_pid >/dev/null 2>&1; then       
		kill $status_pid
    fi
	#Display exiting status
	echo ""
	echo -e "\e[33m [!] Zero-E stopped -- saving progress... \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
	sleep 3
	sed -i '/nocapture = servername/d' paused.conf 2>/dev/null #Removes line that breaks masscan --resume function
	sed -i 's/adapter-port = [0-9]*-[0-9]*/adapter-port = 40000-41023/' paused.conf 2>/dev/null #Fixes another line that breaks masscan --resume function... cmon masscan, do better
	#Remove the trap to prevent it from repeating
	trap - INT TERM  
	exit 1
}

function zrecleanup {
	rm -rd /tmp/zeroe 2>/dev/null
	rm paused.conf 2>/dev/null
}

function checktools {
	oscheck=$(uname)
	if [ $oscheck = "Darwin" ]; then #For st00pid Macs
		missing=()
		for tool in "${mactools[@]}"; do
			if ! command -v "$tool" >/dev/null 2>&1; then
				missing+=("$tool --")
			fi
		done
		if [ ${#missing[@]} -gt 0 ]; then
		  echo -e "\e[31m [X] Error: the following required tools are not installed: ${missing[*]}. Install them with 'sudo apt install <tool name>' \e[0m"
		  exit 1
		fi
	else #For Linux
		missing=()
		for tool in "${linuxtools[@]}"; do
			if ! command -v "$tool" >/dev/null 2>&1; then
				missing+=("<$tool> ")
			fi
		done
		if [ ${#missing[@]} -gt 0 ]; then
		  echo -e "\e[31m [X] Error: the following required tools are not installed: ${missing[*]}. Install them with 'sudo apt install <tool name>' \e[0m"
		  exit 1
		fi
	fi
}

function zrengineer { #Enables users to customize commands
	echo -e "\e[33m [!] ZrE ngineer mode is experimental [!]"
	echo -e " [!] It tries to prevent command options that may cause errors"
	echo -e " [!] But given the large number of possible options, it does not catch everything"
	echo -e " [!] If ZrE errors, it is likely due to input passed in these commands \e[0m"
	#create prompts for all necessary commands depending on if internal or external, saying not to include targets, excludes, output, etc
	if [[ "$e_opt" = true || "$type" = "E" || "$type" = "e" || "$type" = "external" || "$type" = "External" || "$type" = "Ext" || "$type" = "ext" ]]; then
		#while true; do
		#	echo "[?] Provide nmap alives discovery command:"
		#	read -e -p " [>] " zreng_ext_alives
		#	if [[ "$zreng_ext_alives" =~ (-|--excludefile|-iL|>>|>|&|-o\*) ]] || [[ "$zreng_ports_opts" == *"- "* ]] || { [[ "$zreng_ports_opts" =~ (-)$ ]] && [[ ! "$zreng_ports_opts" =~ "-p-" ]]; }; then
		#		echo -e "\e[31m [X] Error: The command cannot contain [-|--excludefile|-iL|>>|>|&] -- this will likely cause errors \e[0m"
		#	elif [[ "$zreng_ext_alives" != *"nmap"* ]]; then
		#		echo -e "\e[31m [X] Error: Nmap must be used for alives discovery or errors will occur \e[0m"
		#	elif [[ -z "$zreng_ext_alives" ]]; then #leave blank to use default
		#		ngineer_default=true
		#		break
		#	else
		#		echo "$zreng_ext_alives"
		#		break
		#	fi
		#done
		echo "[?] Provide custom options for the masscan open port discovery scan command:"
		echo "    Leave blank to use the ZrE default"
		echo "    Hardcoded: <--open-only> <--excludefile (null if not specified)> <--include-file> <-oG>"
		while true; do
			read -e -p " [>] " zreng_ports_opts
			if [[ -z "$zreng_ports_opts" ]]; then #leave blank to use default
				ngineer_ports_default=true
				break
			elif [[ "$zreng_ports_opts" =~ (-sV|--excludefile|--include-file|>>|>|&|-o\*) ]] || [[ "$zreng_ports_opts" == "- " ]] || { [[ "$zreng_ports_opts" =~ (-)$ ]] && [[ ! "$zreng_ports_opts" =~ "-p-" ]]; }; then
				echo -e "\e[31m [X] Error: The command cannot contain [ --excludefile | --include-file | >> | > | & | - | -o* ] -- this will likely cause errors\e[0m"
			elif [[ "$zreng_ports_opts" == *"masscan"* ]]; then
				echo -e "\e[31m [X] Error: Only provide the desired options \e[0m"
			elif [[ "$zreng_ports_opts" == *"nmap"* ]]; then
				echo -e "\e[31m [X] Error: Currently, Nmap cannot be used here \e[0m"
			elif ! [[ "$zreng_ports_opts" =~ (-p[[:space:]]*([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])(-([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5]))?|--top-ports[[:space:]]+([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5]))|-p- ]]; then
				echo -e "\e[31m [X] Error: At minimum, you must specify ports with -p or --top-ports with proper syntax \e[0m"
			else
				break
			fi
		done

		echo "[?] Provide custom options for the Nmap UDP discovery scan command:"
		echo "    Leave blank to use the ZrE default"
		echo "    Hardcoded: <-sU> <--open> <--excludefile (null if not specified)> <-iL> <-oG>"
		while true; do
			read -e -p " [>] " zreng_udpa_opts
			if [[ -z "$zreng_udpa_opts" ]]; then #leave blank to use default
				ngineer_udpa_default=true
				break
			elif [[ "$zreng_udpa_opts" =~ (-sV|--excludefile|-iL|>>|>|&|-o\*) ]] || [[ "$zreng_udpa_opts" == *"- "* ]] || { [[ "$zreng_udpa_opts" =~ (-)$ ]] && [[ ! "$zreng_udpa_opts" =~ "-p-" ]]; }; then
				echo -e "\e[31m [X] Error: The command cannot contain [ -sV | --excludefile | -iL | >> | > | & | - | -o* ] -- this will likely cause errors \e[0m"
			elif [[ "$zreng_udpa_opts" == *"nmap"* ]]; then
				echo -e "\e[31m [X] Error: Only provide the desired options \e[0m"
			elif [[ "$zreng_ports_opts" == *"masscan"* ]]; then
				echo -e "\e[31m [X] Error: Currently, masscan cannot be used here \e[0m"
			elif ! [[ "$zreng_udpa_opts" =~ (-p[[:space:]]*([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])(-([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5]))?|--top-ports[[:space:]]+([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5]))|-p- ]]; then
				echo -e "\e[31m [X] Error: At minimum, you must specify ports with -p or --top-ports with proper syntax \e[0m"
			else
				break
			fi
		done

		echo "[?] Provide custom options for the Nmap TCP service scan command:"
		echo "    Leave blank to use the ZrE default"
		echo "    Hardcoded: <-sV> <-Pn> <-p> <--excludefile (null if not specified)> <-iL> <-oA>"
		while true; do
			read -e -p " [>] " zreng_tcps_opts
			if [[ -z "$zreng_tcps_opts" ]]; then #leave blank to use default
				ngineer_tcps_default=true
				break
			elif [[ "$zreng_tcps_opts" =~ (--excludefile|-iL|>>|>|&|-o\*) ]] || [[ "$zreng_tcps_opts" == *"- "* ]] || { [[ "$zreng_tcps_opts" =~ (-)$ ]] && [[ ! "$zreng_tcps_opts" =~ "-p-" ]]; }; then
				echo -e "\e[31m [X] Error: The command cannot contain [ --excludefile | -iL | >> | > | & | - | -o* ] -- this will likely cause errors \e[0m"
			elif [[ "$zreng_tcps_opts" == *"nmap"* ]]; then
				echo -e "\e[31m [X] Error: Only provide the desired options \e[0m"
			elif [[ "$zreng_ports_opts" == *"masscan"* ]]; then
				echo -e "\e[31m [X] Error: Currently, masscan cannot be used here \e[0m"
			elif [[ "$zreng_tcps_opts" == *"-p"* ]] || [[ "$zreng_tcps_opts" == *"--top-ports"* ]]; then
				echo -e "\e[31m [X] Error: ZrE will provide only open ports to this scan \e[0m"
			else
				break
			fi
		done

		echo "[?] Provide custom options for the Nmap UDP service scan command:"
		echo "    Leave blank to use the ZrE default"
		echo "    Hardcoded: <-sU> <-sV> <-Pn> <-p> <--excludefile (null if not specified)> <-iL> <-oA>"
		while true; do
			read -e -p " [>] " zreng_udps_opts
			if [[ -z "$zreng_udps_opts" ]]; then #leave blank to use default
				ngineer_udps_default=true
				break
			elif [[ "$zreng_udps_opts" =~ (--excludefile|-iL|>>|>|&|-o\*) ]] || [[ "$zreng_udps_opts" == *"- "* ]] || { [[ "$zreng_udps_opts" =~ (-)$ ]] && [[ ! "$zreng_udps_opts" =~ "-p-" ]]; }; then
				echo -e "\e[31m [X] Error: The command cannot contain [ --excludefile | -iL | >> | > | & | - | -o* ] -- this will likely cause errors \e[0m"
			elif [[ "$zreng_udps_opts" == *"nmap"* ]]; then
				echo -e "\e[31m [X] Error: Only provide the desired options \e[0m"
			elif [[ "$zreng_ports_opts" == *"masscan"* ]]; then
				echo -e "\e[31m [X] Error: Currently, masscan cannot be used here \e[0m"
			elif [[ "$zreng_udps_opts" == *"-p"* ]] || [[ "$zreng_udps_opts" == *"--top-ports"* ]]; then
				echo -e "\e[31m [X] Error: ZrE will provide only open ports to this scan \e[0m"
			else
				break
			fi
		done
	elif [[ "$i_opt" = true || "$type" = "I" || "$type" = "i" || "$type" = "internal" || "$type" = "Internal" || "$type" = "Int" || "$type" = "int" ]]; then
		###Internal###
		echo "[?] Provide custom options for the masscan open port discovery scan command:"
		echo "    Leave blank to use the ZrE default"
		echo "    Hardcoded: <--open-only> <--excludefile (null if not specified)> <--include-file> <-oG>"
		while true; do
			read -e -p " [>] " zreng_ports_opts
			if [[ -z "$zreng_ports_opts" ]]; then #leave blank to use default
				ngineer_ports_default=true
				break
			elif [[ "$zreng_ports_opts" =~ (--src-port|--excludefile|--include-file|>>|>|&|-o\*) ]] || [[ "$zreng_ports_opts" == *"- "* ]] || { [[ "$zreng_ports_opts" =~ (-)$ ]] && [[ ! "$zreng_ports_opts" =~ "-p-" ]]; }; then
				echo -e "\e[31m [X] Error: The command cannot contain [ --src-port | --excludefile | --include-file | >> | > | & | - | -o* ] -- this will likely cause errors \e[0m"
			elif [[ "$zreng_ports_opts" == *"masscan"* ]]; then
				echo -e "\e[31m [X] Error: Only provide the desired options \e[0m"
			elif [[ "$zreng_ports_opts" == *"nmap"* ]]; then
				echo -e "\e[31m [X] Error: Currently, Nmap cannot be used here \e[0m"
			elif ! [[ "$zreng_ports_opts" =~ (-p[[:space:]]*([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])(-([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5]))?|--top-ports[[:space:]]+([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5]))|-p- ]]; then
				echo -e "\e[31m [X] Error: At minimum, you must specify ports with -p or --top-ports with proper syntax \e[0m"
			else
				break
			fi
		done

		echo "[?] Provide custom options for the Nmap UDP discovery scan command:"
		echo "    Leave blank to use the ZrE default"
		echo "    Hardcoded: <-sU> <--open> <--excludefile (null if not specified)> <-iL> <-oG>"
		while true; do
			read -e -p " [>] " zreng_udpa_opts
			if [[ -z "$zreng_udpa_opts" ]]; then #leave blank to use default
				ngineer_udpa_default=true
				break
			elif [[ "$zreng_udpa_opts" =~ (--excludefile|-iL|-sV|>>|>|&|-o\*) ]] || [[ "$zreng_udpa_opts" == *"- "* ]] || { [[ "$zreng_udpa_opts" =~ (-)$ ]] && [[ ! "$zreng_udpa_opts" =~ "-p-" ]]; }; then
				echo -e "\e[31m [X] Error: The command cannot contain [ --excludefile | -iL | -sV | >> | > | & | - | -o* ] -- this will likely cause errors \e[0m"
			elif [[ "$zreng_udpa_opts" == *"nmap"* ]]; then
				echo -e "\e[31m [X] Error: Only provide the desired options \e[0m"
			elif [[ "$zreng_ports_opts" == *"masscan"* ]]; then
				echo -e "\e[31m [X] Error: Currently, masscan cannot be used here \e[0m"
			elif ! [[ "$zreng_udpa_opts" =~ (-p[[:space:]]*([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])(-([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5]))?|--top-ports[[:space:]]+([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5]))|-p- ]]; then
				echo -e "\e[31m [X] Error: At minimum, you must specify ports with -p or --top-ports with proper syntax \e[0m"
			else
				break
			fi
		done

		echo "[?] Provide custom options for the Nmap TCP service scan command:"
		echo "    Leave blank to use the ZrE default"
		echo "    Hardcoded: <-sV> <-Pn> <-p> <--excludefile (null if not specified)> <-iL> <-oA>"
		while true; do
			read -e -p " [>] " zreng_tcps_opts
			if [[ -z "$zreng_tcps_opts" ]]; then #leave blank to use default
				ngineer_tcps_default=true
				break
			elif [[ "$zreng_tcps_opts" =~ (--excludefile|-iL|>>|>|&|-o\*) ]] || [[ "$zreng_tcps_opts" == *"- "* ]] || { [[ "$zreng_tcps_opts" =~ (-)$ ]] && [[ ! "$zreng_tcps_opts" =~ "-p-" ]]; }; then
				echo -e "\e[31m [X] Error: The command cannot contain [ --excludefile | -iL | >> | > | & | - | -o* ] -- this will likely cause errors \e[0m"
			elif [[ "$zreng_tcps_opts" == *"nmap"* ]]; then
				echo -e "\e[31m [X] Error: Only provide the desired options \e[0m"
			elif [[ "$zreng_ports_opts" == *"masscan"* ]]; then
				echo -e "\e[31m [X] Error: Currently, masscan cannot be used here \e[0m"
			elif [[ "$zreng_tcps_opts" == *"-p"* ]] || [[ "$zreng_tcps_opts" == *"--top-ports"* ]]; then
				echo -e "\e[31m [X] Error: ZrE will provide only open ports to this scan \e[0m"
			else
				break
			fi
		done

		echo "[?] Provide custom options for the Nmap UDP service scan command:"
		echo "    Leave blank to use the ZrE default"
		echo "    Hardcoded: <-sU> <-sV> <-Pn> <-p> <--excludefile (null if not specified)> <-iL> <-oA>"
		while true; do
			read -e -p " [>] " zreng_udps_opts
			if [[ -z "$zreng_udps_opts" ]]; then #leave blank to use default
				ngineer_udps_default=true
				break
			elif [[ "$zreng_udps_opts" =~ (--excludefile|-iL|>>|>|&|-o\*) ]] || [[ "$zreng_udps_opts" == *"- "* ]] || { [[ "$zreng_udps_opts" =~ (-)$ ]] && [[ ! "$zreng_udps_opts" =~ "-p-" ]]; }; then
				echo -e "\e[31m [X] Error: The command cannot contain [ --excludefile | -iL | >> | > | & | - | -o* ] -- this will likely cause errors \e[0m"
			elif [[ "$zreng_udps_opts" == *"nmap"* ]]; then
				echo -e "\e[31m [X] Error: Only provide the desired options \e[0m"
			elif [[ "$zreng_ports_opts" == *"masscan"* ]]; then
				echo -e "\e[31m [X] Error: Currently, masscan cannot be used here \e[0m"
			elif [[ "$zreng_udps_opts" == *"-p"* ]] || [[ "$zreng_udps_opts" == *"--top-ports"* ]]; then
				echo -e "\e[31m [X] Error: ZrE will provide only open ports to this scan \e[0m"
			else
				break
			fi
		done
	
	fi
}

updatecheck

#--Switches
#pre-sudo options
help_flag=false
version_flag=false
geniplist_file=""
checkfile=""
defaults=false
only_flag=false
ngineer_mode=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		--help)
            help_flag=true
            shift # Remove --help from processing
            ;;
		--version)
            version_flag=true
            shift # Remove --version from processing
            ;;
        --geniplist)
            shift # Remove --geniplist from processing
            if [[ $# -gt 0 && ! $1 =~ ^- && -f $1 ]]; then #If there is at least one more argument, the next arg doesnt start with a -, and the arg refers to an existing file
                geniplistopt="y"
				geniplist_file="$1"
                shift # Remove file argument from processing
            else
                echo -e "\e[31m [X] Error: --geniplist requires an existing file containing a list of IP addresses (e.g. targets.txt) \e[0m"
                exit 1
            fi
            ;;
        --count)
            shift # Remove --count from processing
            if [[ $# -gt 0 && ! $1 =~ ^- && -f $1 ]]; then
                countopt="y"
				checkfile="$1"
                shift # Remove file argument from processing
            else
                echo -e "\e[31m [X] Error: --count requires an existing file containing a list of a IP addresses (e.g. targets.txt) \e[0m"
                exit 1
            fi
            ;;
		--defaults)
			defaults=true
			shift #Removes --defaults from processing
			;;
		--only)
			only_flag=true
			shift
			;;
		--ngineer)
			ngineer_mode=true
			shift
			;;
        *)
			remaining_args+=("$1") #Stores other opts/args for processing in post-sudo functions
			shift
            ;;
	esac
done
if [ "$help_flag" = true ]; then
	echo "$version -- https://github.com/Inscyght/Zero-E"
    echo ''
	echo "While there are options, providing them is not necessary with Zero-E"
	echo "ZrE will prompt you for required configuration settings"
	echo "For advanced usage:"
	echo -e "\nsudo $(basename $0) [-e || -i] [-o output_directory] [-t targets_file] [-x [excludes_file]] [-U || -u] [-S [stage] || -s] [--defaults] [--ngineer] [--only] [--count filename] [--geniplist filename]"
	echo "  -e: Run external assessment scans -- cannot be used with -i"
    echo "  -i: Run internal assessment scans -- cannot be used with -e"
    echo "  -o: Sets the output directory where generated files will save to"
    echo "  -t: Sets the file containing the target IP addressses -- each single IP, range, or CIDR must be on a new line"
	echo "  -x: Sets the file containing the IP addressses to exclude -- provide no argument to disable and not be prompted"
    echo "  -U: Enables UDP scans -- cannot be used with -u"
	echo "  -u: Disables UDP scans -- cannot be used with -U"
	echo "  -S: With no arguments, resumes from saved stage -- cannot be used with -s"
	echo "      Will skip to the specified stage, if provided -- valid stages are:"
	echo "      	discovery-alives"
	echo "      	discovery-ports"
	echo "      	discovery-udp"
	echo "      	discovery-lists"
	echo "      	services-tcp"
	echo "      	services-udp"
	#echo "      	methodology"
	echo "  -s: Disables stage resuming and selection and starts at beginning of script -- cannot be used with -S"
	echo "      Stages are still saved for resuming later as script runs"
	echo "  --defaults: Runs ZrE using default settings -- using options with this will overwrite the default for that option"
	echo "      Default settings are:"
	echo "        Stage (-S/-s) -- starts at initial alives scan"
	echo "        Targets file (-t) -- ./targets.txt"
	echo "        Output directory (-o) -- ./zre-output"
	echo "        Excluded targets (-x) -- none"
	echo "        UDP scans (-U/-u) -- enabled"
	echo "  --ngineer: Enables entry of custom command options"
	echo "  --only: Only run UDP scans if enabled, and/or specified stage if provided -- does not apply to other options"
	echo "  --count: Calculates and displays the total number of target IP addresses -- does not require sudo"
	echo "  --geniplist: Generates a list of unique, single IP addresses from the IP addresses, ranges, and CIDRs in the passed file  -- does not require sudo"
    exit 0
#Check for --version option (for troubleshooting purposes)
elif [ "$version_flag" = true ]; then
	echo $version
	exit 0
#Check for --count option
elif [ -n "$checkfile" ]; then
	mactools=("dos2unix")
	linuxtools=("dos2unix")
	checktools #Check if required tools are installed
	checkfile="$checkfile"
	checkinvalidips
	echo "Counting total number of target hosts..."
	totaltargets
	echo "$total_hosts -- total number of IP addresses in $checkfile"
	exit 0
#Check for --geniplist option
elif [ -n "$geniplist_file" ]; then
	mactools=("dos2unix")
	linuxtools=("dos2unix")
	checktools #Check if required tools are installed
	checkfile="$geniplist_file"
	checkinvalidips
	echo "Generating list of single IP addresses..."
	geniplist
	exit 0
fi


#Check sudo
if [[ $EUID -ne 0 ]]; then # && [[ "$arg" != "--help" || "$arg" != "--version" || "$arg" != "--count" || "$arg" != "--geniplist" ]]; then
   	echo -e "\e[31m [X] Error: $(basename $0) requires sudo \e[0m" 
   	exit 1
fi

#Check if post-sudo required tools are installed
mactools=("nmap" "masscan" "pfctl" "dos2unix" "realpath")
linuxtools=("nmap" "masscan" "iptables" "dos2unix" "realpath")
checktools

#post-sudo options
e_opt=false
i_opt=false
o_opt=""
t_opt=""
x_opt=""
U_opt=false
u_opt=false
s_opt=false
S_opt="disabled"
#Loop to parse options using getopts
while getopts ':eio:t:x:UusS:' opt "${remaining_args[@]}" 2>/dev/null; do
	case "${opt}" in
    	e) 
    		e_opt=true 
    		;;
    	i) 
    		i_opt=true 
    		;;
    	o) 
			if [[ "$OPTARG" == -* ]]; then
                echo -e "\e[31m [X] Error: -o requires a directory name or path \e[0m" >&2
                exit 1
			elif [ -f "$OPTARG" ]; then
				echo -e "\e[31m [X] Error: File exists with the same name \e[0m"
				exit 1
			elif [[ "$OPTARG" == *" "* ]]; then
				echo -e "\e[31m [X] Error: To proactively avoid errors, whitespace is not allowed in directory names \e[0m"
				exit 1
            else
				o_opt="$OPTARG"
			fi
			;;
    	t) 
			if [[ "$OPTARG" == -* ]] || [[ -z "$OPTARG" ]] || [[ ! -f "$OPTARG" ]]; then
                echo -e "\e[31m [X] Error: -t requires an existing file containing the list of target IP addresses (e.g. targets.txt) \e[0m" >&2
                exit 1
			elif [[ "$OPTARG" == *" "* ]]; then
				echo -e "\e[31m [X] Error: To proactively avoid errors, whitespace is not allowed in file names \e[0m"
				exit 1
			elif [ ! -s "$OPTARG" ]; then #Check if the file is empty
        		echo -e "\\e[31m [X] Error: $OPTARG is empty \\e[0m"
				exit 1
            else
				t_opt="$OPTARG"
				checkfile="$t_opt"
				checkinvalidips
			fi
    		;;
		x)
			if [[ "${OPTARG:0:1}" == '-' ]]; then #Enables -x to be run with or without an argument
                OPTIND=$((OPTIND - 1))
				mkdir -p /tmp/zeroe
				touch /tmp/zeroe/nullexcludes.zre
				x_opt="/tmp/zeroe/nullexcludes.zre"
			elif [[ "$OPTARG" == -* ]] || [[ ! -f "$OPTARG" ]]; then
				echo -e "\e[31m [X] Error: -x requires an existing file containing the list of IP addresses to exclude (e.g. exclude.txt) \e[0m" >&2
                exit 1
			elif [[ "$OPTARG" == *" "* ]]; then
				echo -e "\e[31m [X] Error: To proactively avoid errors, whitespace is not allowed in file names \e[0m"
				exit 1
			elif [ ! -s "$OPTARG" ]; then #Check if the file is empty
        		echo -e "\\e[31m [X] Error: $OPTARG is empty \\e[0m"
				exit 1
			else
				x_opt="$OPTARG"
				checkfile="$x_opt"
				checkinvalidips
			fi
			;;
		U) 
    		U_opt=true 
    		;;
		u) 
    		u_opt=true 
    		;;
		s)
			s_opt=true
			;;
		S) 
			if [[ "${OPTARG:0:1}" == '-' ]]; then #Enables -S to be run with or without an argument
                OPTIND=$((OPTIND - 1))
				S_opt=""
			else
				S_opt="$OPTARG"
			fi
			;;
		:) #For when -S or -x is passed without an argument
            if [[ ${OPTARG} == "S" ]]; then
                S_opt=""
			elif [[ ${OPTARG} == "x" ]]; then
				mkdir -p /tmp/zeroe
				touch /tmp/zeroe/nullexcludes.zre
				x_opt="/tmp/zeroe/nullexcludes.zre"
			fi
			;;
    	\?)
    		echo -e "\e[31m [X] Error: invalid option "\`-$OPTARG\`" -- valid options are [-e || -i] [-o] [-t] [-U || -u] [-S || -s] [-x] [--help] [--defaults] [--ngineer] [--only] [--count] [--geniplist] \e[0m" >&2
    		exit 1
    		;;
	esac
done
#Check if the last option was -o or -t and if the arg is missing.
last_arg=${@: -1}
if [[ $last_arg == "-o" ]] && [[ -z "$o_opt" ]]; then
	echo -e "\e[31m [X] Error: -o requires a directory name or path \e[0m" >&2
	exit 1
elif [[ $last_arg == "-t" ]] && [[ -z "$t_opt" ]]; then
	echo -e "\e[31m [X] Error: -t requires an existing file containing the list of target IP addresses (e.g. targets.txt) \e[0m" >&2
	exit 1
fi
#Check if both -e and -i options are used
if [ "$e_opt" = true ] && [ "$i_opt" = true ]; then
    echo -e "\e[31m [X] Error: You seem confused, script kiddie... -e and -i options cannot be used together \e[0m" >&2
    exit 1
fi
#Check if both -U and -u options are used
if [ "$U_opt" = true ] && [ "$u_opt" = true ]; then
    echo -e "\e[31m [X] Error: You seem confused, script kiddie... -U and -u options used together makes no sense \e[0m" >&2
    exit 1
fi
#Check if both -s and -S options are used
if [ "$s_opt" = true ] && [ "$S_opt" != "disabled" ]; then
    echo -e "\e[31m [X] Error: You seem confused, script kiddie... -s disables stage resuming and selection \e[0m" >&2
    exit 1
fi
#Check if both -t and -x are the same file
if [ "$t_opt" = "$x_opt" ] && [ -n "$t_opt" ] && [ -n "$x_opt" ]; then
    echo -e "\e[31m [X] Error: You seem confused, script kiddie... targets and excludes cannot be the same file \e[0m" >&2
    exit 1
fi

#Banner
echo "$version -- https://github.com/Inscyght/Zero-E"
echo ''

#Set the stage to start at
stageinit
if [ -f "/tmp/zeroe/stage.zre" ] && [ -f "/tmp/zeroe/vars.zre" ] && [[ "$resume" = "y" ]]; then #If successfully resuming saved stage...
	if [[ "$(cat /tmp/zeroe/initdir.zre)" = "$(pwd)" ]]; then #check if the current and previous working dir are equal, then...
		: #silently continue to...
	else
		cd $(cat /tmp/zeroe/initdir.zre) #change dirs to the previous working dir and...
	fi
	#parse options to resume scans
	while IFS='=' read -r key rest; do # The value is everything after the first '=', preserving internal quotes and spaces
    	value="${rest#\"}"      # Remove leading quote
    	value="${value%\"}"     # Remove trailing quote
    	eval "$key=\"$value\""  # Use eval to correctly handle complex values, ensuring to escape as needed
	done < /tmp/zeroe/vars.zre
else #Starting new scan or from specific stage
	if [ ! -f "/tmp/zeroe/vars.zre" ] && [[ "$resume" = "y" ]]; then #If choosing resuming without saved options
		echo -e "\e[31m [X] Error: No saved options exist -- configure new scan \e[0m" >&2
		S_opt='disabled'
		resume=''
		while true; do
			stageinit
			if [[ "$resume" = "y" ]]; then
				echo -e "\e[31m [X] Error: New scan configuration required -- resuming without saved options will cause errors \e[0m" >&2
				S_opt='disabled'
				resume=''
			else
				break
			fi
		done
	fi
	#Set external or internal
	settype
	#Enable or disable UDP scans
	enableudp
	#Set the generated file output directory
	output
	#Set the target IPs file
	targets
	#Calculate total number of target hosts
	echo "     Counting total number of target hosts..."
	totaltargets
	#Set the excluded IPs file
	excludes
	#Check if targets and excludes are the same and repeat loop while they are
	if cmp -s "$ips" "$nostrikes"; then
		echo -e "\e[31m [X] Error: You seem confused, script kiddie... all of the targets are excluded -- try again \e[0m" >&2
		ips=""
		t_opt=""
		nostrikes=""
		x_opt=""
		while true; do
			targets
			echo "     Counting total number of target hosts..."
			totaltargets
			excludes
			if cmp -s "$ips" "$nostrikes"; then
				echo -e "\e[31m [X] Error: You seem very confused, script kiddie... all of the targets are still excluded \e[0m" >&2
				ips=""
				t_opt=""
				nostrikes=""
				x_opt=""
			else
				break
			fi
		done
	fi
fi
stagefilescheck
#if --only is not applicable
if [[ "$only_flag" == true ]] && [[ "$u_opt" == true ]] && [[ "$U_opt" == false ]] && [[ "$S_opt" == "disabled" ]]; then
  only_flag=false
fi
#If ngineer mode
if [[ "$ngineer_mode" == true && "$resume" != "y" ]]; then
	zrengineer
fi
#Save options to file for resuming stage
if [[ "$resume" != "y" ]]; then
	echo "e_opt=\"$e_opt\" i_opt=\"$i_opt\" filepath=\"$filepath\" ips=\"$ips\" nostrikes=\"$nostrikes\" U_opt=\"$U_opt\" u_opt=\"$u_opt\" total_hosts=\"$total_hosts\" typevar=\"$typevar\" only_flag=\"$only_flag\" stage_cont=\"$stage_cont\"" > /tmp/zeroe/vars.zre
	echo "$stage" > /tmp/zeroe/stage.zre
	if [[ "$ngineer_mode" == true ]]; then
		echo "ngineer_mode=\"$ngineer_mode\" ngineer_ports_default=\"$ngineer_ports_default\" ngineer_udpa_default=\"$ngineer_udpa_default\" ngineer_tcps_default=\"$ngineer_tcps_default\" ngineer_udps_default=\"$ngineer_udps_default\" zreng_ports_opts=\"$zreng_ports_opts\" zreng_udpa_opts=\"$zreng_udpa_opts\" zreng_tcps_opts=\"$zreng_tcps_opts\" zreng_udps_opts=\"$zreng_udps_opts\"" >> /tmp/zeroe/vars.zre
	fi
fi

#cd to the output dir for better masscan resuming
cd $filepath
#Sets trap for when script stops before finishing
trap whenstopped INT TERM

#=============EXTERNAL=============
if [ "$e_opt" = true ] || [ "$type" = "E" ] || [ "$type" = "e" ] || [ "$type" = "external" ] || [ "$type" = "External" ] || [ "$type" = "Ext" ] || [ "$type" = "ext" ]; then

	#Stage -- start
	if { [[ "$stage" == "discovery-alives" ]] || [[ "$stage" == "script-start" ]]; } && ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; }; then
		echo "discovery-alives" > /tmp/zeroe/stage.zre
		stage="discovery-alives"

		if [[ "$stage" == "discovery-alives" ]] && [[ "$resume" = "y" ]]; then
			echo -e "\e[36m [-] Resuming alive host discovery scans -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		else
			echo -e "\e[35m [=] Zero-E started -- progress updates for scans displayed every 15 minutes \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			echo -e "\e[36m [-] Starting discovery scans -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		fi

		###Nmap alive host discovery
		echo -e "\e[36m [-] Discovering alive hosts with Nmap... \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		ntdscan="nmap -n -vv -sn -oG - --excludefile $nostrikes -iL $ips" #Stored as variable for report generation
		echo "ntdscan=\"$ntdscan\"" >> /tmp/zeroe/vars.zre
		if [[ "$resume" = "y" ]]; then
			resume=''
			nmap --resume "$filepath/logs/misc-files/$typevar-discoscan-nmap.gnmap" 1>>"$filepath/logs/misc-files/$typevar-discoscan-nmap.gnmap" 2>>"$filepath/logs/$typevar-errors.log" &
			echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		else
			#if [[ "$ngineer_mode" == true ]]; then
			#	if [[ "$ngineer_default" == true ]]; then	
			#		eval "$ntdscan" 1>>"$filepath/logs/misc-files/$typevar-discoscan-nmap.gnmap" 2>>"$filepath/logs/$typevar-errors.log" &  #TCP ping scan
			#	else
			#		eval "$zreng_ext_alives - -oG --excludefile $nostrikes -iL $ips" 1>>"$filepath/logs/misc-files/$typevar-discoscan-nmap.gnmap" 2>>"$filepath/logs/$typevar-errors.log" &
			#	fi
			#else
				eval "$ntdscan" 1>>"$filepath/logs/misc-files/$typevar-discoscan-nmap.gnmap" 2>>"$filepath/logs/$typevar-errors.log" &
			#fi
		fi
		#Status indicator
		pid=$!
		periodicfile="$filepath/logs/misc-files/$typevar-discoscan-nmap.gnmap"
		contstatus="Pinging hosts"
		statusnmap
		#Error check and alert
		checked_cmd="$ntdscan"
		wait $pid
		exitstatus=$?
		errorcheck	

		#Stage update
		if [[ "$only_flag" != true && "$stage_cont" == true ]]; then
			echo "discovery-ports" > /tmp/zeroe/stage.zre
			stage="discovery-ports"
		fi
	fi

	#Stage -- start
	if [[ "$stage" == "discovery-ports" ]] && ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; }; then
		#Masscan open port/alive host discovery
		####################################################################
		####### External masscan command if adjustment is necessary ########
		emscan="sudo masscan --open-only -p 1-65535 --rate=5000 --excludefile $nostrikes --include-file $ips -oG $filepath/logs/misc-files/$typevar-discoscan-masscan-tcp.txt"
		echo "emscan=\"$emscan\"" >> /tmp/zeroe/vars.zre
		### Stored as variable to correctly reflect in report if changed ###
		####################################################################
		#^^^If scans are taking too long, remove -p 1-65535 and use --top-ports=32768
		if [[ "$stage" == "discovery-ports" ]] && [[ -f "$(pwd)/paused.conf" ]] && [[ "$resume" = "y" ]]; then
			resume=''
			echo -e "\e[36m [-] Resuming discovery scans -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			masscan --resume paused.conf >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
		else
			if [[ "$ngineer_mode" == true ]]; then
				if [[ "$ngineer_ports_default" == true ]]; then	
					eval "$emscan" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
				else
					echo -e "\e[33m [!] Using ZrE ngineer options for masscan discovery scan \e[0m"
					eval "masscan $zreng_ports_opts --open-only --excludefile $nostrikes --include-file $ips -oG $filepath/logs/misc-files/$typevar-discoscan-masscan-tcp.txt" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
				fi
			else
				eval "$emscan" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			fi
		fi
		pid=$!
		sleep 4
		echo -e "\e[36m [-] Discovering alive hosts and open TCP ports with Masscan... $(grep -o '[0-9]\+:[0-9]\+:[0-9]\+ remaining' "$filepath/logs/misc-files/$typevar-masscan-tcp.log" | tail -1) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		#Status indicator
		periodicfile="$filepath/logs/misc-files/$typevar-masscan-tcp.log"
		contstatus="Scanning TCP ports"
		statusmasscan
		#Error check and alert
		checked_cmd="$emscan"
		wait $pid
		exitstatus=$?
		errorcheck

		#Filter out hosts with more than 100 ports open
		susinput="$filepath/logs/misc-files/$typevar-discoscan-masscan-tcp.txt"
		susips="$filepath/$typevar-100port-hosts-tcp.txt"
		susoutput="$filepath/logs/misc-files/$typevar-discoscan-masscan-tcp-nosusips.txt"
		filtersusips 2>>"$filepath/logs/$typevar-errors.log"

		#Carve out Nmap TCP IP addresses and put them into a file
		if [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ]; then
			awk 'NR==FNR{ips[$0];next} {for (ip in ips) if ($0 !~ ip) print}' $filepath/$typevar-100port-hosts-tcp.txt "$filepath/logs/misc-files/$typevar-discoscan-nmap.gnmap" > $filepath/logs/misc-files/$typevar-discoscan-nmap-nosusips.txt #Filter out hosts with more than 100 open tcp ports from the nmap ping scan results
			cat $filepath/logs/misc-files/$typevar-discoscan-nmap-nosusips.txt | grep 'Up' | awk '{print $2}' >> $filepath/logs/misc-files/$typevar-discoresults.txt
		else
			cat "$filepath/logs/misc-files/$typevar-discoscan-nmap.gnmap" | grep 'Up' | awk '{print $2}' >> $filepath/logs/misc-files/$typevar-discoresults.txt
		fi

		#Carve out Masscan TCP IP addresses and put them into a file
		{ cat $filepath/logs/misc-files/$typevar-discoscan-masscan-tcp-nosusips.txt | grep 'Host' | awk '{print $4}' ; } >> $filepath/logs/misc-files/$typevar-discoresults.txt # this excludes 100port-hosts. {;} groups the piped commands so all output is redirected

		#Stage -- update
		if [ "$udp" = "y" ] || [ "$udp" = "yes" ] || [ "$U_opt" = true ]; then #} && [[ "$stage" != "discovery-lists" && "$stage" != "services-tcp" && "$stage" != "services-udp" && "$stage" != "methodology" ]]; then
			echo "discovery-udp" > /tmp/zeroe/stage.zre
			stage="discovery-udp"
		elif [[ "$stage_cont" == true ]]; then
			echo "discovery-lists" > /tmp/zeroe/stage.zre
			stage="discovery-lists"
		fi

	fi

	#Stage -- start
	if { [[ "$stage" == "discovery-udp" ]] && [[ "$udp" = "y" || "$udp" = "yes" || "$U_opt" = true ]]; } || { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]] && [[ "$stage" != "discovery-lists" && "$stage" != "services-udp" ]]; }; then
		if [[ "$only_flag" == true && "$resume" != "y" ]]; then
		echo -e "\e[35m [=] Zero-E started -- progress updates for scans displayed every 15 minutes \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		fi
		#UDP open port scan
		#15094 top ports is 99% effective. Reference this chart for --top-port number effectiveness: https://nmap.org/book/performance-port-selection.html
		nudpa="nmap -v -Pn -sU --open --min-rate 1000 --max-rate 3000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap" --excludefile $nostrikes -iL $ips -d"
		if [[ "$resume" = "y" ]]; then
			resume=''
			echo -e "\e[36m [-] Resuming UDP discovery scans -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			nmap --resume "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap" >> $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log 2>>"$filepath/logs/$typevar-errors.log" &
		else
			if [[ "$ngineer_mode" == true ]]; then
				if [[ "$ngineer_udpa_default" == true ]]; then	
					eval "$nudpa" >> $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log 2>>"$filepath/logs/$typevar-errors.log" &
				else
					echo -e "\e[33m [!] Using ZrE ngineer options for Nmap UDP discovery scan \e[0m"
					eval "nmap -sU --open $zreng_udpa_opts -oG "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap" --excludefile $nostrikes -iL $ips -d" >> "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log" 2>>"$filepath/logs/$typevar-errors.log" &
				fi
			else
				eval "$nudpa" >> $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log 2>>"$filepath/logs/$typevar-errors.log" &
			fi
		fi
		pid=$!
		echo -e "\e[36m [-] Discovering alive hosts and open UDP ports with Nmap... \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		#Status indicator
		periodicfile="$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log"
		contstatus="Scanning UDP ports"
		statusnmap
		#Error check and alert
		checked_cmd="nmap -v -Pn -sU --open --min-rate 1000 --max-rate 3000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap" --excludefile $nostrikes -iL $ips -d"
		wait $pid
		exitstatus=$?
		errorcheck
		
		#Carve out UDP IP addresses and put them into a file
		if [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ]; then
			awk 'NR==FNR{ips[$0];next} {for (ip in ips) if ($0 !~ ip) print}' $filepath/$typevar-100port-hosts-tcp.txt "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap" > $filepath/logs/misc-files/$typevar-discoscan-nmap-udp-nosusips.txt #Filter out hosts with more than 100 open tcp ports
			cat $filepath/logs/misc-files/$typevar-discoscan-nmap-udp-nosusips.txt | grep '/open' | cut -d ' ' -f2 >> $filepath/logs/misc-files/$typevar-discoresults.txt
		else
			cat "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap" | grep '/open' | cut -d ' ' -f2 >> $filepath/logs/misc-files/$typevar-discoresults.txt
		fi
		
		#Stage -- update
		echo "discovery-lists" > /tmp/zeroe/stage.zre
		stage="discovery-lists"
	fi

	#Stage -- start
	if [[ "$stage" == "discovery-lists" ]]; then
		#Make final list of ordered, unique alive hosts excluding sus ips
		cat $filepath/logs/misc-files/$typevar-discoresults.txt | sort -u | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n > $filepath/$typevar-alives.txt

		#Generate list of all open ports
		if ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; }; then
			echo '===========' > $filepath/$typevar-openports.txt
			echo '    TCP' >> $filepath/$typevar-openports.txt
			echo '===========' >> $filepath/$typevar-openports.txt
			cat $filepath/logs/misc-files/$typevar-discoscan-masscan-tcp-nosusips.txt | grep 'open' | cut -d ' ' -f5 | cut -d '/' -f1 | sort -u >> $filepath/rangetemp.txt
			#continue with ports list
			rangeout="$filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt"
			singleportstorange
			sed -i '/^[ \t]*$/d' "$rangeout" #Removes blank lines and lines that only contain spaces
			cat $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt >> $filepath/$typevar-openports.txt
			echo ' ' >> $filepath/$typevar-openports.txt
		fi
		if [ "$udp" = "y" ] || [ "$udp" = "yes" ] || [ "$U_opt" = true ]; then
			if [[ "$only_flag" == true ]]; then
				echo '===========' > $filepath/$typevar-openports.txt
			else
				echo '===========' >> $filepath/$typevar-openports.txt
			fi
			echo '    UDP' >> $filepath/$typevar-openports.txt
			echo '===========' >> $filepath/$typevar-openports.txt
			if [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ]; then
				cat $filepath/logs/misc-files/$typevar-discoscan-nmap-udp-nosusips.txt | grep '/open' | cut -d ' ' -f4 | cut -d '/' -f1 | sort -u >> $filepath/rangetempu.txt
			else
				cat "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap" | grep '/open' | cut -d ' ' -f4 | cut -d '/' -f1 | sort -u >> $filepath/rangetempu.txt
			fi
			sort -u $filepath/rangetempu.txt >> $filepath/rangetemp.txt
			rm $filepath/rangetempu.txt
			rangeout="$filepath/logs/misc-files/$typevar-portsfornmap-udp.txt"
			singleportstorange
			sed -i '/^[ \t]*$/d' "$rangeout" #Removes blank lines and lines that only contain spaces
			cat $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt >> $filepath/$typevar-openports.txt
		fi
		nessusports 2>/dev/null

		#Status update
		echo -e "\e[32m [+] Alive hosts and open ports discovered -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		if [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ] && [ -s "$filepath/$typevar-100port-hosts-udp.txt" ]; then
			echo -e "\e[33m [!] Excluding potential deception or firewall-protected hosts showing more than 100 open TCP/UDP ports -- recommend inquiring about hosts in ext-100port-hosts-tcp.txt and ext-100port-hosts-udp.txt \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		elif [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ]; then
			echo -e "\e[33m [!] Excluding potential deception or firewall-protected hosts showing more than 100 open TCP ports -- recommend inquiring about hosts in ext-100port-hosts-tcp.txt \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		elif [ -s "$filepath/$typevar-100port-hosts-udp.txt" ]; then
			echo -e "\e[33m [!] Excluding potential deception or firewall-protected hosts showing more than 100 open UDP ports -- recommend inquiring about hosts in ext-100port-hosts-udp.txt \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		fi
		echo -e "\e[33m [!] Generated files for Nessus vulnerability scans -- Hosts: $typevar-alives.txt | Ports: $typevar-portsfornessus.txt \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
	
		#Stage -- update
		if [[ "$only_flag" != true && "$stage_cont" == true ]]; then
			echo "services-tcp" > /tmp/zeroe/stage.zre
			stage="services-tcp"
		elif { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]] && [[ "$stage_cont" == true ]]; }; then
			echo "services-udp" > /tmp/zeroe/stage.zre
			stage="services-udp"
		fi
	
	fi
	
	#Stage -- start
	if [[ "$stage" == "services-tcp" ]]; then
		##Nmap TCP service scans
		#ntportsall="$(cat $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt | paste -sd "," -)"
		#ntports3=$($(head -n 3 $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt | paste -sd "," -),[...])
		ntscan="nmap -sC -sV -Pn -O -p $(cat $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt | paste -sd "," -) --open --reason --excludefile $nostrikes -iL $filepath/$typevar-alives.txt -oA $filepath/$typevar-tcp-servicescan-results"
		echo "ntscan=\"$ntscan\"" >> /tmp/zeroe/vars.zre
		if grep -q "\S" "$filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt"; then
			if [[ "$resume" = "y" ]]; then
				resume=''
				echo -e "\e[36m [-] Resuming TCP service scans \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				nmap --resume $filepath/$typevar-tcp-servicescan-results.gnmap 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
			else
				if [[ "$ngineer_mode" == true ]]; then
					if [[ "$ngineer_tcps_default" == true ]]; then	
						eval "$ntscan -v" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
					else
						echo -e "\e[33m [!] Using ZrE ngineer options for Nmap TCP service scan \e[0m"
						eval "nmap $zreng_tcps_opts -sV -Pn -p $(cat $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt | paste -sd "," -) -oA $filepath/$typevar-tcp-servicescan-results --excludefile $nostrikes -iL $filepath/$typevar-alives.txt" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
					fi
				else
					eval "$ntscan -v" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
				fi
			fi
			pid=$!
			echo -e "\e[36m [-] Scanning services on open TCP ports of alive hosts with Nmap -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			#Status indicator
			periodicfile="$filepath/$typevar-tcp-servicescan-results.nmap"
			contstatus="Scanning TCP ports"
			statusnmap
			#Error check and alert
			checked_cmd="$ntscan"
			wait $pid
			exitstatus=$?
			if [ $exitstatus -eq 0 ]; then
				printf "\r%-${#indicator}s\r" "" #Clears status indicator line
				if [ "$udp" = "y" ] || [ "$udp" = "yes" ] || [ "$U_opt" = true  ]; then
					echo -e "\e[32m [+] Nmap TCP service scan complete, results saved as ext-tcp-servicescan-results -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
					#echo -e "\e[33m [!] Start working with TCP scan results. UDP scans may take a while, depending on the amount of hosts and ports. \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				else
					echo -e "\e[32m [+] Nmap TCP service scan complete, results saved as ext-tcp-servicescan-results -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				fi
			else
				printf "\r%-${#indicator}s\r" "" #Clears status indicator line
				errorcheck
			fi
		else
			echo -e "\e[36m [-] No open TCP ports detected -- TCP service scans skipped \e[0m" | tee -a $filepath/logs/$typevar-timestamps.log
		fi
	
		#Stage -- update
		if { [ "$udp" = "y" ] || [ "$udp" = "yes" ] || [ "$U_opt" = true ]; } && [[ "$stage_cont" == true ]]; then
			echo "services-udp" > /tmp/zeroe/stage.zre
			stage="services-udp"
		#elif [[ "$only_flag" != true && "$stage_cont" == true ]]; then
		#	echo "methodology" > /tmp/zeroe/stage.zre
		#	stage="methodology"
		fi
	
	fi

	#Stage -- start
	if [[ "$stage" == "services-udp" ]] && [[ "$udp" = "y" || "$udp" = "yes"  || "$U_opt" = true ]]; then
		#Nmap UDP service scans
		nsudp="nmap -v -sU -Pn -sV --open --min-rate 1000 --max-rate 3000 --reason -p $(cat $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt | paste -sd "," -) -oA $filepath/$typevar-udp-servicescan-results --excludefile $nostrikes -iL $filepath/$typevar-alives.txt" 
			if grep -q "\S" "$filepath/logs/misc-files/$typevar-portsfornmap-udp.txt"; then
				if [[ "$resume" = "y" ]]; then
					resume=''
					echo -e "\e[36m [-] Resuming UDP service scans \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
					echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
					nmap --resume $filepath/$typevar-udp-servicescan-results.gnmap 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
				else
					if [[ "$ngineer_mode" == true ]]; then
						if [[ "$ngineer_udps_default" == true ]]; then	
							eval "$nsudp" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
						else
							echo -e "\e[33m [!] Using ZrE ngineer options for Nmap UDP service scan \e[0m"
							eval "nmap $zreng_udps_opts -sU -sV -Pn -p $(cat $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt | paste -sd "," -) -oA $filepath/$typevar-udp-servicescan-results --excludefile $nostrikes -iL $filepath/$typevar-alives.txt" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
						fi
					else
						eval "$ntscan -v" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
					fi
				fi
				pid=$!
				echo -e "\e[36m [-] Scanning services on open UDP ports of alive hosts with Nmap -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				#Status indicator
				periodicfile="$filepath/$typevar-udp-servicescan-results.nmap"
				contstatus="Scanning UDP ports"
				statusnmap
				#Error check and alert
				checked_cmd="nmap -v -sU -Pn -sV --open --min-rate 1000 --max-rate 3000 --reason -p $(cat $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt | paste -sd "," -) -oA $filepath/$typevar-udp-servicescan-results --excludefile $nostrikes -iL $filepath/$typevar-alives.txt 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &"
				wait $pid
				exitstatus=$?
				if [ $exitstatus -eq 0 ]; then
					printf "\r%-${#indicator}s\r" "" #Clears status indicator line
					echo -e "\e[32m [+] Nmap UDP service scan complete, results saved as ext-udp-servicescan-results -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				else
					printf "\r%-${#indicator}s\r" "" #Clears status indicator line
					errorcheck
				fi
			else
				echo -e "\e[36m [-] No open UDP ports detected -- UDP service scans skipped \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			fi
		
		#Stage -- update
		#if [[ "$only_flag" != true && "$stage_cont" == true ]]; then
		#	echo "methodology" > /tmp/zeroe/stage.zre 
		#	stage="methodology"
		#fi
	fi

	#Stage -- start
	#if [[ "$stage" == "methodology" ]] && ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; }; then
	#fi #Stage end

	#fi
	zrecleanup
	echo -e "\e[35m [=] Zero-E completed -- happy hacking! \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
	sed -i 's/\x1b\[[0-9;]*m//g' "$filepath/logs/$typevar-timestamps.log"
fi
###===========INTERNAL=============
if [ "$i_opt" = true ] || [ "$type" = "I" ] || [ "$type" = "i" ] || [ "$type" = "internal" ] || [ "$type" = "Internal" ] || [ "$type" = "Int" ] || [ "$type" = "int" ]; then
echo $only_flag
echo $udp

	#Stage -- start
	if { [[ "$stage" == "discovery-alives" ]] || [[ "$stage" == "script-start" ]]; } && ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; }; then
		echo "discovery-alives" > /tmp/zeroe/stage.zre
		stage="discovery-alives"

		#cidrconvert >> $filepath/logs/$typevar-fpingcidrs.txt
		if [[ "$stage" == "discovery-alives" ]] && [[ "$resume" = "y" ]]; then
			resume="y"
			echo -e "\e[36m [-] Resuming alive host discovery scans -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		else
			echo -e "\e[35m [=] Zero-E started -- progress updates for scans displayed every 15 minutes \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			echo -e "\e[36m [-] Starting discovery scans -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		fi
		#Prevent system from sending RST packets by setting the firewall to block packets returning to the Masscan origin port
		oscheck=$(uname)
		if [ $oscheck = "Darwin" ]; then #For st00pid Macs
			macpf=$(sudo pfctl -s info | grep -o "Status: .*" | cut -d' ' -f2) #gets pfctl status
			if [ "$macpf" = "Disabled" ]; then
				sudo pfctl -e >> $filepath/logs/mac-pfctl.log 2>&1 #enable pfctl
			fi
			if sudo pfctl -sr 2>> $filepath/logs/mac-pfctl.log | grep -q "block drop in proto tcp from any to any port 55555"; then #check if rule exists
    			echo -e "\e[33m [!] Firewall rule on port 55555 to prevent RST packets already exists -- skipping rule creation \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			else
				cp "/etc/pf.conf" "$filepath/logs/pf.conf.bak-prescript"
    			echo "block drop in proto tcp from any to any port 55555" | sudo tee -a /etc/pf.conf >> $filepath/logs/mac-pfctl.log #creates the rule
    			sudo pfctl -f /etc/pf.conf >> $filepath/logs/mac-pfctl.log 2>&1 #loads the pfctl configuration
				echo -e "\e[33m [!] Firewall rule created on port 55555 to prevent RST packets \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			fi
		else #For Linux
			if sudo iptables -C INPUT -p tcp --dport 55555 -j DROP 2> /dev/null; then
				echo -e "\e[33m [!] Firewall rule on port 55555 to prevent RST packets already exists -- skipping rule creation \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			else	
				sudo iptables -A INPUT -p tcp --dport 55555 -j DROP
				echo -e "\e[33m [!] Firewall rule created on port 55555 to prevent RST packets \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			fi
		fi

		#Masscan alive host discovery
		alivesmscan="sudo masscan --rate=8000 --src-port=55555 --excludefile $nostrikes --include-file $ips -oG $filepath/logs/misc-files/$typevar-masscanalives-results.txt"
		if [[ "$stage" == "discovery-alives" ]] && [[ -f "$(pwd)/paused.conf" ]] && [[ "$resume" = "y" ]]; then
			resume=''
			{ masscan --resume paused.conf >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 & } && sleep 2
		elif [[ "$stage" == "discovery-alives" ]] || [[ "$stage" == "discovery-alives" && ! -f "$(pwd)/paused.conf" && "$resume" = "y" ]]; then
			if [[ "$stage" == "discovery-alives" && ! -f "$(pwd)/paused.conf" && "$resume" = "y" ]]; then
				echo -e "\e[33m [!] masscan paused.conf file not found -- restarting alive host discovery scans \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			fi
			#fpscan='while IFS= read -r i; do fping -a -q -g "$i" >> "$#filepath/$typevar-fping-results.txt"; done < "$filepath/logs/$typevar-fpingcidrs.txt"'
			if (($total_hosts >= 1 && $total_hosts <= 9999)); then
				checked_cmd="$alivesmscan --top-ports 5000 && sleep 1"
				eval "$alivesmscan --top-ports 5000 && sleep 1" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			elif (($total_hosts >= 10000 && $total_hosts <= 24999)); then
				checked_cmd="$alivesmscan --top-ports 2000 && sleep 1"
				eval "$alivesmscan --top-ports 2000 && sleep 1" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			elif (($total_hosts >= 25000 && $total_hosts <= 49999)); then
				checked_cmd="$alivesmscan --top-ports 1500 && sleep 1"
				eval "$alivesmscan --top-ports 1500 && sleep 1" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			elif (($total_hosts >= 50000 && $total_hosts <= 99999)); then
				checked_cmd="$alivesmscan --top-ports 1000 && sleep 1"
				eval "$alivesmscan --top-ports 1000 && sleep 1" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			elif (($total_hosts >= 100000 && $total_hosts <= 149999)); then
				checked_cmd="$alivesmscan --top-ports 500 && sleep 1"
				eval "$alivesmscan --top-ports 500 && sleep 1" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			elif (($total_hosts >= 150000 && $total_hosts <= 199999)); then
				checked_cmd="$alivesmscan --top-ports 250 && sleep 1"
				eval "$alivesmscan --top-ports 250 && sleep 1" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			elif (($total_hosts >= 200000 && $total_hosts <= 249999)); then
				checked_cmd="$alivesmscan --top-ports 150 && sleep 1"
				eval "$alivesmscan --top-ports 150 && sleep 1" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			elif (($total_hosts >= 250000 && $total_hosts <= 499999)); then
				checked_cmd="$alivesmscan --top-ports 50 && sleep 1"
				eval "$alivesmscan --top-ports 50 && sleep 1" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			elif (($total_hosts >= 500000)); then
				checked_cmd="$alivesmscan --top-ports 20 && sleep 1"
				eval "$alivesmscan --top-ports 20 && sleep 1" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			fi
			pid=$!
			sleep 4
			echo -e "\e[36m [-] Discovering alive hosts with masscan... $(grep -o '[0-9]\+:[0-9]\+:[0-9]\+ remaining' "$filepath/logs/misc-files/$typevar-masscan-tcp.log" | tail -1) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			#Status indicator
			periodicfile="$filepath/logs/misc-files/$typevar-masscan-tcp.log"
			contstatus="Scanning hosts"
			statusmasscan
			#Error check and alert
			wait $pid
			exitstatus=$?
			errorcheck
		fi 
		echo -e "\e[32m [+] Alive hosts discovered -- "$(date)" \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		#Filter out hosts with more than 100 ports open
		susinput="$filepath/logs/misc-files/$typevar-masscanalives-results.txt"
		susips="$filepath/$typevar-100port-hosts-tcp.txt"
		susoutput="$filepath/logs/misc-files/$typevar-discoscan-masscan-tcp-nosusips.txt"
		filtersusips
		#Carve out TCP IP addresses and put them into a file
		cat $filepath/logs/misc-files/$typevar-discoscan-masscan-tcp-nosusips.txt | grep 'Host' | awk '{print $4}' >> $filepath/logs/misc-files/$typevar-discoresults.txt #this excludes 100port-hosts
		#cat $filepath/logs/misc-files/$typevar-masscanalives-results.txt | grep 'Host' | awk '{print $4}' | sort -u >> $filepath/$typevar-masscan-alives.txt
	
		#Stage -- update
		if [[ "$only_flag" != true && "$stage_cont" == true ]]; then
			echo "discovery-ports" > /tmp/zeroe/stage.zre
			stage="discovery-ports"
		fi

	fi
	
	#Stage -- start
	if [[ "$stage" == "discovery-ports" ]] && ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; }; then
		#Masscan open port discovery
		####################################################################
		####### Internal masscan command if adjustment is necessary ########
		imscan="sudo masscan --open-only -p 1-65535 --rate=8000 --src-port=55555 --excludefile $nostrikes --include-file $filepath/logs/misc-files/$typevar-discoresults.txt -oG $filepath/logs/misc-files/$typevar-discoscan-masscan-tcp.txt"
		echo "imscan=\"$imscan\"" >> /tmp/zeroe/vars.zre
		### Stored as variable to correctly reflect in report if changed ###
		####################################################################
		#^^^If scans are taking too long, remove -p 1-65535 and use --top-ports=32768
		#^^^If not getting any, or low number of, alive hosts, use --rate=500
		if [[ "$stage" == "discovery-ports" ]] && [[ -f "$(pwd)/paused.conf" ]] && [[ "$resume" = "y" ]]; then
			resume=''
			echo -e "\e[36m [-] Resuming masscan open port discovery scans -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			masscan --resume paused.conf >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
		else
			if [[ "$ngineer_mode" == true ]]; then
				if [[ "$ngineer_ports_default" == true ]]; then	
					eval "$imscan" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
				else
					echo -e "\e[33m [!] Using ZrE ngineer options for masscan open ports scan \e[0m"
					eval "masscan $zreng_ports_opts --open-only --excludefile $nostrikes --include-file $ips -oG $filepath/logs/misc-files/$typevar-discoscan-masscan-tcp.txt" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
				fi
			else
				eval "$imscan" >> "$filepath/logs/misc-files/$typevar-masscan-tcp.log" 2>&1 &
			fi
		fi
		pid=$!
		sleep 4
		echo -e "\e[36m [-] Discovering open TCP ports with Masscan... $(grep -o '[0-9]\+:[0-9]\+:[0-9]\+ remaining' "$filepath/logs/misc-files/$typevar-masscan-tcp.log" | tail -1) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		#Status indicators
		periodicfile="$filepath/logs/misc-files/$typevar-masscan-tcp.log"
		contstatus="Scanning TCP ports"
		statusmasscan
		#Error check and alert
		checked_cmd="$imscan"
		wait $pid
		exitstatus=$?
		errorcheck

		#Filter out hosts with more than 100 ports open
		susinput="$filepath/logs/misc-files/$typevar-discoscan-masscan-tcp.txt"
		susips="$filepath/$typevar-100port-hosts-tcp.txt"
		susoutput="$filepath/logs/misc-files/$typevar-discoscan-masscan-tcp-nosusips.txt"
		filtersusips
		#Carve out TCP IP addresses and put them into a file
		cat $filepath/logs/misc-files/$typevar-discoscan-masscan-tcp-nosusips.txt | grep 'Host' | awk '{print $4}' >> $filepath/logs/misc-files/$typevar-discoresults.txt #this excludes 100port-hosts
	
		#Stage -- update
		if [ "$udp" = "y" ] || [ "$udp" = "yes" ] || [ "$U_opt" = true ]; then #} && [[ "$stage" != "discovery-lists" && "$stage" != "services-tcp" && "$stage" != "services-udp" && "$stage" != "methodology" ]]; then
			echo "discovery-udp" > /tmp/zeroe/stage.zre
			stage="discovery-udp"
		elif [[ "$stage_cont" == true ]]; then 
			echo "discovery-lists" > /tmp/zeroe/stage.zre
			stage="discovery-lists"
		fi

	fi

	#Stage -- start
	if { [[ "$stage" == "discovery-udp" ]] && [[ "$udp" = "y" || "$udp" = "yes" || "$U_opt" = true ]]; } || { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]] && [[ "$stage" != "discovery-lists" && "$stage" != "services-udp" ]]; }; then
		if [[ "$only_flag" == true && "$resume" != "y" ]]; then
		echo -e "\e[35m [=] Zero-E started -- progress updates for scans displayed every 15 minutes \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		fi
		#UDP open port scan
		if [[ "$resume" = "y" ]]; then
			resume=''
			echo -e "\e[36m [-] Resuming UDP discovery scans -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			nmap --resume "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap" >> $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log 2>>"$filepath/logs/$typevar-errors.log" &
		else
			if [[ "$ngineer_mode" == true ]]; then
				if [[ "$ngineer_udpa_default" == true ]]; then
					if [[ -f $filepath/logs/misc-files/$typevar-discoresults.txt ]]; then
						#15094 top ports is 99% effective. Reference this chart for --top-port number effectiveness: https://nmap.org/book/performance-port-selection.html
						nudpa="nmap -v -Pn -sU --open --min-rate 3000 --max-rate 5000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap --excludefile $nostrikes -iL $filepath/logs/misc-files/$typevar-discoresults.txt -d"
					else
						nudpa="nmap -v -Pn -sU --open --min-rate 3000 --max-rate 5000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap --excludefile $nostrikes -iL $ips -d"
					fi	
					eval "$nudpa" >> $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log 2>> $filepath/logs/$typevar-errors.log &
				else
					echo -e "\e[33m [!] Using ZrE ngineer options for Nmap UDP discovery scan \e[0m"
					if [[ -f $filepath/logs/misc-files/$typevar-discoresults.txt ]]; then
						eval "nmap -sU --open $zreng_udpa_opts -oG $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap --excludefile $nostrikes -iL $filepath/logs/misc-files/$typevar-discoresults.txt -d" >> $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log 2>> $filepath/logs/$typevar-errors.log &
					else
						eval "nmap -sU --open $zreng_udpa_opts -oG $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap --excludefile $nostrikes -iL $ips -d" >> $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log 2>> $filepath/logs/$typevar-errors.log &
					fi
				fi
			else
				if [[ -f $filepath/logs/misc-files/$typevar-discoresults.txt ]]; then
					#15094 top ports is 99% effective. Reference this chart for --top-port number effectiveness: https://nmap.org/book/performance-port-selection.html
					nudpa="nmap -v -Pn -sU --open --min-rate 3000 --max-rate 5000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap --excludefile $nostrikes -iL $filepath/logs/misc-files/$typevar-discoresults.txt -d"
				else
					nudpa="nmap -v -Pn -sU --open --min-rate 3000 --max-rate 5000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap --excludefile $nostrikes -iL $ips -d"
				fi	
				eval "$nudpa" >> $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log 2>> $filepath/logs/$typevar-errors.log &
			fi
		fi
		pid=$!
		echo -e "\e[36m [-] Discovering alive hosts and open UDP ports with Nmap... \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		#Status indicator
		periodicfile="$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.log"
		contstatus="Scanning UDP ports"
		statusnmap
		#Error check and alert
		checked_cmd="nmap -Pn -sU --open --min-rate 3000 --max-rate 5000 --top-ports 15094 --max-retries 3 --host-timeout 30 -oG $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap --excludefile $nostrikes -iL $filepath/logs/misc-files/$typevar-discoresults.txt -d"
		wait $pid
		exitstatus=$?
		errorcheck

		#Carve out UDP IP addresses and put them into a file
		if [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ]; then
			awk 'NR==FNR{ips[$0];next} {for (ip in ips) if ($0 !~ ip) print}' $filepath/$typevar-100port-hosts-tcp.txt $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap > $filepath/logs/misc-files/$typevar-discoscan-nmap-udp-nosusips.txt #Filter out hosts with more than 100 open tcp ports
			cat $filepath/logs/misc-files/$typevar-discoscan-nmap-udp-nosusips.txt | grep '/open' | cut -d ' ' -f2 >> $filepath/logs/misc-files/$typevar-discoresults.txt
		else
			cat "$filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap" | grep '/open' | cut -d ' ' -f2 >> $filepath/logs/misc-files/$typevar-discoresults.txt
		fi

		#Stage -- update
		echo "discovery-lists" > /tmp/zeroe/stage.zre
		stage="discovery-lists"
	fi

	#Stage discovery-lists -- start
	if [[ "$stage" == "discovery-lists" ]]; then
		#Status update
		if [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; then
			echo -e "\e[32m [+] Alive hosts and open ports discovered -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		else
			echo -e "\e[32m [+] Open ports discovered -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		fi
		#Remove firewall rule
		if ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]] }; then
			oscheck=$(uname)
			if [ $oscheck = "Darwin" ]; then #For st00pid Macs
				cp "/etc/pf.conf" "$filepath/logs/pf.conf.bak-postscript"
				sudo sed -i "/block drop in proto tcp from any to any port 55555/d" /etc/pf.conf
				sudo pfctl -f /etc/pf.conf >> $filepath/logs/mac-pfctl.log 2>&1
				if [ "$macpf" = "Disabled" ]; then
					sudo pfctl -d >> $filepath/logs/mac-pfctl.log 2>&1 #disable pfctl
				fi
			else #For Linux	
				sudo iptables -D INPUT -p tcp --dport 55555 -j DROP
			fi
			echo -e "\e[33m [!] Firewall rule removed \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		fi
		
		#Make final list of ordered, unique alive hosts excluding sus ips
		cat $filepath/logs/misc-files/$typevar-discoresults.txt | sort -u | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n > $filepath/$typevar-alives.txt

		#Generate list of all open ports
		if ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; }; then
			echo '===========' > $filepath/$typevar-openports.txt
			echo '    TCP' >> $filepath/$typevar-openports.txt
			echo '===========' >> $filepath/$typevar-openports.txt
			cat $filepath/logs/misc-files/$typevar-discoscan-masscan-tcp-nosusips.txt | grep 'open' | cut -d ' ' -f5 | cut -d '/' -f1 | sort -u >> $filepath/rangetemp.txt
			rangeout="$filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt"
			singleportstorange
			sed -i '/^[ \t]*$/d' "$rangeout" #Removes blank lines and lines that only contain spaces
			cat $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt >> $filepath/$typevar-openports.txt
			echo '' >> $filepath/$typevar-openports.txt
		fi
		if [ "$udp" = "y" ] || [ "$udp" = "yes" ] || [ "$U_opt" = true ]; then
			if [[ "$only_flag" == true ]]; then
				echo '===========' > $filepath/$typevar-openports.txt
			else
				echo '===========' >> $filepath/$typevar-openports.txt
			fi
			echo '    UDP' >> $filepath/$typevar-openports.txt
			echo '===========' >> $filepath/$typevar-openports.txt
			if [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ]; then
				cat $filepath/logs/misc-files/$typevar-discoscan-nmap-udp-nosusips.txt | grep '/open' | cut -d ' ' -f4 | cut -d '/' -f1 | sort -u >> $filepath/rangetemp.txt
			else
				cat $filepath/logs/misc-files/$typevar-discoscan-nmap-udp.gnmap | grep '/open' | cut -d ' ' -f4 | cut -d '/' -f1 | sort -u >> $filepath/rangetemp.txt
			fi
			rangeout="$filepath/logs/misc-files/$typevar-portsfornmap-udp.txt"
			singleportstorange
			sed -i '/^[ \t]*$/d' "$rangeout" #Removes blank lines and lines that only contain spaces
			cat $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt >> $filepath/$typevar-openports.txt
		fi
		nessusports 2>/dev/null
		
		#Status update
		if [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ] && [ -s "$filepath/$typevar-100port-hosts-udp.txt" ]; then
			echo -e "\e[33m [!] Excluding potential deception or firewall-protected hosts showing more than 100 open TCP/UDP ports -- recommend inquiring about hosts in $typevar-100port-hosts-tcp.txt and $typevar-100port-hosts-udp.txt \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		elif [ -s "$filepath/$typevar-100port-hosts-tcp.txt" ]; then
			echo -e "\e[33m [!] Excluding potential deception or firewall-protected hosts showing more than 100 open TCP ports -- recommend inquiring about hosts in $typevar-100port-hosts-tcp.txt \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		elif [ -s "$filepath/$typevar-100port-hosts-udp.txt" ]; then
			echo -e "\e[33m [!] Excluding potential deception or firewall-protected hosts showing more than 100 open UDP ports -- recommend inquiring about hosts in $typevar-100port-hosts-udp.txt \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		fi
		echo -e "\e[33m [!] Generated files for Nessus vulnerability scans -- Hosts: $typevar-alives.txt | Ports: $typevar-portsfornessus.txt \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
	
		#Stage -- update
		if [[ "$only_flag" != true && "$stage_cont" == true ]]; then
			echo "services-tcp" > /tmp/zeroe/stage.zre
			stage="services-tcp"
		elif { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]] && [[ "$stage_cont" == true ]]; }; then
			echo "services-udp" > /tmp/zeroe/stage.zre
			stage="services-udp"
		fi
	
	fi

	#Stage -- start
	if [[ "$stage" == "services-tcp" ]]; then
		#Nmap TCP service scans
		ntscan="nmap -sC -sV -Pn -O -p $(cat $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt | paste -sd "," -) --open --reason -oA $filepath/$typevar-tcp-servicescan-results --excludefile $nostrikes -iL $filepath/$typevar-alives.txt"
		echo "ntscan=\"$ntscan\"" >> /tmp/zeroe/vars.zre
		if grep -q "\S" "$filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt"; then
			if [[ "$resume" = "y" ]]; then
				resume=''
				echo -e "\e[36m [-] Resuming TCP service scans \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				nmap --resume $filepath/$typevar-tcp-servicescan-results.gnmap 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
			else
				if [[ "$ngineer_mode" == true ]]; then
					if [[ "$ngineer_tcps_default" == true ]]; then	
						eval "$ntscan -v" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
					else
						echo -e "\e[33m [!] Using ZrE ngineer options for Nmap TCP service scan \e[0m"
						eval "nmap $zreng_tcps_opts -sV -Pn -p $(cat $filepath/logs/misc-files/$typevar-portsfornmap-tcp.txt | paste -sd "," -) -oA $filepath/$typevar-tcp-servicescan-results --excludefile $nostrikes -iL $filepath/$typevar-alives.txt" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
					fi
				else
					eval "$ntscan -v" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
				fi
			fi
			pid=$!
			echo -e "\e[36m [-] Scanning services on open TCP ports of alive hosts with Nmap -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			#Status indicator
			periodicfile="$filepath/$typevar-tcp-servicescan-results.nmap"
			contstatus="Scanning TCP ports"
			statusnmap
			#Error check and alert
			checked_cmd="$ntscan"
			wait $pid
			exitstatus=$?
			if [ $exitstatus -eq 0 ]; then
				printf "\r%-${#indicator}s\r" "" #Clears status indicator line
				if [ "$udp" = "y" ] || [ "$udp" = "yes" ] || [ "$U_opt" = true ]; then
					echo -e "\e[32m [+] Nmap TCP service scan complete, results saved as $typevar-tcp-servicescan-results -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
					#echo -e "\e[33m [!] Start working with TCP scan results. UDP scans may take a while, depending on the amount of hosts and ports. \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				else
					echo -e "\e[32m [+] Nmap TCP service scan complete, results saved as $typevar-tcp-servicescan-results -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				fi
			else
				printf "\r%-${#indicator}s\r" "" #Clears status indicator line
				errorcheck
			fi
		else
			echo -e "\e[36m [-] No open TCP ports detected -- TCP service scans skipped \e[0m" | tee -a $filepath/logs/$typevar-timestamps.log
		fi

		#Stage -- update
		if { [ "$udp" = "y" ] || [ "$udp" = "yes" ] || [ "$U_opt" = true ]; } && [[ "$stage_cont" == true ]]; then
			echo "services-udp" > /tmp/zeroe/stage.zre
			stage="services-udp"
		#elif [[ "$only_flag" != true && "$stage_cont" == true ]]; then
		#	echo "methodology" > /tmp/zeroe/stage.zre
		#	stage="methodology"
		fi
	
	fi

	#Stage -- start
	if [[ "$stage" == "services-udp" ]] && [[ "$udp" = "y" || "$udp" = "yes" || "$U_opt" = true ]]; then
		#Nmap UDP service scans
		nsudp="nmap -v -sU -Pn -sV --open --min-rate 1000 --max-rate 3000 --reason -p $(cat $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt | paste -sd "," -) -oA $filepath/$typevar-udp-servicescan-results --excludefile $nostrikes -iL $filepath/$typevar-alives.txt"
		if grep -q "\S" "$filepath/logs/misc-files/$typevar-portsfornmap-udp.txt"; then
			if [[ "$resume" = "y" ]]; then
				resume=''
				echo -e "\e[36m [-] Resuming UDP service scans \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				echo -e "\e[36m     Using options from resumed scan \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
				nmap --resume $filepath/$typevar-udp-servicescan-results.gnmap 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
			else
				if [[ "$ngineer_mode" == true ]]; then
					if [[ "$ngineer_udps_default" == true ]]; then	
						eval "$nsudp" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
					else
						echo -e "\e[33m [!] Using ZrE ngineer options for Nmap UDP service scan \e[0m"
						eval "nmap $zreng_udps_opts -sU -sV -Pn -p $(cat $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt | paste -sd "," -) -oA $filepath/$typevar-udp-servicescan-results --excludefile $nostrikes -iL $filepath/$typevar-alives.txt" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
					fi
				else
					eval "$ntscan -v" 1>/dev/null 2>>$filepath/logs/$typevar-errors.log &
				fi
			fi
			pid=$!
			echo -e "\e[36m [-] Scanning services on open UDP ports of alive hosts with Nmap -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			#Status indicator
			periodicfile="$filepath/$typevar-udp-servicescan-results.nmap"
			contstatus="Scanning UDP ports"
			statusnmap
			#Error check and alert
			checked_cmd="nmap -v -sU -Pn -sV --open --min-rate 1000 --max-rate 3000 --reason -p $(cat $filepath/logs/misc-files/$typevar-portsfornmap-udp.txt | paste -sd "," -) -oA $filepath/$typevar-udp-servicescan-results --excludefile $nostrikes -iL $filepath/$typevar-alives.txt"
			wait $pid
			exitstatus=$?
			if [ $exitstatus -eq 0 ]; then
				printf "\r%-${#indicator}s\r" "" #Clears status indicator line
				echo -e "\e[32m [+] Nmap UDP service scan complete, results saved as $typevar-udp-servicescan-results -- $(date) \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
			else
				printf "\r%-${#indicator}s\r" "" #Clears status indicator line
				errorcheck
			fi
		else
			echo -e "\e[36m [-] No open UDP ports detected -- UDP service scans skipped \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
		fi

		#Stage -- update
		#if [[ "$only_flag" != true && "$stage_cont" == true ]]; then
		#	echo "methodology" > /tmp/zeroe/stage.zre 
		#	stage="methodology"
		#fi
	fi

	#Stage -- start
	#if [[ "$stage" == "methodology" ]] && ! { [[ "$udp" == "y" ]] && [[ "$only_flag" == true ]]; }; then		
	#fi #Stage end

	#fi
	zrecleanup
	echo -e "\e[35m [=] Zero-E completed -- happy hacking! \e[0m" | tee -a "$filepath/logs/$typevar-timestamps.log"
	sudo sed -i 's/\x1b\[[0-9;]*m//g' "$filepath/logs/$typevar-timestamps.log"
fi