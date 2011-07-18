class ColumnInfo

	attr_accessor :name, :type, :collation, :nullable, :key, :def_value, :auto_increment, :comment, :pk, :unique

	def initialize
		@name = ""
		@type = ""
		@collation = ""
		@nullable = true
		@key = ""
		@def_value = nil
		@auto_increment = false
		@pk = false
		@unique = false
		@comment = ""

	end

	def nullable=(new_value)
		if !new_value.nil?
			if new_value.downcase.eql?("no")
				@nullable = false
			end
		end

	end

	def key=(new_key)

		if !new_key.nil? && !new_key.empty?
			if new_key.downcase.eql?("pri")
				@key = "Primary key"
				@pk = true
			elsif new_key.downcase.eql?("uni")
				@key = "Unique constraint"
				@unique = true
			elsif new_key.downcase.eql?("mul")
				@key = "Multiple occurences"
			end
		end

	end

	def auto_increment=(new_ai)
		if !new_ai.nil?
			@auto_increment = new_ai.downcase.eql?("auto_increment")
		end
	end
end