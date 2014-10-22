class Exception < Exception
end

class DescendentException < Exception
end

class ExceptionA < ExceptionB
end

class ExceptionB < ExceptionA
end
