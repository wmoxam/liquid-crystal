require "time"

class String # :nodoc:
  def to_liquid
    self
  end
end

class Array # :nodoc:
  def to_liquid
    self
  end
end

class Hash # :nodoc:
  def to_liquid
    self
  end
end

struct Number # :nodoc:
  def to_liquid
    self
  end
end

struct Time # :nodoc:
  def to_liquid
    self
  end
end

struct Bool
  def to_liquid # :nodoc:
    self
  end
end

struct Nil
  def to_liquid # :nodoc:
    self
  end
end

struct Range
  def to_liquid # :nodoc:
    self
  end
end

struct Symbol
  def to_liquid # :nodoc:
    self
  end
end

struct Tuple
  def to_liquid # :nodoc:
    self
  end
end
