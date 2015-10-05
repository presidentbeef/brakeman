This warning comes up if a model does not limit what attributes can be set through mass assignment.

In particular, this check looks for `attr_accessible` inside model definitions. If it is not found, this warning will be issued.

Brakeman also warns on use of `attr_protected` - especially since it was found to be [vulnerable to bypass](https://groups.google.com/d/topic/rubyonrails-security/AFBKNY7VSH8/discussion). Warnings for mass assignment on models using `attr_protected` will be reported, but at a lower confidence level.

Note that disabling mass assignment globally will suppress these warnings.
