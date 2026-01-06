#!/bin/bash

#======================================================================#
#==================_____________WELCOME_____________===================# 
#======================================================================#

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "[ERROR] This script must be run as root"
        exit 1
    fi
}

########################################################################
############      Nmap scan and system Maintenance     #################
########################################################################

Get_IP () {
# Get current IP 
MYIP=$(hostname -I | awk '{print $1}' | tr -d ' ')
}

########################################################################

show_menu_1() {
    clear
    echo "----- System & Package Maintenance -----"
    echo -e " 1 - Show open ports & service version"
    echo -e " 2 - Show OS version"
    echo -e " 3 - Update package lists"
    echo -e " 4 - Upgrade installed packages"
	echo -e " 5 - Removing unused packages "
	echo -e " 6 - clean package cache "
	echo -e " 7 - Back to main menu "
    echo "-----------------------------------------------"
    read -p "Enter your choice [1-7]: " show_menu_1_in
}

########################################################################

show_OP() {

	echo -e "If an error occurs, it means there may be no open ports"
	read -p "Press Enter to continue..."
	Get_IP
	nmap -sV --open "$MYIP"
	if [[ $? -eq 0 ]]; then
        echo ""
    else
        echo "No any open ports"
    fi
}

########################################################################
show_OS() {


	Get_IP
	sudo nmap -O "$MYIP" 2>/dev/null | grep -E "^OS details:.*Linux" | grep -o "Linux.*" || echo "No Linux OS detected"
}

########################################################################
update_system() {
    
	echo -e " Updatting......"
    # Update package lists
    apt update -qq
		if [[ $? -eq 0 ]]; then
        echo "Updated successfully!"
    else
        echo "Failed to update."
    fi

    echo "-------------------------------------"
   
}

########################################################################

Remove_Unused() {
	
    echo -e " removing unused packages."
    # Remove unused packages
    apt autoremove -y > /dev/null 2>&1
    apt autoclean -y > /dev/null 2>&1
	echo -e " removed unused packages."
}
#########################################################################

Clean_Cache() {
	
  
    #Clean package caches
    apt clean -y > /dev/null 2>&1
	echo -e " removed cache"
}

########################################################################

Upgrade_system() {
    echo -e " ---This operation may require extended processing time---"

    # Upgrade existing packages
    apt upgrade -y > /dev/null 2>&1
	
    # Full upgrade (handles kernel upgrades too)
    apt dist-upgrade -y > /dev/null 2>&1

    # Install unattended upgrade package if not installed
    apt install -y unattended-upgrades > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
        echo "Upgraded successfully!"
    else
        echo "Failed to Upgrade."
    fi

    echo "-------------------------------------"
}

########################################################################

main_1() {
	echo  "---- Please wait ----"
	apt install nmap -y > /dev/null 2>&1
	echo "---- nmap installed successfully ----"
    while true; do
		echo  "---- Please wait ----"
		apt install nmap -y > /dev/null 2>&1
		echo "---- nmap installed successfully ----"
        show_menu_1
        
        case $show_menu_1_in in
            1)
                show_OP
				read -p "Press Enter to continue..."
                ;;
            2)
                show_OS
				read -p "Press Enter to continue..."
                ;;
            3)
                update_system
				read -p "Press Enter to continue..."
                ;;
            4)
                Upgrade_system
				read -p "Press Enter to continue..."
                ;;  
			5)
                Remove_Unused
				read -p "Press Enter to continue..."
                ;;
			6)
                Clean_Cache
				read -p "Press Enter to continue..."
                ;;
				
			7)
                break
                ;;	
				
            *)
               echo -e "Invalid option. Please select 0-9."
                sleep 2
                ;;
        esac
    done
}

########################################################################
##########      END of Nmap scan and system Maintenance      ###########
########################################################################

########################################################################
###################          IPtables             ######################
########################################################################

Show_IPtable() {
	echo "-------------------------------------"
	echo "      CURRENT IPTABLES RULES"
	echo "-------------------------------------"

	iptables -L -v -n --line-numbers

	echo "-------------------------------------"
	read -p "Press Enter to continue..."
}

########################################################################

show_menu_2() {
    clear
    echo "----- IPtables -----"
    echo -e " 1 - Show rules"
    echo -e " 2 - Set default rules"
    echo -e " 3 - Save IPtables"
    echo -e " 4 - Delete rules"
	echo -e " 5 - Start IPtables services "
	echo -e " 6 - Stop IPtables services"
	echo -e " 7 - Restart IPtable services"
	echo -e " 8 - Flush IPtables "
	echo -e " 9 - Make rules "
	echo -e " 0 - Back to main menu "
    echo "-----------------------------------------------"
    read -p "Enter your choice [0-9]: " show_menu_2_in
}

########################################################################

Show_Main_2() {
    clear
    echo "-----“If you use UFW and iptables rules together, they can conflict.” -----"
    echo -e " 1 - Disable UFW and setup IPtables"
    echo -e " 2 - Keep UFW and exit"
    echo "-----------------------------------------------"
    read -p "Enter your choice [0-9]: " Show_Main_2_in
}

########################################################################

Main_IPtable() {
    
    while true; do
        show_menu_2
        
        case $show_menu_2_in in
            1)	
				Show_IPtable
				          
                ;;
            2)
				echo "configuring iptables default rules..."

				iptables -F
				iptables -X
				iptables -t nat -F
				iptables -t nat -X
				iptables -t mangle -F
				iptables -t mangle -X

				# example default settings
				iptables -P INPUT DROP
				iptables -P OUTPUT ACCEPT
				iptables -P FORWARD DROP

				iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
				# SSH
				iptables -A INPUT -p tcp --dport 22 -j ACCEPT  
				# Localhost
				iptables -A INPUT -i lo -j ACCEPT              

				echo "iptables configured successfully!"
				read -p "Press Enter to continue..."
                ;;
            3)
				echo "Saving iptables rules to /etc/iptables.rules..."
				iptables-save > /etc/iptables.rules
				echo "Rules saved successfully!"
				read -p "Press Enter to continue..."
                
                ;;
            4)
                Delete_rule
                read -p "Press Enter to continue..."
                ;;
            5)
				systemctl start netfilter-persistent
				echo "Service started."
				read -p "Press Enter to continue..."
                ;;
            6)
                systemctl stop netfilter-persistent
				echo "Service stopped."
				read -p "Press Enter to continue..."
                ;;
            7)
                systemctl restart netfilter-persistent
				echo "Service restarted."
				read -p "Press Enter to continue..."
				;;
            8)
                echo "----------------- WARNING -----------------"
				echo "--- This will remove all iptables rules!---"
				read -p "----------- Are you sure?(Y/N): -----------" confirm
				if [[ "$confirm" == "Y" ]]; then
					iptables -F
					iptables -X
					iptables -t nat -F
					iptables -t nat -X
					iptables -t mangle -F
					iptables -t mangle -X
					echo "All iptables rules flushed!"
					
					
				else
					echo "Operation cancelled."
				fi
				read -p "Press Enter to continue..."
                ;;
            9)
				Make_rule
                ;;
            0)
				main
				;;
            *)
                echo -e "Invalid option. Please select 0-9."
                sleep 2
                ;;
        esac
    done
}

##########################  IPtable Delete rule #########################

Delete_rule() {
	clear
	echo "-------------------------------------"
	echo "      CURRENT IPTABLES RULES"
	echo "-------------------------------------"
	iptables -L -v -n --line-numbers
	echo "-------------------------------------"	
	read -p "Enter the chain name (INPUT, OUTPUT, FORWARD) or 'q' to quit: " chain_name
	
	if [[ "$chain_name" == "q"  ]]; then
		echo "Exiting..."
        Main_IPtable
    fi
	
	if [[ "$chain_name" != "INPUT" && "$chain_name" != "OUTPUT" && "$chain_name" != "FORWARD" ]]; then
        echo "Invalid chain name! Please try again."
        sleep 2
        return
    fi
	echo "-------------------------------------"
	read -p "Enter the rule number to delete from $chain_name (or 'q' to quit): " rule_num
	
	if [[ "$rule_num" == "q"  ]]; then
		echo "Exiting..."
        Main_IPtable
    fi
	
    if ! [[ "$rule_num" =~ ^[0-9]+$ ]]; then
        echo "Invalid rule number! Please enter a number."
        sleep 2
        return
    fi
	echo "-------------------------------------"
	
	iptables -D $chain_name $rule_num
	if [[ $? -eq 0 ]]; then
        echo "Rule #$rule_num from $chain_name deleted successfully!"
    else
        echo "Failed to delete rule. Please check the number and chain."
    fi

    echo "-------------------------------------"
    
}

########################    IPtable make rule   ########################

Chain_Name() {
    clear
    echo "----- select Chain -----"
    echo -e " 1 - INPUT"
    echo -e " 2 - OUTPUT"
    echo -e " 3 - FORWARD"
    echo -e " 4 - EXIT"
    echo ""
    
	
    while true; do  
		read -p "Enter your choice [1-4]: " Chain_Num_In
        case $Chain_Num_In in
            1)	
				chain="INPUT"
				return
                ;;
            2)
                chain="OUTPUT"
				return
                ;;
            3)
                chain="FORWARD"
				return
                ;;
            4)
               
                main_2
                ;;
            *)
                echo -e "Invalid option. Please select [1-4]."
                sleep 2
                ;;
        esac
    done
}
	
Insert_mode() {
    clear
    echo "----- select Insert_mode -----"
    echo -e " 1 - Insert (at the top)"
    echo -e " 2 - Append (at the end)"
    echo -e " 3 - Delete"
    echo -e " 4 - EXIT"
    echo ""
  
	
    while true; do 
	read -p "Enter your choice [1-4]: " Insert_Num
        case $Insert_Num in
            1)	
				Insert="-I"
				return
                ;;
            2)
				Insert="-A"
				return
                ;;
            3)
				Insert="-D"
				return
                ;;
            4)
               
                main_2
                ;;
            *)
                echo -e "Invalid option. Please select [1-4]."
                sleep 2
                ;;
        esac
    done
}

Protocol() {
    clear
    echo "----- select Protocol -----"
    echo -e " 1 - All"
    echo -e " 2 - TCP"
    echo -e " 3 - UDP"
    echo -e " 4 - ICMP"
	echo -e " 5 - EXIT"
    echo ""

	
    while true; do
    read -p "Enter your choice [1-5]: " Proto_Num	
        case $Proto_Num in
            1)	
				proto=""
				return
                ;;
            2)
				proto="-p tcp"
				return
                ;;
            3)
				proto="-p udp"
				return
                ;;
            4)
				proto="-p icmp"
				return
                ;; 
		
			5)         
                main_2
                ;; 	
				
            *)
                echo -e "Invalid option. Please select [1-5]."
                sleep 2
                ;;
        esac
    done
}

Source_IP() {
    clear
    echo "----- Source address -----"
    echo -e " 1 - Enter source IP or subnet"
    echo -e " 2 - Any source"
	echo -e " 3 - EXIT"
    echo ""

	
    while true; do 
    read -p "Enter your choice [1-3]: " Source_Num	
        case $Source_Num in
            1)	
				clear
				read -p "Enter your Source IP address or subnet [example: 10.10.10.1 or 10.10.10.0/24]: " Source_IP_In
				SIP="-s $Source_IP_In"
				return
                ;;
            2)
				SIP=""
				return
                ;;
			3)         
                main_2
                ;; 					
            *)
                echo -e "Invalid option. Please select [1-3]."
                sleep 2
                ;;
        esac
    done
}

Source_Port() {
    clear
    echo "----- Source port numbers-----"
    echo -e " 1 - Enter source Port"
    echo -e " 2 - Any Port"
	echo -e " 3 - EXIT"
    echo ""
    
	
    while true; do
	read -p "Enter your choice [1-3]: " SPort_Num
        case $SPort_Num in
            1)	
				clear
				read -p "Enter your Source port numbers [example: 20,21,22,80]: " Source_Port_In
				sport_out="--Sport $Source_Port_In"
				return
                ;;
            2)
				sport_out=""
				return
                ;;
			3)         
                main_2
                ;;				
            *)
                echo -e "Invalid option. Please select [1-3]."
                sleep 2
                ;;
        esac
    done
}

Destination_IP() {
    clear
    echo "----- Destination address -----"
    echo -e " 1 - Enter Destination IP or subnet"
    echo -e " 2 - Any Destination"
	echo -e " 3 - EXIT"
    echo ""
    
	
    while true; do
	read -p "Enter your choice [1-2]: " Destination_Num
        case $Destination_Num in
            1)	
				clear
				read -p "Enter your Destination IP address or subnet [example: 10.10.10.1 or 10.10.10.0/24]: " Destination_IP_In
				DIN="-d $Destination_IP_In"
				return
                ;;
            2)
				DIN=""
				return
                ;;		
			3)         
                main_2
                ;;
            *)
                echo -e "Invalid option. Please select [1-3]."
                sleep 2
                ;;
        esac
    done
}

Destination_Port() {
    clear
    echo "----- Destination port numbers-----"
    echo -e " 1 - Enter Destination Port"
    echo -e " 2 - Any Port"
	echo -e " 3 - EXIT"
    echo ""
    
	
    while true; do
	read -p "Enter your choice [1-2]: " DPort_Num
        case $DPort_Num in
            1)	
				clear
				read -p "Enter your Destination port numbers [example: 20,21,22,80]: " Destination_Port_In
				dport_out="--dport $Destination_Port_In"
				return
                ;;
            2)
				dport_out=""
				return
                ;;	
			3)         
                main_2
                ;;				
            *)
                echo -e "Invalid option. Please select [1-3]."
                sleep 2
                ;;
        esac
    done
}

Action() {
    clear
    echo "----- Select an action-----"
    echo -e " 1 - ACCEPT"
    echo -e " 2 - DROP (silently)"
	echo -e " 3 - REJECT"
	echo -e " 4 - EXIT"
    echo ""
    
	
    while true; do 
	read -p "Enter your choice [1-2]: " Action_Num
        case $Action_Num in
            1)				
				Action_In="-j ACCEPT"
				return
                ;;
            2)
				Action_In="-j DROP"
				return
                ;;
			3)
				Action_In="-j REJECT"
				return
                ;;
			4)         
                main_2
                ;;				
            *)
                echo -e "Invalid option. Please select [1-4]."
                sleep 2
                ;;
        esac
    done
}

Make_rule() {
	Chain_Name
	Insert_mode
	Protocol
	Source_IP
	Source_Port
	Destination_IP
	Destination_Port
	Action
	echo -e "This is your rule:"
	IP_RULE=$"iptables $Insert $chain $proto $SIP $sport_out $DIN $dport_out $Action_In"
	echo -e "$IP_RULE"
	echo -e ""
	echo -e ""
	echo -e "------- select one -------"
	echo -e " 1 - Apply this rule"
	echo -e " 2 - Make a rule again"
	echo -e " 3 - Exit"
	 while true; do
	read -p "Enter your choice [1-3]: " MR_In
        case $MR_In in
            1)	
				$IP_RULE
				if [[ $? -eq 0 ]]; then
					echo "-----------success!-----------"
				else
					echo "-----------Failed!-----------"
				fi
				read -p "Press Enter to continue..."
				return
                ;;
            2)
				Make_rule
                ;;
			3)         
                Main_IPtabFlush IPtables 
le
                ;;				
            *)
                echo -e "Invalid option. Please select [1-3]."
                sleep 2
                ;;
        esac
    done
	
	
	
}

####################   IPtable main   #######################

main_2() {
if command -v ufw >/dev/null 2>&1; then
    echo "UFW is installed on this system."
	Show_Main_2
	case $Show_Main_2_in in
        1)
            echo "Disabling UFW..."
            ufw disable
            echo "Removing UFW rules..."
            ufw reset
            echo "Uninstalling UFW..."
            apt remove -y ufw

            echo "Now configuring iptables default rules..."
			apt install -y iptables-persistent 
			systemctl enable --now netfilter-persistent

            iptables -F
            iptables -X
            iptables -t nat -F
            iptables -t nat -X
            iptables -t mangle -F
            iptables -t mangle -X

            iptables -P INPUT DROP
            iptables -P OUTPUT ACCEPT
            iptables -P FORWARD DROP

            iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
            iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # SSH
            iptables -A INPUT -i lo -j ACCEPT              # Localhost

            echo "iptables configured successfully!"
			Show_IPtable
			Main_IPtable
            ;;

        2)
            echo "Keeping UFW enabled!"
            echo "Exiting..."
            exit 0
            ;;

        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac
else
	
	Main_IPtable
fi
}

########################################################################
###################       END of IPtables         ######################
########################################################################

########################################################################
#######################      TCPDUMP       #############################
########################################################################


menuTCPDUMP() {
    clear
    echo "-------------------- Select one --------------------"
    echo "1) All traffic on your primary network interface"
    echo "2) All traffic on all interfaces"
    echo "3) Traffic from specific IP"
    echo "4) SSH traffic"
    echo "5) HTTP traffic to specific host"
    echo "6) ICMP (Ping)"
    echo "7) TCP SYN packets only"
    echo "8) Specific port"
    echo "9) Back to main menu"
    echo "----------------------------------------------------"
}

choose_limit() {
    echo ""
    echo "----- Capture stop condition -----"
    echo "1) Stop after number of packets"
    echo "2) Stop after time (seconds)"
    echo "3) Run until Ctrl + C"
    echo "----------------------------------"
    read -p "Choose [1-3]: " LIMIT_CHOICE

    PACKET_LIMIT=""
    TIME_LIMIT=""

    case $LIMIT_CHOICE in
        1)
            read -p "Enter number of packets: " PACKET_LIMIT_In
			PACKET_LIMIT="-c $PACKET_LIMIT_In"
            ;;
        2)
            read -p "Enter time in seconds: " TIME_LIMIT_In
			TIME_LIMIT="timeout $TIME_LIMIT_In"
            ;;
        3)
            ;;
        *)
            echo "Invalid option, running until Ctrl + C."
            ;;
    esac
}

Do_tcpdump() {
	
	
    case $1 in
        1)
			choose_limit
            $TIME_LIMIT tcpdump -i $INTERFACE $PACKET_LIMIT
			
            ;;
        2)	
			choose_limit
            $TIME_LIMIT tcpdump -i any $PACKET_LIMIT
            ;;
        3)
			choose_limit
            read -p "Enter IP address: " IP
            $TIME_LIMIT tcpdump -i $INTERFACE host "$IP" $PACKET_LIMIT
            ;;
        4)
            choose_limit
			$TIME_LIMIT tcpdump -i $INTERFACE port 22 $PACKET_LIMIT
            ;;
        5)
            choose_limit
			read -p "Enter destination host IP: " HOST
            $TIME_LIMIT tcpdump -i $INTERFACE tcp port 80 and host "$HOST" $PACKET_LIMIT
            ;;
        6)
            choose_limit
			$TIME_LIMIT tcpdump -i $INTERFACE icmp $PACKET_LIMIT
            ;;
        7)
            choose_limit
			$TIME_LIMIT tcpdump -i $INTERFACE 'tcp[13] == 2' $PACKET_LIMIT
            ;;
        8)
            choose_limit
			read -p "Enter port number: " portnumber
            $TIME_LIMIT tcpdump -i $INTERFACE port $portnumber $PACKET_LIMIT
            ;;
        9)
            main
            ;;
        *)
            echo "Invalid option"
            sleep 2
            ;;
    esac
}

main_TCPDUMP() {
while true; do
    menuTCPDUMP
	INTERFACE=$(ip route | grep default | awk '{print $5}')
    read -p "Choose an option [0-9]: " TCPDUMP_In
    Do_tcpdump "$TCPDUMP_In"
    echo ""
    read -p "Press Enter to return to menu..."
done
}
########################################################################
###################          END of TCPDUMP      #######################
########################################################################

########################################################################
###################          Main function       #######################
########################################################################

show_menu() {
    clear
    echo "----- Main Menu -----"
    echo -e " 1 - System & Package Maintenance"
    echo -e " 2 - IPtables"
    echo -e " 3 - Traffic Capture"
    echo -e " 4 - EXIT"
    echo ""
    read -p "Enter your choice [1-4]: " choice
}

main() {
    check_root
    
    while true; do
        show_menu
        
        case $choice in
            1)	
				main_1
               
                ;;
            2)
                main_2
                ;;
            3)
                main_TCPDUMP
                ;;
            4)
                echo -e "Goodbye!"
                exit 0
                ;;
            *)
                echo -e "Invalid option. Please select 0-9."
                sleep 2
                ;;
        esac
    done
}
########################################################################
################          END of Main function         #################
########################################################################


# Run Script
main

