to_entries as $entries |
{
  all: {
    vars: {ansible_user: "ubuntu"},
    children: {
      rke2_servers: {
        hosts: (reduce ($entries[] | select(.key == "lab-server")) as $entry ({};
          .[$entry.key] = {ansible_host: ($entry.value | split("/")[0])}
        ))
      },
      rke2_workers: {
        hosts: (reduce ($entries[] | select(.key != "lab-server")) as $entry ({};
          .[$entry.key] = {ansible_host: ($entry.value | split("/")[0])}
        ))
      }
    }
  }
}
