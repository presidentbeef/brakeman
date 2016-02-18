Brakeman reports on several cases of remote code execution, in which a user is able to control and execute code in ways unintended by application authors.

The obvious form of this is the use of `eval` with user input.

However, Brakeman also reports on dangerous uses of `send`, `constantize`, and other methods which allow creation of arbitrary objects or calling of arbitrary methods.

