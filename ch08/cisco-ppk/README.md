# Cisco IOS XE RFC 8784 PPK verification exercise

This exercise is documentation-verified but not executed in the review
environment because it requires licensed Cisco IOS XE on a supported platform.
Use the current Cisco configuration guide for the exact software train and
hardware model before applying the commands.

The minimum configuration is more than two `keyring` lines. It requires:

1. An IKEv2 authentication keyring or another supported authentication method.
2. A separate PPK keyring containing `ppk manual id ... key ...` or a supported
   external key-source integration.
3. An IKEv2 profile that references the authentication keyring and the PPK
   keyring.
4. A policy decision on whether PPK is required. Optional fallback permits a
   non-PPK session and must be monitored.
5. Operational verification with `show crypto ikev2 sa detailed`.

Do not copy a sample PPK into production. Generate a high-entropy value, deliver
it through an independent protected channel, store it as a managed secret, and
define rotation and revocation procedures.

Native ML-KEM support and RFC 8784 PPK support have different platform and
software matrices. As of IOS XE 26.1, Cisco documents native IKEv2 ML-KEM on
specific physical C8100 through C8500 secure-router families, not Catalyst
8000V. Cisco separately documents RFC 8784 PPK support for Catalyst 8000V from
IOS XE 17.11.1a. Verify both the platform and the release rather than inferring
one feature from the other.
