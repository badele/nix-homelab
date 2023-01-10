#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from invoke import run
from deploykit import DeployHost, DeployGroup

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


def _cert_init_cert_domain() -> None:
    # openssl_3_0.bin
    # openssl req -new -newkey rsa:4096 -days 36500 -nodes -x509 -keyout server.key -out server.crt -subj "/CN=h"
    with open('homelab.json', 'r') as fr:
        jinfo = json.load(fr)
        domain = jinfo['domain']

    res = run(f"openssl req -new -newkey rsa:4096 -days 36500 -nodes -x509 -keyout /tmp/wildcard-domain.key.pem -out hosts/wildcard-domain.crt.pem -subj '/CN=*.{domain}'")
    res = run(f"cat /tmp/wildcard-domain.key.pem",hide=True)

    indent = "  "
    indented = indent + res.stdout.replace('\n', '\n' + indent)

    info(f"""
Please add this content to hosts/secrets.yml

wildcard-domain.key.pem: |
{indented}
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
        with open(f'docs/hosts/{hn}/summaries.json', 'r') as fs:
            sinfo = json.load(fs)

            hosts_table += f'''<tr>
        <td><a href="./docs/hosts/{hn}.md"><img width="32" src="{hosts[hn]["icon"]}"></a></td>
        <td><a href="./docs/hosts/{hn}.md">{hn}</a>&nbsp;({hosts[hn]["ipv4"]})</td>
        <td>{sinfo["cpu"]["arch"]}</td>
        <td>{hosts[hn]["os"]}</td>
        <td>{sinfo["cpu"]["nb"]}</td>
        <td>{sinfo["memory"]}</td>
        <td>{sinfo["disk"]}</td>
        <td>{hosts[hn]["description"]}</td>
    </tr>'''

    hosts_table += "</table>"

    return hosts_table


def getUsedModulesList():
    filename = f'homelab.json'
    allmodules = {}
    with open(filename, 'r') as fr:
        jinfo = json.load(fr)
        hostslist = jinfo['hosts']

        for hn in hostslist:
            if 'modules' in hostslist[hn]:
                for svc in hostslist[hn]['modules']:
                    if svc not in allmodules:
                        allmodules[svc] = []
                    allmodules[svc].append(hn)

    return allmodules


def generateUsedModules() -> str:
    # Get hosts infos
    with open('homelab.json', 'r') as fhl:
        jhl = json.load(fhl)
        modules = jhl['modules']

    allmodules = getUsedModulesList()

    modules_table = '''<table>
    <tr>
        <th>Logo</th>
        <th>Module</th>
        <th>Hosts</th>
        <th>Description</th>
    </tr>'''

    for mname in allmodules:
        hosts_list = []
        for h in allmodules[mname]:
            hosts_list.append(h)

        modules_table += f'''<tr>
        <td><a href="./docs/{mname}.md"><img width="32" src="{modules[mname]["icon"]}"></a></td>
        <td><a href="./docs/{mname}.md">{mname}</a></td>
        <td>{", ".join(hosts_list)}</td>
        <td>{modules[mname]['description']}</td>
        '''

    modules_table += "</table>"

    return modules_table

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
    modules_table = generateUsedModules()
    commands = generateCommandsList()

    # Replace content
    newcontent = _replace_content(content,"HOSTS",hosts_table)
    newcontent = _replace_content(newcontent,"MODULES",modules_table)
    newcontent = _replace_content(newcontent,"COMMANDS",commands)

    # Write new content
    with open('README.md', 'w') as fw:
        fw.write(newcontent)
