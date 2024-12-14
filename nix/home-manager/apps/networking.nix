{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Tools
    ipcalc # IP subnetcalculator

    # Networking
    # [conflit] pietrasanta-traceroute # Traceroute utility
    # [conflit] tshark # Network protocol analyzer
    conntrack-tools # Connection tracking userspace tools
    iperf # Tool to measure IP bandwidth using UDP or TCP
    iputils # arping, clockdif, ping, tracepath
    mtr # Network diagnostics tool
    netcat-gnu # Utility which reads and writes data across network
    nmap # Network exploration tool and security scanner
    omping # multicast ping
    tcpdump # Network packet analyzer
    termshark # Terminal UI for tshark
    trippy # mtr traceroute alternative
    wireshark # Network protocol analyzer

    # Proxy
    mitmproxy # Intercept HTTP traffic
    charles # Web debugging proxy application
    requestly # mockup and API tool

    # Security
    burpsuite # Web vulnerability scanner
    nikto # Web server scanner
  ];
}
