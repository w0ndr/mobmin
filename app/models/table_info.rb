class TableInfo

	attr_accessor :database, :name, :row_count, :columns, :rows, :engine, :collation

	def initialize(database_name, table_name)
		@database = database_name
		@name = table_name
		@row_count = 0
		@columns = []
		@rows = []
		@engine = ""
		@collation = ""
	end

end