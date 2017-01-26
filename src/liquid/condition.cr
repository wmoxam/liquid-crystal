module Liquid
  # Container for liquid nodes which conveniently wraps decision making logic
  #
  # Example:
  #
  #   c = Condition.new("1", "==", "1")
  #   c.evaluate #=> true
  #
  class Condition #:nodoc:
    getter :attachment
    property left : Type, operator : String | Nil, right : Type

    @child_condition : Condition | Nil
    @attachment : Array(Tag | Variable | String) | Nil

    def initialize(left = nil, operator = nil, right = nil)
      @left, @operator, @right = left, operator, right
      @child_relation  = :nil
    end

    def evaluate(context = Context.new)
      result = interpret_condition(left, right, operator, context)

      case @child_relation
      when :or
        result || @child_condition.not_nil!.evaluate(context)
      when :and
        result && @child_condition.not_nil!.evaluate(context)
      else
        result
      end
    end

    def or(condition)
      @child_relation, @child_condition = :or, condition
    end

    def and(condition)
      @child_relation, @child_condition = :and, condition
    end

    def attach(attachment)
      @attachment = attachment
    end

    def else?
      false
    end

    def inspect
      "#<Condition #{[@left, @operator, @right].compact.join(" ")}>"
    end

    private def equal_variables(left, right)
      left_raw = left.raw
      right_raw = right.raw

      # As per Context#literals, the only symbols that are supported
      # are #blank? & #empty?
      if left_raw.is_a? Symbol
        return case left_raw
        when :blank?
          right_raw.blank? if right_raw.responds_to?(:blank?)
        when :empty?
          right_raw.empty? if right_raw.responds_to?(:empty?)
        end
      end

      if right_raw.is_a? Symbol
        return case right_raw
        when :blank?
          left_raw.blank? if left_raw.responds_to?(:blank?)
        when :empty?
          left_raw.empty? if left_raw.responds_to?(:empty?)
        end
      end

      left_raw == right_raw
    end

    private def interpret_condition(left, right, op, context)
      # If the operator is empty this means that the decision statement is just
      # a single variable. We can just poll this variable from the context and
      # return this as the result.
      if op == nil
        return context[left]
      end

      left, right = Any.new(context[left]), Any.new(context[right])

      case op
      when "=="
        equal_variables(left, right)
      when "!=", "<>"
        !equal_variables(left, right)
      when "<", ">", ">=", "<="
        left.compare(op.as String, right)
      when "contains"
        left && right ? left.include?(right) : false
      else
        raise ArgumentError.new("Unknown operator #{op}")
      end
    end
  end

  class ElseCondition < Condition
    def else?
      true
    end

    def evaluate(context)
      true
    end
  end

end
