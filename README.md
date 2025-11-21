# Bitwarden Environment Manager

A simple bash script to load environment variables from Bitwarden secure notes.

## Prerequisites

- [Bitwarden CLI](https://bitwarden.com/help/cli/) installed
- [jq](https://jqlang.org/) for JSON parsing

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd secretManager
```

2. Make the script executable:
```bash
chmod +x bw-env.sh
```

## Usage

1. Create a secure note in Bitwarden with your environment variables in `KEY=VALUE` format (one per line):
```
DB_HOST=localhost
DB_USER=admin
API_KEY=your-secret-key
```

2. Load the variables into your current terminal session:
```bash
source bw-env.sh <note-name>
```

3. The script will:
   - Unlock your Bitwarden vault (if needed)
   - Search for the specified note
   - Export all variables to your current session

## Example

```bash
source bw-env.sh "Production Secrets"
```

The variables will remain available in your terminal until you close it or manually unset them.

## Unloading Variables

To remove all loaded variables:
```bash
unset $(compgen -v | grep -E '^[A-Z_]+$')
```
