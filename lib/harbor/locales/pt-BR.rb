locale = Harbor::Locale.new
locale.culture_code        = 'pt-BR'
locale.time_formats        = {:long => "%d/%m/%Y %H:%m:%s", :default => "%H:%m:%s"}
locale.date_formats        = {:default => '%d/%m/%Y'}
locale.decimal_formats     = {:default => "%8.2f", :currency => "R$%8.2f"}
locale.wday_names          = [nil, 'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado']
locale.wday_abbrs          = [nil, 'Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab']
locale.month_names         = [nil, 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
locale.month_abbrs         = [nil, 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
locale.meridian_indicator = {"AM" => "AM", "PM" => "PM"}
Harbor::Locale.register(locale)
