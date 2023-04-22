#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import os
import re
import sys
from typing import Any
from typing import Callable
from typing import IO

from deploykit import DeployHost
from invoke import run


def color_text(code: int, file: IO[Any] = sys.stdout) -> Callable[[str], None]:
    def wrapper(text: str) -> None:
        if sys.stderr.isatty():
            print(f"\x1b[{code}m{text}\x1b[0m", file=file)
        else:
            print(text, file=file)

    return wrapper


warn = color_text(31, file=sys.stderr)
info = color_text(32)


##############################################################################
# Run
##############################################################################


def _init_nix_serve(host: DeployHost, hostname: str) -> None:
    # TODO: use domain from homelab.json file
    host.run(
        f"""
export DIR_NIXSERVE=/persist/host/data/nix-serve
mkdir -p $DIR_NIXSERVE && cd $DIR_NIXSERVE
nix-store --generate-binary-cache-key {hostname}.h cache-priv-key.pem cache-pub-key.pem
"""  # noqa: E501
    )


def generateCommandsList() -> str:
    res = run("inv -l", hide=True)
    commands = f"""```
{res.stdout}
```
"""

    return commands


##############################################################################
# Functions
##############################################################################


def generateHostsList() -> str:
    with open("homelab.json", "r") as f:
        jhl = json.load(f)
        hosts = jhl["hosts"]

    # Header table
    hosts_table = """<table>
    <tr>
        <th>Logo</th>
        <th>Name</th>
        <th>OS</th>
        <th>Description</th>
    </tr>"""

    # Hosts loop
    for hn in hosts:
        hosts_table += f"""<tr>
            <td><a href="./docs/hosts/{hn}.md"><img width="32" src="{hosts[hn]["icon"]}"></a></td>
            <td><a href="./docs/hosts/{hn}.md">{hn}</a>&nbsp;({hosts[hn]["ipv4"]})</td>
            <td>{hosts[hn]["os"]}</td>
            <td>{hosts[hn]["description"]}</td>
        </tr>"""  # noqa: E501

    hosts_table += "</table>"

    return hosts_table


def getUsedRolesList(hostname=None):
    filename = "homelab.json"
    allroles = {}
    with open(filename, "r") as fr:
        jinfo = json.load(fr)
        hostslist = jinfo["hosts"]

        for hn in hostslist:
            if hostname and hn != hostname:
                continue

            if "roles" in hostslist[hn]:
                for svc in hostslist[hn]["roles"]:
                    if svc not in allroles:
                        allroles[svc] = []
                    allroles[svc].append(hn)

    return allroles


def generateNetworkGraph():
    with open("homelab.json", "r") as f:
        jhl = json.load(f)
        hosts = jhl["hosts"]

    # Header table
    network_graph = """```mermaid
 graph BT
 linkStyle default interpolate basis
 internet((Internet))

 """

    # Hosts loop
    zones = {}
    for hn in hosts:
        if "zone" in hosts[hn]:
            zone = hosts[hn]["zone"]
            if zone not in zones:
                zones[zone] = []
            zones[zone].append(hn)

        network_graph += f"{hn}[<center>{hosts[hn]['description']}</br>{hosts[hn]['ipv4']}</center>]"  # noqa: E501

        if "parent" in hosts[hn]:
            network_graph += f"---{hosts[hn]['parent']}"

        network_graph += "\n"
    network_graph += "\n"

    for zn in zones:
        network_graph += f"subgraph {zn}\n"
        for zi in zones[zn]:
            network_graph += f"{zi}\n"
        network_graph += "end\n\n"

    network_graph += "```"
    return network_graph


def generateUsedRoles(rootpath, hostname=None) -> str:
    # Get hosts infos
    with open("homelab.json", "r") as fhl:
        jhl = json.load(fhl)
        roles = jhl["roles"]

    allroles = getUsedRolesList(hostname)

    if not allroles:
        return ""

    roles_table = """<table>
    <tr>
        <th>Logo</th>
        <th>Module</th>
        <th>Hosts</th>
        <th>Description</th>
    </tr>"""

    for mname in allroles:
        hosts_list = []
        for h in allroles[mname]:
            hosts_list.append(h)

        filename = f"docs/{mname}.md"
        if os.path.exists(filename):
            roles_table += f"""<tr>
            <td><a href="{rootpath}/{mname}.md"><img width="32" src="{roles[mname]["icon"]}"></a></td>
            <td><a href="{rootpath}/{mname}.md">{mname}</a></td>
            """  # noqa: E501
        else:
            roles_table += f"""<tr>
            <td><img width="32" src="{roles[mname]["icon"]}"></td>
            <td>{mname}</td>
            """

        roles_table += f"""<td>{", ".join(hosts_list)}</td>
        <td>{roles[mname]['description']}</td>
        """

    roles_table += "</table>"

    return roles_table


# Replace the content marker
def _replace_content(content: str, marker: str, newcontent) -> str:
    newcontent = f"""[comment]: (>>{marker})

{newcontent}

[comment]: (<<{marker})"""

    result = re.sub(
        rf"\[comment\]: \(\>\>{marker}\).*\[comment\]\: \(\<\<{marker}\)",
        newcontent,
        content,
        flags=re.DOTALL | re.M,
    )

    return result


# Update the main README.md project page
def _doc_update_main_project_page() -> None:
    # Read readme.md content
    with open("README.md", "r") as fr:
        content = fr.read().rstrip()

    # Get generated contents
    hosts_table = generateHostsList()
    roles_table = generateUsedRoles(rootpath="./docs")
    network_graph = generateNetworkGraph()
    commands = generateCommandsList()

    # Replace content
    newcontent = _replace_content(content, "HOSTS", hosts_table)
    newcontent = _replace_content(content, "NETWORK", network_graph)
    newcontent = _replace_content(newcontent, "ROLES", roles_table)
    newcontent = _replace_content(newcontent, "COMMANDS", commands)

    # Write new content
    with open("README.md", "w") as fw:
        fw.write(newcontent)
