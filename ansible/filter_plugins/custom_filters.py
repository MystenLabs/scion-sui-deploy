#!/usr/bin/env python3
import yaml


class FilterModule:
    """Module of custom ansible filters for the playbook"""

    def filters(self):
        """Return the list of filters supported by this module"""
        return {
            "select_vfs_from_stat_result": select_vfs_from_stat_result,
            "customize_cloud_config": customize_cloud_config,
        }


def select_vfs_from_stat_result(stat_results: list[dict], parent_pci: str) -> list[str]:
    """Selects VFs from the list with the specified parent.

    Return the names of virtual function interfaces in stat_result that
    have parent_pci as their physical function.
    """
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
    anapaya_user["lock_passwd"] = True
    anapaya_user["sudo"] = "ALL=(ALL) NOPASSWD:ALL"
    del anapaya_user["plain_text_passwd"]

    userdata["runcmd"].append("touch /home/anapaya/.setup_complete")
    userdata["ssh_pwauth"] = False
    del userdata["chpasswd"]

    none_datasource["userdata_raw"] = "#cloud-config\n" + yaml.dump(userdata)
    return yaml.dump(parsed_config)
