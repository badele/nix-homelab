#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from invoke import run
from deploykit import DeployHost, DeployGroup

import os
import sys
import json
import re
from typing import IO, Any, Callable, List, Dict, Optional, Text


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
    host.run(f"""
export DIR_NIXSERVE=/persist/host/data/nix-serve
mkdir -p $DIR_NIXSERVE && cd $DIR_NIXSERVE  
nix-store --generate-binary-cache-key {hostname}.h cache-priv-key.pem cache-pub-key.pem
""")


def generateCommandsList() -> str:
    res = run(f"inv -l",hide=True)
    commands = f'''```
{res.stdout}
```
'''

    return commands


##############################################################################
# Functions
##############################################################################


def generateHostsList() -> str:
    with open('homelab.json', 'r') as f:
        jhl = json.load(f)
        hosts = jhl['hosts']

    # Header table
    hosts_table = '''<table>
    <tr>
        <th>Logo</th>
        <th>Name</th>
        <th>Arch</th>
        <th>OS</th>
        <th>CPU</th>
        <th>Memory</th>
        <th>Disk</th>
        <th>Description</th>
    </tr>'''

    # Hosts loop
    for hn in hosts:
        summariespath = f'docs/hosts/{hn}/summaries.json'
        if os.path.exists(summariespath):
            with open(summariespath, 'r') as fs:
                sinfo = json.load(fs)

        cpuarch = "" 
        if "cpu" in sinfo and "arch" in sinfo["cpu"]:
            cpuarch =  sinfo["cpu"]["arch"]
        cpunb = ""
        if "cpu" in sinfo and "nb" in sinfo["cpu"]:
            cpunb =  sinfo["cpu"]["nb"]

        smemory = sinfo['memory'] if "memory" in sinfo else ''
        sdisk = sinfo['disk'] if "disk" in sinfo else ''
        sdescription = sinfo['description'] if "description" in sinfo else ''

        hosts_table += f'''<tr>
            <td><a href="./docs/hosts/{hn}.md"><img width="32" src="{hosts[hn]["icon"]}"></a></td>
            <td><a href="./docs/hosts/{hn}.md">{hn}</a>&nbsp;({hosts[hn]["ipv4"]})</td>
            <td>{cpuarch}</td>
            <td>{hosts[hn]["os"]}</td>
            <td>{cpunb}</td>
            <td>{smemory}</td>
            <td>{sdisk}</td>
            <td>{hosts[hn]["description"]}</td>
        </tr>'''

    hosts_table += "</table>"

    return hosts_table


def getUsedRolesList():
    filename = f'homelab.json'
    allroles = {}
    with open(filename, 'r') as fr:
        jinfo = json.load(fr)
        hostslist = jinfo['hosts']

        for hn in hostslist:
            if 'roles' in hostslist[hn]:
                for svc in hostslist[hn]['roles']:
                    if svc not in allroles:
                        allroles[svc] = []
                    allroles[svc].append(hn)

    return allroles


def generateUsedRoles() -> str:
    # Get hosts infos
    with open('homelab.json', 'r') as fhl:
        jhl = json.load(fhl)
        roles = jhl['roles']

    allroles = getUsedRolesList()

    roles_table = '''<table>
    <tr>
        <th>Logo</th>
        <th>Module</th>
        <th>Hosts</th>
        <th>Description</th>
    </tr>'''

    for mname in allroles:
        hosts_list = []
        for h in allroles[mname]:
            hosts_list.append(h)

        filename=f'./docs/{mname}.md'
        if os.path.exists(filename):
            roles_table += f'''<tr>
            <td><a href="./docs/{mname}.md"><img width="32" src="{roles[mname]["icon"]}"></a></td>
            <td><a href="./docs/{mname}.md">{mname}</a></td>
            '''
        else:
            roles_table += f'''<tr>
            <td><img width="32" src="{roles[mname]["icon"]}"></td>
            <td>{mname}</td>
            '''

        roles_table += f'''<td>{", ".join(hosts_list)}</td>
        <td>{roles[mname]['description']}</td>
        '''

    roles_table += "</table>"

    return roles_table

# Replace the content marker
def _replace_content(content: str, marker: str, newcontent) -> str:
    newcontent = f'''[comment]: (>>{marker})

{newcontent}

[comment]: (<<{marker})'''

    result = re.sub(rf'\[comment\]: \(\>\>{marker}\).*\[comment\]\: \(\<\<{marker}\)',newcontent, content,  flags=re.DOTALL | re.M)
    
    return result


# Update the main README.md project page
def _doc_update_main_project_page() -> None:

    # Read readme.md content
    with open('README.md', 'r') as fr:
        content = fr.read().rstrip()

    # Get generated contents
    hosts_table = generateHostsList() 
    roles_table = generateUsedRoles()
    commands = generateCommandsList()

    # Replace content
    newcontent = _replace_content(content,"HOSTS",hosts_table)
    newcontent = _replace_content(newcontent,"ROLES",roles_table)
    newcontent = _replace_content(newcontent,"COMMANDS",commands)

    # Write new content
    with open('README.md', 'w') as fw:
        fw.write(newcontent)
