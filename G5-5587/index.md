# Toubleshooting graphics issues

The laptop I'm using for this is a Dell G5 5587 gaming laptop which includes both on-chip Intel graphics as well as a dedicated nVidia graphics card.

It is plugged into two external monitors. One via the HDMI port and one via a USB3 docking station that uses the DisplayLink driver.

I use Fedora Workstation on this machine as a daily driver. At the time I started having issues I was on Fedora 32, then upgraded (clean install) to Fedora 33 but had the same issues.

## Kernel 5.11 issues
Around late March 2021 I started to have issues booting Fedora after a recent round of updates.

It appeared as though it just hung on boot - the screen would freeze and nothing would happen.

Pushing the Esc key while booting removes the splash screen and shows you text output for the boot process.

Here I saw that it was hitting a kernel panic and crashing.

When I chose the previous kernel version 5.10.x at GRUB, I didn't have the problem.

