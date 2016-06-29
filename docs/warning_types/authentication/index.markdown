"Authentication" is the act of verifying that a user or client is who they say they are.

Right now, the only Brakeman warning in the authentication category is regarding hardcoded passwords.
Brakeman will warn about constants with literal string values that appear to be passwords.

Hardcoded passwords are security issues since they imply a single password and that password is stored in the source code.
Typically source code is available to a wide number of people inside an organization, and there have been many instances of source
code leaking to the public. Passwords and secrets should be stored in a separate, secure location to limit access.

Additionally, it is recommended not to use a single password for accessing sensitive information.
Each user should have their own password to make it easier to audit and revoke access.
