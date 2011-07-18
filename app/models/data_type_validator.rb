class DataTypeValidator

		@@string_types = [
			"char",
			"varchar",
			"tinytext",
			"text",
			"mediumtext",
			"longtext"
		]
		@@numeric_types = [
			"tinyint",
			"smallint",
			"mediumint",
			"int",
			"bigint",
			"decimal",
			"float",
			"double"
		]
		@@date_types = [
			"date",
			"datetime",
			"timestamp",
			"time",
			"year"
		]
		@@bin_types = [
			"bit",
			"binary",
			"varbinary",
			"tinyblob",
			"blob",
			"mediumblob",
			"longblob"
		]
		@@list_types = [
			"enum",
			"set"
		]

	def validate(data)

		new_type = ""
		new_length = ""

		data.each_pair{ |type, value|
			type.match('\(.*\)') { |length|
				new_type = type.sub(length.to_s, "")
				new_length = length.to_s.chop
				new_length.slice!(0)
			}

			if new_type.empty?
				new_type = type
			end
		}
		puts new_type
		puts new_length

		if @@string_types.include?(new_type)
			puts "text"
		elsif @@numeric_types.include?(new_type)
			puts "number"
		elsif @@date_types.include?(new_type)
			puts "date"
		elsif @@bin_types.include?(new_type)
			puts "binary"
		elsif @@list_types.include?(new_type)
			puts "list"
		end

	end
end