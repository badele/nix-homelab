from diagrams import Cluster
from diagrams import Diagram
from diagrams.custom import Custom
from diagrams.generic.device import Mobile
from diagrams.generic.network import Firewall
from diagrams.generic.network import Router
from diagrams.generic.network import Subnet
from diagrams.generic.network import Switch
from diagrams.onprem.dns import Coredns
from diagrams.onprem.logging import Loki
from diagrams.onprem.monitoring import Grafana
from diagrams.onprem.monitoring import Prometheus
from diagrams.onprem.network import Internet

# onprem

with Diagram("Network Architecture", show=False):
    # Subnet
    # netpriv = Subnet("subnet\private")
    # netdmz = Subnet("subnet\DMZ")
    # netvpn = Subnet("subnet\VPN")

    # Box
    internet = Internet("internet\n81.64.x.x")
    wireless1 = Subnet("work\nwireless")
    wireless2 = Subnet("home\nwireless")
    phones = Mobile("phones")
    laptops = Custom("laptops", "./icons/laptop.png")

    # bootstore = Custom("bootstore", "./icons/computer.png")

    with Cluster("living room"):
        mikro254 = Router("micro254\n192.168.254.254")
        box = Firewall("box\n192.168.0.x")
        boxtv = Custom("boxtv", "./icons/tv.png")

    with Cluster("lad room"):
        mikro253 = Router("micro253\n192.168.254.253")
        hue = Custom("hue\n192.168.0.3", "./icons/philipshue.png")
        ladpc = Custom("ladpc", "./icons/computer.png")

    with Cluster("services"):
        coredns = Coredns("dns")
        grafana = Grafana("grafana")
        prometheus = Prometheus("prometheus")
        loki = Loki("loki")

    with Cluster("work room"):
        mikro252 = Switch("mikro252\n192.168.254.252")
        servers = Custom("servers", "./icons/computer.png")
        rpi40 = Custom("rpi40", "./icons/raspberrypi.png")
        b4d14 = Custom("b4d14", "./icons/laptop.png")

        mikro252 - [servers, rpi40, b4d14]
        servers - [coredns, grafana, loki, prometheus]

    # Flow
    (internet - box - mikro254 - mikro253 - mikro252)

    (box - boxtv)

    (mikro254 - wireless1)

    # (wireless1 >> b4d14)

    (mikro253 - [hue, wireless2])

    (wireless2 - [phones, laptops])
