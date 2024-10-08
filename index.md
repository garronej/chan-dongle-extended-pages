---
title: chan-dongle-extended
---

[GitHub repo](https://github.com/garronej/chan-dongle-extended)

## Motivations

``asterisk-chan-dongle`` let you use Huawei 3G dongles to place phone calls  
via ``Asterisk``, unfortunately it handle SMS very poorly, it is complicated to   
setup and it is quite unstable.

This project aim to automate the compilation/installation/configuration  
of ``asterisk-chan-dongle`` alongside fixing bugs and providing many new features.

## Features: 

* **PIN/PUK codes management**:  
    No need to disable LOCK anymore, list connected dongle that need to be  
    unlocked, provide a PIN or PUK, if the unlocking was successful the module  
    will save the code for the SIM so you don't have to provide it again.  
* **Multipart SMS**:  
    Reliably Send and receive multipart SMS, fix all encoding problems.  
* **SMS status report**:  
    Confirm that SMS have been successfully delivered.  
* **SIM phonebook**:  
    Read and write contacts in SIM storage.  
* **Auto configuration of devices**:  
    No need to configure devices in dongle.conf anymore,  
    when a supported device is connected it is automatically detected  
    by the module and instantiated for you.  
    
## July 2022 update

Reported working on Rapberry PI 4 with Ubuntu 18.04. (Installed using [this guide](https://qengineering.eu/install-ubuntu-18.04-on-raspberry-pi-4.html))  

![image](https://user-images.githubusercontent.com/6702424/178040865-4d2fbbd9-716c-438f-81ec-ea9aab2c971c.png)


## February 2022 update

tty0tty update,  
chan-dongle-extended have been reported working with:  

kernel version  5.13.0-28-generic  
Distributor ID: Ubuntu  
Description:    Ubuntu 21.10  
Release:        21.10  
Codename:       impish  

Please [report](https://github.com/garronej/chan-dongle-extended/issues) if it breaks things with older linux Kernel.

## December 2021 update

Recommended debian versions: Stretch (9) or Buster (10).  
*It can work with newer versin as well, I haven't tested. Any report will be much apreciated at: joseph.garrone.gj@gmail.com*  
If you chose to go with `Buster` or newer, you need to install `python 2` manually before running the installer.

We recommend using Debian Buster 10.11.0 (it uses Kernel 4.19.0-18) because it's tested working with the Linux Kernel it ships with. 
Other minor version variant might (or may not) have problems related with kernel header not having [an available package](https://packages.debian.org/fr/buster/linux-headers-amd64). Installing Linux Kerner header by hand is a pain.

You can also use Ubuntu, [every Ubuntu version have a corresponding Debian version](https://askubuntu.com/a/445496).  
This means that:  
    - Debian 9 Streatch <-> Ubuntu 17.10 artful, 17.04 zesty, 16.10  yakkety or 16.04 xenial  
    - Debian 10 Buster <-> Ubuntu 19.10 eoan, 19.04  disco, 18.10 cosmic, 18.04 bionic  
    
You must also run theses command before running the installer:  

```bash
sudo su
apt-get update
apt-get install curl
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
python get-pip.py
pip install virtualenv==20.4.7
```

## Installing

System requirements:
* Debian/Raspbian jessie or newer

To install simply run this command:

````bash
wget -nc -q -O - garronej.github.io/chan-dongle-extended-pages/install.sh | sudo bash
````

![image](https://user-images.githubusercontent.com/6702424/48592742-23117b00-e94a-11e8-80d4-a52142ad96fc.png)


This program act as a system service to stop the service run: 
````bash
sudo systemctl stop chan_dongle
````

To uninstall ``chan-dongle-extended`` run:  
````bash
sudo dongle_uninstaller run
````

Logfile:  
````bash
tail -f /usr/share/dongle/working_directory/log
````

### Behavior on unrecoverable dongle crash.

The service will do what it can to recover from dongle error  
however sometimes the modems just crash and need to be
unplugged/reconnected. This can be a big issue if you do not have  
physical access to the device.  
The only option in this case is to allow ``chan-dongle-extended`` to reboot  
the host when a dongle is unrecoverable crashed.

To grant the permission edit ``/usr/share/dongle/working_directory/install_options.json``
````json
{
    "allow_host_reboot_on_dongle_unrecoverable_crash": true
}
````

## API

The service come bundled with a CLI tool ``dongle``

![image](https://user-images.githubusercontent.com/6702424/48590982-0709db80-e942-11e8-8456-af247c773fdf.png)

![image](https://user-images.githubusercontent.com/6702424/48590810-47b52500-e941-11e8-9fb0-7f54840cfd95.png)

Once unlocked you can see that the modem is handled by ``asterisk-chan-dongle``

![image](https://user-images.githubusercontent.com/6702424/48592557-3ec85180-e949-11e8-9fa3-44d07c1d7517.png)

A npm module is available to interface the service programmatically with Node.js: [`garronej/chan-dongle-extended-client`](https://github.com/garronej/chan-dongle-extended-client)  

## Handling multi parts SMS via the dialplan.

In this example we reply "OK, got you! 👌" to any message we receive

NOTE: All channel variable set in both reassembled-sms and sms-status-report extensions:
DONGLENAME, DONGLEPROVIDER, DONGLEIMEI, DONGLEIMSI, DONGLENUMBER

````ini
[from-dongle]

;In this example we reply to the sender with the same content
exten = reassembled-sms,1,NoOp(reassembled-sms)
same = n,NoOp(SMS_NUMBER=${SMS_NUMBER})
same = n,NoOp(SMS_DATE=${SMS_DATE})
same = n,NoOp(BASE64_DECODE(SMS_BASE64)=${BASE64_DECODE(${SMS_BASE64})})
same = n,Set(SEND_TIME=${SHELL(dongle send --imei ${DONGLEIMEI} --number ${SMS_NUMBER} --text-base64 ${BASE64_ENCODE(OK, got you! 👌)})})
;Or just use System instead of SHELL system if you don't care about the status report
;same = n,System(dongle send -i ${DONGLEIMEI} -n ${SMS_NUMBER} -T ${BASE64_ENCODE(OK, got you! 👌)})
same = n,Hangup()

;Check that the message have been received
exten = sms-status-report,1,NoOp(sms-status-report)
same = n,NoOp(STATUS_REPORT_DISCHARGE_TIME=${STATUS_REPORT_DISCHARGE_TIME})
same = n,NoOp(STATUS_REPORT_IS_DELIVERED=${STATUS_REPORT_IS_DELIVERED})
same = n,NoOp(STATUS_REPORT_ID=${STATUS_REPORT_SEND_TIME})
same = n,NoOp(STATUS_REPORT_STATUS=${STATUS_REPORT_STATUS})
same = n,Hangup()
````

* Asterisk log: 

````raw
-- Executing [reassembled-sms@from-dongle:1] NoOp("Local/init-reassembled-sms@from-dongle-0000001b;2", "reassembled-sms") in new stack
-- Executing [reassembled-sms@from-dongle:2] NoOp("Local/init-reassembled-sms@from-dongle-0000001b;2", "SMS_NUMBER=+33636786385") in new stack
-- Executing [reassembled-sms@from-dongle:3] NoOp("Local/init-reassembled-sms@from-dongle-0000001b;2", "SMS_DATE=2017-05-14T17:37:45.000Z") in new stack
-- Executing [reassembled-sms@from-dongle:4] NoOp("Local/init-reassembled-sms@from-dongle-0000001b;2", "BASE64_DECODE(SMS_BASE64)=Un mal qui répand la terreur,
-- Mal que le Ciel en sa fureur
-- Inventa pour punir les crimes de la terre,
-- La Peste (puisqu’il faut l’appeler par son nom),
-- Capable d’enrichir en un jour l’Achéron,
-- Faisait aux Animaux la guerre.
-- Ils ne mouraient pas tous, mais tous étaient frappés :
-- On n’en voyait point d’occupés
-- À chercher le soutien d’une mourante vie ;
-- Nul mets n’excitait leur envie ;
-- Ni Loups ni Renards n’épiaient
-- La douce et l’innocente proie ;
-- Les Tourterelles se fuyaient :
-- Plus d’amour, partant plus de joie.
-- Le Lion tint conseil, et dit : « Mes chers amis,
-- Je crois que le Ciel a permis
-- Pour nos péchés cette infortune.
-- Que le plus coupable de nous
-- Se sacrifie aux traits du céleste courroux ;
-- Peut-être il obtiendra la guérison commune.") in new stack
-- Executing [reassembled-sms@from-dongle:5] Set("Local/init-reassembled-sms@from-dongle-0000001b;2", "MESSAGE_ID=1494783564908
-- ") in new stack
-- Executing [reassembled-sms@from-dongle:6] Hangup("Local/init-reassembled-sms@from-dongle-0000001b;2", "") in new stack

... Then when "OK, got you! 👌"  received :

-- Goto (from-dongle,sms-status-report,1)
-- Executing [sms-status-report@from-dongle:1] NoOp("Local/init-sms-status-report@from-dongle-0001c;2", "sms-status-report") in new stack
-- Executing [sms-status-report@from-dongle:2] NoOp("Local/init-sms-status-report@from-dongle-0001c;2", "STATUS_REPORT_DISCHARGE_TIME=2017-05-14T17:39:27.000Z") in new stack
-- Executing [sms-status-report@from-dongle:3] NoOp("Local/init-sms-status-report@from-dongle-0001c;2", "STATUS_REPORT_IS_DELIVERED=true") in new stack
-- Executing [sms-status-report@from-dongle:4] NoOp("Local/init-sms-status-report@from-dongle-0001c;2", "STATUS_REPORT_ID=1494783564908") in new stack
-- Executing [sms-status-report@from-dongle:5] NoOp("Local/init-sms-status-report@from-dongle-0001c;2", "STATUS_REPORT_STATUS=COMPLETED_RECEIVED") in new stack
-- Executing [sms-status-report@from-dongle:6] Hangup("Local/init-sms-status-report@from-dongle-0001c;2", "") in new stack
````

Note: SMS_BASE64 truncate message of more than 1024 byte, this is an expected behavior, 
it is to avoid asterisk buffer overflow. You can use the 
SMS_TEXT_SPLIT_COUNT=n and SMS_BASE64_PART_0..n-1 variables to retrieve very long SMS. 
In order to reassemble the message you must base64 decode the concatenation of all SMS_BASE64_PART_X.  

## Asterisk Configuration for good quality phone calls  

![image](https://cloud.githubusercontent.com/assets/6702424/26686554/9253bc18-46ed-11e7-9bce-cad8e2396435.png)  

[This file could help you](https://gist.github.com/garronej/39ef04b3356574621cf272d58adda649)  

## Report bugs

Any feedback highly appreciated.
Feel free to open an issue or start a discution on [the repo of the project](https://github.com/garronej/chan-dongle-extended).  

## Need some compatible GSM Dongle?  

I have a stock that I can sell. Contact me at: joseph.garrone@protonmail.com
