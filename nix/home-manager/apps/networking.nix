{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Networking
    conntrack-tools # Connection tracking userspace tools
    iperf # Tool to measure IP bandwidth using UDP or TCP
    iputils # arping, clockdif, ping, tracepath
    mtr # Network diagnostics tool
    netcat-gnu # Utility which reads and writes data across network
    nmap # Network exploration tool and security scanner
    omping # multicast ping
    # pietrasanta-traceroute # Traceroute utility
    tcpdump # Network packet analyzer
    termshark # Terminal UI for tshark
    # tshark # Network protocol analyzer
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
