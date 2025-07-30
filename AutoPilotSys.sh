#!/bin/bash


# Function: Live System Health Report with Logging
view_system_health_report() {
  LOGFILE="/var/log/system_health.log"
  sudo touch "$LOGFILE"
  sudo chmod 644 "$LOGFILE"


  echo "===========================================" | sudo tee -a "$LOGFILE"
  echo "       Live System Health Monitor" | sudo tee -a "$LOGFILE"
  echo "    Press [CTRL+C] to stop monitoring" | sudo  tee -a "$LOGFILE"
  echo "===========================================" | sudo tee -a "$LOGFILE"

  while true; do
    clear
    echo "------ $(date) ------" | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"
    
    echo "🔹 Uptime:" | sudo tee -a "$LOGFILE"
    uptime -p | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"

    echo "🔹 CPU Load:" | sudo tee -a "$LOGFILE"
    top -bn1 | grep "Cpu(s)" | awk '{printf "CPU Usage: %.1f%%\n", 100 - $8}' | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"

    echo "🔹 Memory Usage:" | sudo tee -a "$LOGFILE"
    free -h | awk '/Mem:/ {printf "Used: %s / Total: %s\n", $3, $2}' | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"

    echo "🔹 Disk Usage (/):" | sudo tee -a "$LOGFILE"
    df -h / | awk 'NR==2 {print "Used: "$3 " / Total: "$2 " (" $5 " used)"}' | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"

    echo "🔹 Top 5 Memory Consuming Processes:" | sudo tee -a "$LOGFILE"
    ps aux --sort=-%mem | head -n 3 | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"
    echo "------------------------------------------------" | sudo tee -a "$LOGFILE"
    echo "Report saved in : $LOGFILE"
    break
  done
}

monitor_disk_memory_usage(){

    while true; do
	clear
        echo "================================================"
        echo "        Monitor Disk & Memory Usage"
        echo "================================================"

        echo " You have these disks: "
        lsblk -f -e7 | awk ' {print "NAME: "$1" \t SIZE: "$6" \t LABEL: "$4"  "} '
	echo ""
	echo "================================================"
	echo " Memory (RAM) usage: "
	free -h | awk '/Mem:/ {printf "Used: %s \n Total: %s\n", $3, $2}'
	echo ""
	echo "================================================"
	echo "              Running Processes ID"
	echo "================================================"
	ps -eo pid,user,%cpu,%mem,time,command --sort=-%cpu | head -n 11

	echo""
    break 
  done
}

html_status_report() {
    # Get current user's desktop path
    DESKTOP_PATH="$HOME/Desktop"
    
    # Create filename with timestamp
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    REPORT_FILE="$DESKTOP_PATH/system_status_$TIMESTAMP.html"

    # Begin HTML content
    cat <<EOF > "$REPORT_FILE"
<!DOCTYPE html>
<html>
<head>
    <title>System Status Report - $TIMESTAMP</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f4f4f4; }
        h1 { color: #333; }
        pre { background-color: #fff; padding: 10px; border: 1px solid #ccc; }
        section { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>System Status Report</h1>
    <p><strong>Generated on:</strong> $TIMESTAMP</p>

    <section>
        <h2>Uptime</h2>
        <pre>$(uptime)</pre>
    </section>

    <section>
        <h2>Disk Usage</h2>
        <pre>$(df -h)</pre>
    </section>

    <section>
        <h2>Memory Usage</h2>
        <pre>$(free -h)</pre>
    </section>

    <section>
        <h2>Top Processes</h2>
        <pre>$(ps aux --sort=-%cpu | head -n 10)</pre>
    </section>
</body>
</html>
EOF

    echo "System report saved to: $REPORT_FILE"

}



user_management() {
    while true; do
	clear

	 echo "User Management Script"
   	 echo "======================="
         echo "1. Create a user"
         echo "2. Delete a user"
         echo "3. List users"
         echo "4. Check if a user exists"
         echo "5. Exit"
         echo ""



    read -p "Enter your choice [1-5]: " choice

    case $choice in
        1)
            read -p "Enter new username: " username
            if id "$username" &>/dev/null; then
                echo "User '$username' already exists."
		
            else
                sudo useradd -m "$username"
                echo "User '$username' created."
            fi
            ;;
        2)
            read -p "Enter username to delete: " username
            if id "$username" &>/dev/null; then
                sudo userdel -r "$username"
                echo "User '$username' deleted."
            else
                echo "User '$username' does not exist."
            fi
            ;;
        3)
            echo "Listing users (with UID >= 1000):"
            awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd
            ;;
        4)
            read -p "Enter username to check: " username
            if id "$username" &>/dev/null; then
                echo "User '$username' exists."
            else
                echo "User '$username' does not exist."
            fi
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select a number between 1 and 5."
            ;;
    esac

echo "======================================================"
echo ""

    done
}


# Function to backup and compress a directory
backup_directory() {
    read -p "Enter the directory to back up: " src_dir

    if [ ! -d "$src_dir" ]; then
        echo "Error: Directory '$src_dir' does not exist."
        return 1
    fi

    # Set default backup location
    backup_dir="./backups"
    mkdir -p "$backup_dir"

    # Create a timestamped backup filename
    timestamp=$(date +"%Y%m%d_%H%M%S")
    dir_name=$(basename "$src_dir")
    backup_file="${backup_dir}/${dir_name}_backup_${timestamp}.tar.gz"

    # Create compressed backup
    tar -czf "$backup_file" "$src_dir"

    if [ $? -eq 0 ]; then
        echo "Backup successful: $backup_file"
    else
        echo "Backup failed."
    fi
}

# Function to set up auto backup
setup_auto_backup() {
    read -p "Enter the full path of the directory to back up: " src_dir

    if [ ! -d "$src_dir" ]; then
        echo "Error: Directory '$src_dir' does not exist."
        return 1
    fi

    read -p "Enter backup destination directory (default: ./backups): " backup_dir
    backup_dir=${backup_dir:-"./backups"}

    mkdir -p "$backup_dir"

    read -p "Choose backup frequency (daily, weekly, monthly): " frequency

    case "$frequency" in
        daily)
            cron_time="0 2 * * *" ;;     # Every day at 2:00 AM
        weekly)
            cron_time="0 3 * * 0" ;;     # Every Sunday at 3:00 AM
        monthly)
            cron_time="0 4 1 * *" ;;     # First day of month at 4:00 AM
        *)
            echo "Invalid frequency. Please enter daily, weekly, or monthly."
            return 1 ;;
    esac

    backup_script_path="/usr/local/bin/auto_backup.sh"

    # Create the actual backup script
    cat <<EOF | sudo tee "$backup_script_path" > /dev/null

    timestamp=\$(date +"%Y%m%d_%H%M%S")
    backup_file="${backup_dir}/\$(basename "$src_dir")_backup_\$timestamp.tar.gz"
    tar -czf "\$backup_file" "$src_dir"
EOF

    sudo chmod +x "$backup_script_path"

    # Add cron job
    (crontab -l 2>/dev/null; echo "$cron_time $backup_script_path") | crontab -

    echo "Auto backup scheduled with frequency: $frequency"
    echo "Backup script path: $backup_script_path"
}

port_security_check(){
	while true; do

		OUTPUT="security_check_$(date '+%Y-%m-%d_%H-%M-%S').log"

		if [ -f /var/log/auth.log ]; then
   	 		LOG_FILE="/var/log/auth.log"
		elif [ -f /var/log/secure ]; then
   			 LOG_FILE="/var/log/secure"
		else
    			echo "No known auth log file found!" | tee "$OUTPUT"
   			 exit 1
		fi

		echo "========== SECURITY CHECK REPORT ==========" > "$OUTPUT"
		echo "Date: $(date)" >> "$OUTPUT"
		echo "Log File: $LOG_FILE" >> "$OUTPUT"
		echo "" >> "$OUTPUT"

		echo ">> OPEN PORTS (LISTENING):" >> "$OUTPUT"
		if command -v ss &> /dev/null; then
		    ss -tuln >> "$OUTPUT"
		else
		    netstat -tuln >> "$OUTPUT"
		fi
		echo "" >> "$OUTPUT"

		echo ">> FAILED LOGIN ATTEMPTS:" >> "$OUTPUT"
		grep -i "failed\|invalid" "$LOG_FILE" | tail -n 20 >> "$OUTPUT"
		echo "" >> "$OUTPUT"

		
		echo ">> SUCCESSFUL ROOT LOGINS:" >> "$OUTPUT"
		grep "session opened for user root" "$LOG_FILE" | tail -n 10 >> "$OUTPUT"
		echo "" >> "$OUTPUT"

		
		echo ">> TOP SOURCES OF FAILED LOGIN ATTEMPTS:" >> "$OUTPUT"
		grep -i "failed\|invalid" "$LOG_FILE" | \
		    grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
		    sort | uniq -c | sort -nr | head -n 10 >> "$OUTPUT"
		echo "" >> "$OUTPUT"

		echo "Security check complete. Report saved to $OUTPUT"

		break
	done

}


pkgupdate_manager(){

	while true; do
		echo "=================================================="
		echo "		Enter your Password : "

		while true; do
			echo "         Your system is being updating! \n please Wait....."
			sudo apt update
			sudo apt upgrade
		echo ""
		echo "		Your System is updated!."
		break
		done
	done
}



while true; do
	echo "====================================================="
	echo "          🚀 AutoPilotSys - Linux Toolbox            "
	echo "          Your Server Automation Companion           "
	echo "====================================================="
	echo ""
	echo "1. View System Health Report "
	echo "2. Monitor Disk & Memory Usage "
	echo "3. Generate Html Status Report "
	echo "4. User Management "
	echo "5. Backup & Compress Directory "
	echo "6. Setup Schedules Auto-Backup "
	echo "7. Security Check (Ports + Logs) "
	echo "8. Package & OS Update Manager "
	echo "9. Exit "
	echo "====================================================="
	read -p "Choose an Option [1-10]: " choice

	case $choice in
		1) view_system_health_report
 		;;

		2) monitor_disk_memory_usage
		;;

		3) html_status_report
		;;

		4) user_management
		;;

		5) backup_directory
		;;

		6) setup_auto_backup
		;;

		7) port_security_check
		;;

		8) pkgupdate_manager
		;;

		9) echo "Thanks for using | Goodbye"
		exit
		;;
		*) echo "-----------------------------------------------"
		   echo "Invalid Task | Choose from 1 to 10"
		;;
	esac
echo""
echo""

done
#!/bin/bash

# Function: Live System Health Report with Logging
view_system_health_report() {
  LOGFILE="/var/log/system_health.log"
  sudo touch "$LOGFILE"
  sudo chmod 644 "$LOGFILE"

  echo "===========================================" | sudo tee -a "$LOGFILE"
  echo "       Live System Health Monitor" | sudo tee -a "$LOGFILE"
  echo "    Press [CTRL+C] to stop monitoring" | sudo tee -a "$LOGFILE"
  echo "===========================================" | sudo tee -a "$LOGFILE"

  while true; do
    clear
    echo "------ $(date) ------" | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"

    echo "🔹 Uptime:" | sudo tee -a "$LOGFILE"
    uptime -p | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"

    echo "🔹 CPU Load:" | sudo tee -a "$LOGFILE"
    top -bn1 | grep "Cpu(s)" | awk '{printf "CPU Usage: %.1f%%\n", 100 - $8}' | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"

    echo "🔹 Memory Usage:" | sudo tee -a "$LOGFILE"
    free -h | awk '/Mem:/ {printf "Used: %s / Total: %s\n", $3, $2}' | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"

    echo "🔹 Disk Usage (/):" | sudo tee -a "$LOGFILE"
    df -h / | awk 'NR==2 {print "Used: "$3 " / Total: "$2 " (" $5 " used)"}' | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"

    echo "🔹 Top 5 Memory Consuming Processes:" | sudo tee -a "$LOGFILE"
    ps aux --sort=-%mem | head -n 6 | sudo tee -a "$LOGFILE"
    echo "" | sudo tee -a "$LOGFILE"
    echo "------------------------------------------------" | sudo tee -a "$LOGFILE"
    echo "Report saved in : $LOGFILE"
    break
  done
}

monitor_disk_memory_usage() {
  clear
  echo "================================================"
  echo "        Monitor Disk & Memory Usage"
  echo "================================================"

  echo "You have these disks:"
  lsblk -f -e7 | awk '{print "NAME: "$1"\tSIZE: "$4"\tLABEL: "$3}'

  echo ""
  echo "================================================"
  echo "Memory (RAM) usage:"
  free -h | awk '/Mem:/ {printf "Used: %s\nTotal: %s\n", $3, $2}'

  echo ""
  echo "================================================"
  echo "Running Top Processes by CPU:"
  echo "================================================"
  ps -eo pid,user,%cpu,%mem,time,command --sort=-%cpu | head -n 10
}

html_status_report() {
  DESKTOP_PATH="$HOME/Desktop"
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  REPORT_FILE="$DESKTOP_PATH/system_status_$TIMESTAMP.html"

  cat <<EOF > "$REPORT_FILE"
<!DOCTYPE html>
<html>
<head>
  <title>System Status Report - $TIMESTAMP</title>
  <style>
    body { font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px; }
    h1 { color: #333; }
    section { margin-bottom: 20px; }
    pre { background: #fff; padding: 10px; border: 1px solid #ccc; }
  </style>
</head>
<body>
  <h1>System Status Report</h1>
  <p><strong>Generated on:</strong> $TIMESTAMP</p>

  <section>
    <h2>Uptime</h2>
    <pre>$(uptime)</pre>
  </section>
  <section>
    <h2>Disk Usage</h2>
    <pre>$(df -h)</pre>
  </section>
  <section>
    <h2>Memory Usage</h2>
    <pre>$(free -h)</pre>
  </section>
  <section>
    <h2>Top Processes</h2>
    <pre>$(ps aux --sort=-%cpu | head -n 10)</pre>
  </section>
</body>
</html>
EOF

  echo "System report saved to: $REPORT_FILE"
}

user_management() {
  while true; do
    clear
    echo "User Management Script"
    echo "======================="
    echo "1. Create a user"
    echo "2. Delete a user"
    echo "3. List users"
    echo "4. Check if a user exists"
    echo "5. Exit"
    echo ""

    read -p "Enter your choice [1-5]: " choice
    case $choice in
      1)
        read -p "Enter new username: " username
        if id "$username" &>/dev/null; then
          echo "User '$username' already exists."
        else
          sudo useradd -m "$username"
          echo "User '$username' created."
        fi
        ;;
      2)
        read -p "Enter username to delete: " username
        if id "$username" &>/dev/null; then
          sudo userdel -r "$username"
          echo "User '$username' deleted."
        else
          echo "User '$username' does not exist."
        fi
        ;;
      3)
        echo "Listing users (UID >= 1000):"
        awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd
        ;;
      4)
        read -p "Enter username to check: " username
        if id "$username" &>/dev/null; then
          echo "User '$username' exists."
        else
          echo "User '$username' does not exist."
        fi
        ;;
      5)
        echo "Exiting..."
        break
        ;;
      *)
        echo "Invalid option. Choose 1-5."
        ;;
    esac
    read -p "Press [Enter] to continue..."
  done
}

backup_directory() {
  read -p "Enter the directory to back up: " src_dir
  if [ ! -d "$src_dir" ]; then
    echo "Error: Directory '$src_dir' does not exist."
    return 1
  fi

  backup_dir="./backups"
  mkdir -p "$backup_dir"

  timestamp=$(date +"%Y%m%d_%H%M%S")
  dir_name=$(basename "$src_dir")
  backup_file="${backup_dir}/${dir_name}_backup_${timestamp}.tar.gz"

  tar -czf "$backup_file" "$src_dir" && echo "Backup successful: $backup_file" || echo "Backup failed."
}

setup_auto_backup() {
  read -p "Enter the full path of the directory to back up: " src_dir
  [ ! -d "$src_dir" ] && echo "Error: Directory does not exist." && return 1

  read -p "Enter backup destination directory (default: ./backups): " backup_dir
  backup_dir=${backup_dir:-"./backups"}
  mkdir -p "$backup_dir"

  read -p "Choose backup frequency (daily, weekly, monthly): " frequency
  case "$frequency" in
    daily) cron_time="0 2 * * *" ;;
    weekly) cron_time="0 3 * * 0" ;;
    monthly) cron_time="0 4 1 * *" ;;
    *) echo "Invalid frequency." && return 1 ;;
  esac

  backup_script_path="/usr/local/bin/auto_backup.sh"
  sudo tee "$backup_script_path" > /dev/null <<EOF
#!/bin/bash
timestamp=\$(date +"%Y%m%d_%H%M%S")
backup_file="${backup_dir}/\$(basename "$src_dir")_backup_\$timestamp.tar.gz"
tar -czf "\$backup_file" "$src_dir"
EOF

  sudo chmod +x "$backup_script_path"
  (crontab -l 2>/dev/null; echo "$cron_time $backup_script_path") | crontab -
  echo "Auto backup scheduled: $frequency | Script: $backup_script_path"
}

port_security_check() {
  OUTPUT="security_check_$(date '+%Y-%m-%d_%H-%M-%S').log"
  LOG_FILE=""

  if [ -f /var/log/auth.log ]; then
    LOG_FILE="/var/log/auth.log"
  elif [ -f /var/log/secure ]; then
    LOG_FILE="/var/log/secure"
  else
    echo "No known auth log file found!" | tee "$OUTPUT"
    return
  fi

  echo "========== SECURITY CHECK REPORT ==========" > "$OUTPUT"
  echo "Date: $(date)" >> "$OUTPUT"
  echo "Log File: $LOG_FILE" >> "$OUTPUT"
  echo "" >> "$OUTPUT"

  echo ">> OPEN PORTS:" >> "$OUTPUT"
  if command -v ss &> /dev/null; then
    ss -tuln >> "$OUTPUT"
  else
    netstat -tuln >> "$OUTPUT"
  fi

  echo "" >> "$OUTPUT"
  echo ">> FAILED LOGIN ATTEMPTS:" >> "$OUTPUT"
  grep -i "failed\|invalid" "$LOG_FILE" | tail -n 20 >> "$OUTPUT"

  echo "" >> "$OUTPUT"
  echo ">> SUCCESSFUL ROOT LOGINS:" >> "$OUTPUT"
  grep "session opened for user root" "$LOG_FILE" | tail -n 10 >> "$OUTPUT"

  echo "" >> "$OUTPUT"
  echo ">> TOP SOURCES OF FAILED LOGIN ATTEMPTS:" >> "$OUTPUT"
  grep -i "failed\|invalid" "$LOG_FILE" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
    sort | uniq -c | sort -nr | head -n 10 >> "$OUTPUT"

  echo "Security check complete. Report saved to $OUTPUT"
}

pkgupdate_manager() {
  echo "=================================================="
  echo "System Update Starting..."

  sudo apt update && sudo apt upgrade -y
  echo ""
  echo "✅ Your system is up to date!"
}

# Main Menu
while true; do
  clear
  echo "====================================================="
  echo "          🚀 AutoPilotSys - Linux Toolbox            "
  echo "          Your Server Automation Companion           "
  echo "====================================================="
  echo ""
  echo "1. View System Health Report"
  echo "2. Monitor Disk & Memory Usage"
  echo "3. Generate HTML Status Report"
  echo "4. User Management"
  echo "5. Backup & Compress Directory"
  echo "6. Setup Scheduled Auto-Backup"
  echo "7. Security Check (Ports + Logs)"
  echo "8. Package & OS Update Manager"
  echo "9. Exit"
  echo "====================================================="
  read -p "Choose an Option [1-9]: " choice

  case $choice in
    1) view_system_health_report ;;
    2) monitor_disk_memory_usage ;;
    3) html_status_report ;;
    4) user_management ;;
    5) backup_directory ;;
    6) setup_auto_backup ;;
    7) port_security_check ;;
    8) pkgupdate_manager ;;
    9) echo "Thanks for using AutoPilotSys. Goodbye!"; exit ;;
    *) echo "Invalid Option. Please choose 1-9." ;;
  esac

  echo ""
  read -p "Press [Enter] to return to the main menu..."
done
