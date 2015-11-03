When a call to `render` uses a dynamically generated path, template name, file name, or action, there is the possibility that a user can access templates that should be restricted. The issue may be worse if those templates execute code or modify the database.

This warning is shown whenever the path to be rendered is not a static string or symbol.

These warnings are often false positives, however, because it can be difficult to manipulate Rails' assumptions about paths to perform malicious behavior. Reports of dynamic render paths should be checked carefully to see if they can actually be manipulated maliciously by the user.
