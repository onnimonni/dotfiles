# To use Estonian ID-card for ssh public key authentication

To find the public key you need to run following commands:
```bash
# Ensure that you have new enough opensc installed so that it can read the EstEID 2025:
$ opensc-tool -D | grep esteid
  esteid2018       EstEID 2018
  esteid2025       EstEID 2025

# Swap the card into reader and list all cards
$ pkcs15-tool --list-keys --list-public-keys

# If the card is in slot 01
$ pkcs15-tool --read-ssh-key 01
Using reader with a card: ACS ACR39U ICC Reader
ecdsa-sha2-nistp384 AAAA ... == Isikutuvastus
```

Then copy paste the public key into your Github:
https://github.com/settings/ssh/new

Sources:
* https://techblog.dac.digital/using-estonian-e-residency-card-for-ssh-authentication-f812eda4ce86