# Digital Wellbeing Site Blocker

A simple but powerful command-line tool for temporarily blocking distracting websites to help you focus on work.

**WORKS ONLY ON BASH BASED SYSTEMS WITH ROOT ACCESS**.

## Overview

This script helps you temporarily block distracting websites by modifying your hosts file, making these sites unreachable for a specified duration. Once the timer ends, the sites are automatically unblocked. Perfect for focused work sessions, studying, or breaking unhealthy browsing habits.

## Features

- **Flexible Timing Options**: Block sites until a specific time or for a set number of minutes
- **Interactive Timer Mode**: Enter duration on the fly
- **Progress Display**: Visual progress bar shows remaining time
- **Interrupt Handling**: Safely unblocks sites if canceled with Ctrl+C
- **Cross-Platform**: Works on both Linux and macOS
- **Custom Site Lists**: Easily configure which sites to block

## Installation

1. Clone or download this repository
2. Make the script executable:
   ```bash
   chmod +x block_until.sh
   ```
3. Create your blocklist file:
   ```bash
   mkdir -p ~/.digital_wellbeing
   echo "reddit.com" > ~/.digital_wellbeing/blocked_sites.txt
   echo "twitter.com" >> ~/.digital_wellbeing/blocked_sites.txt
   # Add more sites as needed
   ```

## Usage

### Block until a specific time

```bash
./block_until.sh 17:30
```
This blocks sites until 5:30 PM today (or tomorrow if it's already past 5:30 PM).

### Block for a specific duration

```bash
./block_until.sh 45
```
This blocks sites for 45 minutes.

### Interactive timer mode

```bash
./block_until.sh
```
When run without arguments, the script will prompt you to enter the number of minutes to block sites.

### Custom site list

```bash
./block_until.sh 30 /path/to/my/custom_blocklist.txt
```
This uses a custom blocklist instead of the default one.

## Customization

### Default blocklist

The default blocklist is located at `~/.digital_wellbeing/blocked_sites.txt`. Add one domain per line:

```
facebook.com
twitter.com
instagram.com
reddit.com
youtube.com
# Add comments with #
```

Blank lines and comments (lines starting with #) are ignored.

## Requirements

- Bash shell
- Administrative privileges (sudo) to modify the hosts file
- Standard Unix utilities (sed, grep)

## How It Works

The script works by adding entries to your system's hosts file that redirect requests for specific domains to your local machine (127.0.0.1), effectively making those sites unreachable. When the timer expires or if you interrupt the script with Ctrl+C, it safely removes these entries, restoring normal access.

## Tips

- Run this script before starting a focused work session
- Use a pomodoro-style approach: `./block_until.sh 25` for 25-minute focus sessions
- Create aliases in your `.bashrc` or `.zshrc` for quick access:
  ```
  alias focus30="~/path/to/block_until.sh 30"
  alias focusuntil="~/path/to/block_until.sh"
  ```

## License

MIT License

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.