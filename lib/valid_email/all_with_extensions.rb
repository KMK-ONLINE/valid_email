require 'valid_email'
class String

  def email?(options={})
    ValidEmail::ValidateEmail.valid?(self, options)
  end

end

class NilClass

  def email?(options={})
    false
  end

end