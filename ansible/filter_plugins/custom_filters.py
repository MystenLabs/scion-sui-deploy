#!/usr/bin/env python3
import yaml
from typing import Union


class FilterModule:
    """Module of custom ansible filters for the playbook"""

    def filters(self):
        """Return the list of filters supported by this module"""
        return {
            "select_vfs_from_stat_result": select_vfs_from_stat_result,
            "customize_cloud_config": customize_cloud_config,
            "scion_ia_to_tag": scion_ia_to_tag,
            "parse_ssh_key": parse_ssh_key,
            "format_edge_key": format_edge_key,
            "flatten_cidr_ranges": flatten_cidr_ranges,
        }

def scion_ia_to_tag(
    isd_as: str, sep: str = "_", isd_prefix="isd", asn_prefix="as"
) -> str:
    """Convert a SCION ISD-AS number to the format isd<isd>_as<asn>

    Colons are replaced with underscores in the AS number. The ISD and
    AS parts are separated with sep.
    """
    (isd, asn) = isd_as.split("-")
    asn = asn.replace(":", "_")

    return f"{isd_prefix}{isd}{sep}{asn_prefix}{asn}"


def select_vfs_from_stat_result(stat_results: list[dict], parent_pci: str) -> list[str]:
    """Selects VFs from the list with the specified parent.

    Return the names of virtual function interfaces in stat_result that
    have parent_pci as their physical function.
    """
    assert isinstance(stat_results, list), "`state_results` were not provided as a list"
    return [
        result["item"]
        for result in stat_results
        if result["stat"]["exists"]
        and result["stat"]["lnk_target"].endswith("/" + parent_pci)
    ]


def customize_cloud_config(config: str, ssh_authorized_keys: list[str]) -> str:
    """Customize the cloud config from the Anapaya EDGE appliance.

    This modifies the config by
    - injects the provided ssh_authorized_keys,
    - disables ssh password authentication,
    - allows passwordless sudo for the anapaya user
    - locks the anapaya user's password and removes the need to change passwords, and
    - touching the file /home/anapaya/.setup_complete once setup has completed,
    """
    assert ssh_authorized_keys, "requires at least 1 SSH authorized key"

    parsed_config = yaml.safe_load(config)
    none_datasource = parsed_config["datasource"]["None"]

    userdata = yaml.safe_load(none_datasource["userdata_raw"])

    anapaya_user = next(
        (user for user in userdata["users"] if user["name"] == "anapaya"), None
    )
    assert anapaya_user is not None, "expected the 'anapaya' user in the cloud config"

    anapaya_user["ssh_authorized_keys"] = ssh_authorized_keys
    anapaya_user["lock_passwd"] = False
    anapaya_user["sudo"] = "ALL=(ALL) NOPASSWD:ALL"

    userdata["runcmd"].append("touch /home/anapaya/.setup_complete")
    userdata["ssh_pwauth"] = False
    del userdata["chpasswd"]

    none_datasource["userdata_raw"] = "#cloud-config\n" + yaml.dump(userdata)
    return yaml.dump(parsed_config)

# scion edge appliances want ssh keys in a specific format
# this function strps away the leading algo and trailing email if present
def parse_ssh_key(ssh_key_string):
    parts = ssh_key_string.split()
    if len(parts) >= 2:
        return {
            'key': parts[1],
            'name': parts[2] if len(parts) > 2 else "key"
        }
    return None  # or raise an error if you prefer

def format_edge_key(ssh_key):
    parts = ssh_key.split()
    if len(parts) > 1:
        return parts[1]
    return ssh_key

def flatten_cidr_ranges(data: list[dict[str, list[str]]], additional_allowed_ips: list[str]) -> list[str]:
    """Extract and flatten CIDR ranges from the YAML structure.
    
    Args:
        data: List of dictionaries containing isd_as and cidr_ranges
        
    Returns:
        List of CIDR ranges extracted from all entries
        
    Example:
        Input YAML structure:
        - isd_as: 66-2:0:5b
          cidr_ranges:
            - 45.250.255.101/32
        - isd_as: 65-2:0:58
          cidr_ranges:
            - 103.50.32.105/32
            
        Returns: [45.250.255.101/32, 103.50.32.105/32]
    """
    result = []
    for entry in data:
        if 'cidr_ranges' in entry:
            result.extend(entry['cidr_ranges'])

    if additional_allowed_ips:
        result.extend([str(cidr).strip("'\"") for cidr in additional_allowed_ips])
    return result
