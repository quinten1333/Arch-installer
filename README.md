# An arch install system with an over engineered server
This arch install system will install arch linux with:
- fat16 as boot parition
- ext4 as root partition
- Download all packages supplied in the config
- Install fstab
- Set the hostname
- Install grub
- Create a user
- Add the user to the groups specified in the config
- Disallow password authentication for SSH connections
- Allow users of the `wheel` group to call sudo
- Enable all services supplied in the config

## Running the installer:
On the host:
```
python serve.py <path_to_config>
```

On the new server:
```
curl http://<ip>:<port>/dl.sh | sh
./install.sh
```
