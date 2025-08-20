Prompt: list all disks in my device
List all mounted disks and their usage:
```bash
echo disks:
df -h
```

List all disks including unmounted:
```bash
lsblk
```

Display disk partitions with detailed information:
```bash
fdisk -l
```

Show disk information with identification details:
```bash
blkid
```
