# Dockerized Kiosk Tor Browser

A lightweight, fully isolated Tor Browser running in a Docker container, accessible via any web browser.

This build strips out heavy desktop environments in favor of a specialized "kiosk" window manager. It dynamically scales to fit your browser window, creating a seamless, native-feeling application experience.

## Features
* **Auto-Scaling (noVNC + Matchbox):** The internal desktop automatically resizes to match your host browser window dimensions on the fly.
* **Always Updated:** The Dockerfile programmatically scrapes the Tor Project to download the latest available Linux release on build.
* **Fullscreen Experience:** Auto-disables Tor's default "letterboxing" privacy feature to ensure the browser utilizes 100% of your screen space.
* **Passwordless Local Access:** Bypasses basic authentication for frictionless access on trusted local networks.

## Setup & Installation

1. Clone this repository and navigate to the directory.
2. Build and start the container:
   ```bash
   docker compose up -d --build

```
3. Open your web browser and navigate to:
   `http://localhost:5800` *(Replace `localhost` with your server's IP if accessing remotely).*

## Security Notice: The Firefox Sandbox Warning

When opening the Tor Browser, you may notice a warning stating: *"Some of Tor Browser's security features may offer less protection on your current operating system."*

**This is expected behavior.**

Tor (built on Firefox) attempts to use Linux kernel features (`clone` and `unshare`) to build a security sandbox around web pages. However, Docker's default security profile (`seccomp`) actively blocks these system calls to maintain strong container isolation.

We have explicitly disabled the browser's internal sandbox using `MOZ_DISABLE_CONTENT_SANDBOX=1` in the `docker-compose.yml`.

**Why we do this:**
* **Defense in Depth:** The browser is already running as a non-root user (`toruser`) inside an isolated Docker container.
* **The Trade-off:** To make the browser's internal sandbox work, we would have to run the container with `security_opt: seccomp=unconfined`, exposing the host's kernel to over 40 dangerous system calls.
* **Conclusion:** We prioritize Docker's robust container isolation over the browser's internal sandboxing. The container itself acts as the sandbox.
