# Cloudflare MCP Setup for Antigravity

This guide helps you configure the Cloudflare MCP server to allow Antigravity (the AI) to manage your Cloudflare resources (DNS, Caching, Firewall, Zones, etc.).

## 1. Prerequisites

- **Node.js & npm**: Ensure you have Node.js installed.
- **Cloudflare API Token**:
    1. Go to the [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens).
    2. Click **Create Token**.
    3. Use the **Edit Zone DNS** template or create a custom token with the following permissions:
        - `Zone.Zone`: Read/Edit
        - `Zone.DNS`: Read/Edit
        - `Zone.Cache Purge`: Edit
        - `Zone.Firewall Services`: Read/Edit
    4. Copy the generated token.

## 2. Configuration

We are using the `@ironclads/cloudflare-mcp` package, which provides extensive management capabilities.

### Option A: VS Code (with MCP Extension)

1. Open your VS Code `settings.json` or the specific MCP extension configuration.
2. Add the `cloudflare` server definition from the generated `cloudflare_mcp_config.json` file.
3. Replace `"YOUR_API_TOKEN_HERE"` with your actual Cloudflare API Token.
4. Replace `"your-email@example.com"` with your Cloudflare email (if required by the specific operations, usually Token is sufficient but Email is good for some auth methods).

### Option B: Claude Desktop (claude_desktop_config.json)

1. Locate your configuration file:
    - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
    - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
    - **Linux**: `~/.config/Claude/claude_desktop_config.json`
2. Open the file and add the `cloudflare` entry to the `mcpServers` object.
    ```json
    {
      "mcpServers": {
        "cloudflare": {
          "command": "npx",
          "args": ["-y", "@ironclads/cloudflare-mcp"],
          "env": {
            "CLOUDFLARE_API_TOKEN": "your_token_here",
            "CLOUDFLARE_EMAIL": "your_email_here"
          }
        }
      }
    }
    ```
3. Restart the application.

## 3. Capabilities

Once configured, Antigravity will be able to:
- **Manage DNS**: List, create, update, and delete DNS records.
- **Manage Caching**: Purge cache for your zones.
- **Manage Firewall**: View and update firewall rules.
- **Manage Zones**: List and configure your domains.

## Troubleshooting

- If the server fails to start, ensure `npx` is in your system PATH.
- If you see "Permission Denied" errors, check your API Token permissions in the Cloudflare Dashboard.
