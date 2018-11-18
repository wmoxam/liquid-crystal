require "html"

module Liquid
  class StandardFilters < Filter
    # Return the size of an array or of an string
    def size(input)
      input.responds_to?(:size) ? input.size : 0
    end

    # convert a input string to DOWNCASE
    def downcase(input)
      input.to_s.downcase
    end

    # convert a input string to UPCASE
    def upcase(input)
      input.to_s.upcase
    end

    # capitalize words in the input centence
    def capitalize(input)
      input.to_s.capitalize
    end

    def escape(input)
      HTML.escape(input.to_s)
    end

    def escape_once(input)
      regexp = /["><']|&(?!([a-zA-Z]+|(#\d+));)/
      mappings = {"&" => "&amp;",
                  ">" => "&gt;",
                  "<" => "&lt;",
                  "\"" => "&quot;",
                  "'" => "&#39;"}
      input.to_s.gsub(regexp, mappings)
    end

    def h(input)
      escape_once(input)
    end

    # Truncate a string down to x characters
    def truncate(input : String?,
                 length : Int32 = 30,
                 truncate_string : String = "...")
      return nil if input.nil?
      l = length.to_i - truncate_string.size
      l = 0 if l < 0
      input.size > length.to_i ? input[0...l] + truncate_string : input
    end

    def truncatewords(input : String?,
                      words : Int32 = 15,
                      truncate_string : String = "...")
      return nil if input.nil?
      wordlist = input.to_s.split
      l = words.to_i - 1
      l = 0 if l < 0
      wordlist.size > l ? wordlist[0..l].join(" ") + truncate_string : input
    end

    # Split input string into an array of substrings separated by given pattern.
    #
    # Example:
    #   <div class="summary">{{ post | split "//" | first }}</div>
    #
    def split(input : String?, pattern : Regex? | String?)
      if pattern.nil?
        return [] of String
      else
        input.to_s.split(pattern)
      end
    end

    def strip_html(input)
      input.to_s.gsub(/<script.*?<\/script>/, "").gsub(/<!--.*?-->/, "").gsub(/<.*?>/, "")
    end

    # Remove all newlines from the string
    def strip_newlines(input)
      input.to_s.gsub(/\n/, "")
    end

    # Join elements of the array with certain character between them
    def join(input, glue = " ")
      [input].flatten.join(glue)
    end

    # # Sort elements of the array
    # # provide optional property with which to sort an array of hashes or drops
    # def sort(input, property = nil)
    #   ary = [input].flatten
    #   if property.nil?
    #     ary.sort
    #   elsif ary.first.responds_to?("[]") && !ary.first[property].nil?
    #     ary.sort {|a,b| a[property] <=> b[property] }
    #   elsif ary.first.responds_to?(property)
    #     ary.sort {|a,b| a.send(property) <=> b.send(property) }
    #   end
    # end

    # map/collect on a given property
    # def map(input, property)
    #   ary = [input].flatten
    #   ary.map do |e|
    #     e = e.call if e.is_a?(Proc)
    #     e = e.to_liquid if e.responds_to?(:to_liquid)
    #
    #     if property == "to_liquid"
    #       e
    #     elsif e.responds_to?(:[])
    #       e[property]
    #     end
    #   end
    # end

    # Replace occurrences of a string with another
    def replace(input, string, replacement = "")
      input.to_s.gsub(string.to_s, replacement.to_s)
    end

    # Replace the first occurrences of a string with another
    def replace_first(input, string, replacement = "")
      input.to_s.sub(string.to_s, replacement.to_s)
    end

    # remove a substring
    def remove(input, string)
      input.to_s.gsub(string.to_s, "")
    end

    # remove the first occurrences of a substring
    def remove_first(input, string)
      input.to_s.sub(string.to_s, "")
    end

    # add one string to another
    def append(input, string)
      input.to_s + string.to_s
    end

    # prepend a string to another
    def prepend(input, string)
      string.to_s + input.to_s
    end

    # Add <br /> tags in front of all newlines in input string
    def newline_to_br(input)
      input.to_s.gsub(/\n/, "<br />\n")
    end

    # Reformat a date
    #
    #   %a - The abbreviated weekday name (``Sun'')
    #   %A - The  full  weekday  name (``Sunday'')
    #   %b - The abbreviated month name (``Jan'')
    #   %B - The  full  month  name (``January'')
    #   %c - The preferred local date and time representation
    #   %d - Day of the month (01..31)
    #   %H - Hour of the day, 24-hour clock (00..23)
    #   %I - Hour of the day, 12-hour clock (01..12)
    #   %j - Day of the year (001..366)
    #   %m - Month of the year (01..12)
    #   %M - Minute of the hour (00..59)
    #   %p - Meridian indicator (``AM''  or  ``PM'')
    #   %S - Second of the minute (00..60)
    #   %U - Week  number  of the current year,
    #           starting with the first Sunday as the first
    #           day of the first week (00..53)
    #   %W - Week  number  of the current year,
    #           starting with the first Monday as the first
    #           day of the first week (00..53)
    #   %w - Day of the week (Sunday is 0, 0..6)
    #   %x - Preferred representation for the date alone, no time
    #   %X - Preferred representation for the time alone, no date
    #   %y - Year without a century (00..99)
    #   %Y - Year with century
    #   %Z - Time zone name
    #   %% - Literal ``%'' character
    def date(input, format)
      return nil if input.nil?

      if format.to_s.empty?
        return input.to_s
      end

      date = if input.is_a?(Time)
               input
             elsif (input.is_a?(String) && !/^\d+$/.match(input.to_s).nil?)
               Time.unix(input.to_i)
             elsif input.is_a?(Int) && input > 0
               Time.unix(input)
             else
               begin
                 Time.parse(input.to_s, "%F %T", Time::Location.local)
               rescue # Time::Format::Error
                 begin
                   Time.parse(input.to_s, "%c", Time::Location.local)
                 rescue
                   begin
                     Time.parse(input.to_s, "%Y%m%d", Time::Location.local)
                   rescue
                     nil
                   end
                 end
               end
             end

      if date.is_a?(Time)
        date.to_s(format.to_s)
      else
        input
      end
    rescue
      input
    end

    # Get the first element of the passed in array
    #
    # Example:
    #    {{ product.images | first | to_img }}
    #
    def first(array)
      array.first? if array.responds_to?(:first)
    end

    # Get the last element of the passed in array
    #
    # Example:
    #    {{ product.images | last | to_img }}
    #
    def last(array)
      array.last? if array.responds_to?(:last)
    end

    # addition
    def plus(input, operand)
      to_number(input) + to_number(operand)
    end

    # subtraction
    def minus(input, operand)
      to_number(input) - to_number(operand)
    end

    # multiplication
    def times(input, operand)
      to_number(input) * to_number(operand)
    end

    # division
    def divided_by(input, operand)
      to_number(input) / to_number(operand)
    end

    def modulo(input, operand)
      to_number(input).to_i % to_number(operand).to_i
    end

    private def to_number(obj)
      case obj
      when Number
        obj
      when String
        if (obj.strip =~ /^\d+\.\d+$/)
          obj.to_f rescue 0.0
        else
          obj.to_i rescue 0
        end
      else
        0
      end
    end
  end

  Strainer.global_filter StandardFilters
end
