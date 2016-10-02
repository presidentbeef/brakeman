Denial of Service (DoS) is any attack which causes a service to become unavailable for legitimate clients.

For issues that Brakeman detects, this typically arises in the form of memory leaks.

### Symbol DoS

Since Symbols are not garbage collected in Ruby versions prior to 2.2.0, creation of large numbers of Symbols could lead to a server running out of memory.

Brakeman checks for instances of user input which is converted to a Symbol. When this is not restricted, an attacker could create an unlimited number of Symbols.

The best approach is to simply never convert user-controlled input to a Symbol. If this cannot be avoided, use a whitelist of acceptable values.

For example:

    valid_values = ["valid", "values", "here"]

    if valid_values.include? params[:value]
      symbolized = params[:value].to_sym
    end


### Regex DoS

Regular expressions can be used for DoS if the pattern and input requires exponential time to process.

Brakeman will warn about dynamic regular expressions which may be controlled by an attacker. The attacker can create an "[evil regex](https://www.owasp.org/index.php/Regular_expression_Denial_of_Service_-_ReDoS)" and then supply input which causes the server to use a large amount of resources.

It is recommended to avoid interpolating user input into regular expressions.
