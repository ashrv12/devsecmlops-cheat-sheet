kubectl exec -it openbao-0 -- /bin/sh

bao operator init

# Unseal Key 1: MBFSDepD9E6whREc6Dj+k3pMaKJ6cCnCUWcySJQymObb
# Unseal Key 2: zQj4v22k9ixegS+94HJwmIaWLBL3nZHe1i+b/wHz25fr
# Unseal Key 3: 7dbPPeeGGW3SmeBFFo04peCKkXFuuyKc8b2DuntA4VU5
# Unseal Key 4: tLt+ME7Z7hYUATfWnuQdfCEgnKA2L173dptAwfmenCdf
# Unseal Key 5: vYt9bxLr0+OzJ8m7c7cNMFj7nvdLljj0xWRbpLezFAI9

# Initial Root Token: s.zJNwZlRrqISjyBHFMiEca6GF
##...

# SAVE THIS

bao operator unseal
# Input one of the unseal keys

bao operator unseal
# Input another one of the unseal keys

bao operator unseal
# Input one more of the unseal keys

bao status
# Key             Value
# ---             -----
# Seal Type       shamir
# Initialized     true
# Sealed          false
# Total Shares    5
# Threshold       3
# Version         2.5.2
# Build Date      2026-03-25T16:16:27Z
# Storage Type    file
# Cluster Name    vault-cluster-f9362ebd
# Cluster ID      04ae9737-68db-2042-740d-c8582baeb994
# HA Enabled      false


bao login
# Token (will be hidden):
# Success! You are now authenticated. The token information displayed below is
# already stored in the token helper. You do NOT need to run "bao login" again.
# Future OpenBao requests will automatically use this token.

# Key                  Value
# ---                  -----
# token                s.Dbhasdasdadsasd
# token_accessor       LKASJDbakfdsjhfIAJos
# token_duration       ∞
# token_renewable      false
# token_policies       ["root"]
# identity_policies    []
# policies             ["root"]
