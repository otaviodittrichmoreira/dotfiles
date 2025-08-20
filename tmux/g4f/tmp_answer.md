Check free disk space in human-readable format:
```bash
df -h
```

Display free space on the root filesystem:
```bash
df / --output=avail,human
```

Get the total, used, and available space for all file systems:
```bash
df -T
```