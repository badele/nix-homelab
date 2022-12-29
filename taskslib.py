#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from invoke import run

import json
import re


def generateCommandsList() -> str:
    res = run(f"inv -l",hide=True)
    commands = f'''```
{res.stdout}
```
'''

    return commands


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


def getUsedServicesList():
    filename = f'homelab.json'
    allservices = {}
    with open(filename, 'r') as fr:
        jinfo = json.load(fr)
        hostslist = jinfo['hosts']

        for hn in hostslist:
            if 'services' in hostslist[hn]:
                for svc in hostslist[hn]['services']:
                    if svc not in allservices:
                        allservices[svc] = []
                    allservices[svc].append(hn)

    return allservices


def generateUsedServices() -> str:
    # Get hosts infos
    with open('homelab.json', 'r') as fhl:
        jhl = json.load(fhl)
        services = jhl['services']

    # # Get used services list
    # with open('docs/hosts/services.json', 'r') as fsvc:
    #     susvc = json.load(fsvc)

    allservices = getUsedServicesList()

    services_table = '''<table>
    <tr>
        <th>Logo</th>
        <th>Service</th>
        <th>Hosts</th>
        <th>Description</th>
    </tr>'''

    for sname in allservices:
        hosts_list = []
        for h in allservices[sname]:
            hosts_list.append(h)

        services_table += f'''<tr>
        <td><a href="./docs/{sname}.md"><img width="32" src="{services[sname]["icon"]}"></a></td>
        <td><a href="./docs/{sname}.md">{sname}</a></td>
        <td>{", ".join(hosts_list)}</td>
        <td>{services[sname]['description']}</td>
        '''

    services_table += "</table>"

    return services_table

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
    services_table = generateUsedServices()
    commands = generateCommandsList()

    # Replace content
    newcontent = _replace_content(content,"HOSTS",hosts_table)
    newcontent = _replace_content(newcontent,"SERVICES",services_table)
    newcontent = _replace_content(newcontent,"COMMANDS",commands)

    # Write new content
    with open('README.md', 'w') as fw:
        fw.write(newcontent)
