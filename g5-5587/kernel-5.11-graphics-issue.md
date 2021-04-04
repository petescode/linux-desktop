# Kernel 5.11 graphics issues

## My setup
The laptop I'm using for this is a Dell G5 5587 gaming laptop which includes both on-chip Intel graphics as well as a dedicated nVidia graphics card.

It is plugged into two external monitors. One via the HDMI port and one via a USB3 docking station that uses the DisplayLink driver.

I use Fedora Workstation on this machine as a daily driver. At the time I started having issues I was on Fedora 32, then upgraded (clean install) to Fedora 33 but had the same issues.

## Symptoms
Around late March 2021 I started to have issues booting Fedora 32 after a recent round of updates.

It appeared as though it just hung on boot - the screen would freeze and nothing would happen.

Pushing the Esc key while booting removes the splash screen and shows you text output for the boot process.

Here I saw that it was hitting a kernel panic and crashing.

When I chose the previous kernel version 5.10.x at GRUB, I didn't have the problem.

So at this point, Fedora 34 is only a few weeks away and I needed to upgrade from Fedora 32 anyway. I went ahead and just did a clean install of Fedora 33.

But the same problem persisted. In fact it was slightly worse now. The default kernel for Fedora 33, kernel 5.8, was also broken.

After pulling updates I now have kernel 5.8 and 5.11, this time on Fedora 33.

Booting into 5.8 works but loads a graphics driver called "NV136/MESA Intel UHD Graphics 630 (CFL GT2)", which causes issues with the external monitor.

You can see this by going to Settings --> About in GNOME.

With an external monitor the experience is terrible. It takes several seconds after clicking to get a reaction from GNOME. Sometimes clicks are just missed altogether. It is unusable.

Disconnecting the external monitor from the HDMI port and just using the laptop display works fine, but that is not acceptable for my desktop.

For what it's worth I installed Fedora 33 with the latest kernel, version 5.11.11 onto an older Dell Latitude E5430 laptop that only had the integrated Intel graphics chip. This worked fine with an external monitor. In Settings --> About the driver shows up as "Intel HD Graphics 4000 (IVB GT2)"

## Known issues
After doing some googling, I've found that there were significant changes in kernel 5.11 to graphics drivers.
There's also a plethora of issue complaints about graphics problem with 5.11, although most of them are coming from AMD users.

## Temporary fix
Since I know everything worked with kernel 5.10, I can just go back to that for the time being.

Normally if you had this issue you would just select the old kernel version from the GRUB menu on boot.

However since I did a fresh install of Fedora 33, I now only have what it originally shipped with, kernel 5.8, and the latest kernel, 5.11 (the broken one).

So now I need to manually install the latest version of 5.10 and then put a freeze on kernel updates.

This is not as straight forward as you would think - you can't simply find and grab it from the repos.

I'll use koji to download a specific older kernel version that I need.

```markdown
cd ~/Downloads
sudo dnf install koji -y
```

Go to the koji website: https://koji.fedoraproject.org/koji/packages

Search for "kernel" packages

Use Ctrl+F to find the latest 5.10 package. In my case it is "kernel-5.10.23-200.fc33"

Note: be sure to select the correct Fedora version. There are currently versions that end in ".fc32" and ".fc33"

Use koji to download:
```markdown
koji download-build --arch=x86_64 kernel-5.10.23-200.fc33
```

This will download several .rpm packages.

Install them all with dnf
```markdown
sudo dnf install kernel*
```

Now when I reboot I see the 5.10 kernel in the GRUB menu, and can boot into it successfully.

When checking the graphics driver in Settings --> About, I now see "GeForce GTX 1060 with Max-Q Design"

My external monitor works as expected again.

Now I need to put an update freeze on the kernel. This will only be a temporary solution until a fix has been made for kernel 5.11 or 5.12, etc. There's a couple of ways to do this but I will use versionlock.
```markdown
sudo dnf install python3-dnf-plugin-versionlock
sudo dnf versionlock add kernel-*
```
You'll see several kernel packages get locked, such as -core, -devel, -modules, etc. This is what you want.
