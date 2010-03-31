class Array

  def compress
    range_start = nil
    previous = nil
    ranges = []
    leftovers = []
    sorted = compact.uniq.sort

    return ranges, sorted if sorted.size == 1

    (sorted = sort).each do |n|
      if !range_start && !previous
        range_start = n
        previous = n
      else
        if sorted.last == n
          if range_start == previous
            if previous + 1 == n
              ranges << (range_start..n)
            else
              leftovers << previous
              leftovers << n
            end
          else
            if previous + 1 == n
              ranges << (range_start..n)
            else
              ranges << (range_start..previous)
              leftovers << n
            end
          end
        elsif previous + 1 != n
          if range_start == previous
            leftovers << previous
          else
            ranges << (range_start..previous)
          end
          range_start = n
        end
      end

      previous = n
    end

    return ranges, leftovers
  end

end
