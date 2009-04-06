module Wheels::ViewContext::Helpers::Html

  ##
  # Takes a flat array and yields the data properly separated into columns.
  ##
  def split_into_columns(data, columns = 2) #:yields: column
    per_column = (data.size / columns.to_f).ceil

    columns.times do |i|
      yield data[i*per_column, per_column]
    end
  end

end