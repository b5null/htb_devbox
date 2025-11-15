# HTB DevBox Generator (`gendev.sh`)

A helper script to automatically **spawn a retired Windows VM on Hack The Box**, optimized for **development, debugging, and tool testing**.

The script uses **Puppy** as the default devbox VM and leverages **htbcli** (https://github.com/thekeen01/htbcli) for interaction with the HTB platform.  
Once the VM is created, it automatically:

- Enables **RDP**
- Maps the **current working directory** as a `TSClient` share
- Connects via RDP automatically  
- (Optional) Stops or starts a specific VM depending on your choices

---

## Requirements

- A Hack The Box subscription that allows generating **retired machines**  
- A valid `HTB_API_TOKEN` generated at - https://app.hackthebox.com/profile/settings
- xfreerdp

---

## Usage

```bash
git clone https://github.com/your/repo.git
cd htb_devbox
chmod +x gendev.sh
```
