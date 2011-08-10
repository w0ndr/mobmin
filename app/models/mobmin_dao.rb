require 'active_record'
require 'table_info'
require 'column_info'

class MobminDao

  attr_reader :connection
	attr_writer :user, :psw


	def initialize(user, password)
		@user = user
		@psw = password
	end

  def connection()
#    if(!ActiveRecord::Base.connected?)
			puts "Conecting ................................."
      ActiveRecord::Base.establish_connection(
        :adapter  => "mysql2",
        :host     => "localhost",
        :username => @user,
        :password => @psw
      )
#    end
     
    return ActiveRecord::Base.retrieve_connection
  end

	def clear_connection
    if(ActiveRecord::Base.connected?)
			ActiveRecord::Base.remove_connection
		end

	end

=begin
	Method retrieves list of databases available to current user
=end
  def show_databases
    stmt = "show databases"
    return self.connection.execute(stmt)
  end

=begin
	Method retrieves list of tables in database

	@param database name of selected database
	@return Array 
=end
  def show_tables(database)
    #TO-DO - sanitize stmt
    stmt = "show tables from " + database
    return self.connection.execute(stmt)
  end

=begin
	Method adds table information (row count, columns info) retrieved from database
	to TableInfo object.

	@param database_name 	name of database that table belongs to
	@param table_name			name of the table
	@return TableInfo object
=end
  def table_info(database_name, table_name)
#    stmt = "use " + database_name
#    self.connection.execute(stmt)

    table = TableInfo.new(database_name, table_name)

		stmt = "show table status in #{database_name} where name = '#{table_name}'"
    result = self.connection.execute(stmt).to_a.first
    table.row_count = result[4]
		table.engine = result[1]
		table.collation = result[14]

    stmt = "show full columns in #{database_name}.#{table_name}"
    fields = self.connection.execute(stmt).to_a
		fields.each do |field|
			column = ColumnInfo.new
			column.name = field[0]
			column.type = field[1]
			column.collation = field[2]
			column.nullable = field[3]
			column.key = field[4]
			column.def_value = field[5]
			column.auto_increment = field[6]
			column.comment = field[8]
			table.columns << column
		end

    return table
  end

=begin
	Method retrieve table information and data from database

	@param database_name 	name of database that table belongs to
	@param table_name			name of the table
	@return TableInfo object
=end
  def show_data(database_name, table_name)

    table = table_info(database_name, table_name)

    stmt = "select * from #{database_name}.#{table_name}"
    result = self.connection.execute(stmt)
		table.rows = result.to_a

		#workaround for encoding bug
		#if column collation is utf8_bin mysql2 returns latin1 encoding
		table.columns.each_index { |i|
			if !table.columns[i].collation.nil? && table.columns[i].collation.downcase.eql?("utf8_bin")
				table.rows.each { |row|
					row[i] = row[i].force_encoding("UTF-8")
				}
			end
			if table.columns[i].type.downcase.include?("blob")
				table.rows.each { |row|
					size = row[i].size
					row[i] = size.to_s + " bytes"
				}
			end
		}

    return table

  end

	def insert_data(data = {}, database_name, table_name)

		if !data.empty?

			cols = ""
			vals = ""

			data.each_pair { |column, value|
				if !value[1].empty?
					cols = cols + value[0] + ", "
					vals = vals + "'" + value[1] + "', "
				end
			}

			if !cols.empty?
				cols = cols.rstrip
				cols = cols.chop
				vals = vals.rstrip
				vals = vals.chop
			end

#			stmt = "use " + database_name
#			self.connection.execute(stmt)
			stmt = "insert into #{database_name}.#{table_name} (#{cols}) values(#{vals})"
			puts stmt
			result = self.connection.execute(stmt)
			puts result

		end

	end

	def delete_row(row = {}, database_name, table_name)

		size = (row.length / 2).to_i
		size -= 1

#		stmt = "use " + database_name
#		self.connection.execute(stmt)

		stmt = "delete from #{database_name}.#{table_name} where"
		for i in 0..size
			key = "key-" + i.to_s
			val = "val-" + i.to_s
			stmt += " " + row[key] + " = " + "'" + row[val] + "' and" if !(row[val].nil? || row[val].eql?(""))
		end
		
		stmt[-4, 4] = ""

		self.connection.execute(stmt)

	end

	def update_row(data = {}, database_name, table_name)

		error = ""

		table = table_info(database_name, table_name)

#		stmt = "use " + database_name
#		self.connection.execute(stmt)

		stmt = "select * from #{database_name}.#{table_name} where"
		data.each_pair { |key, value|
			if !(value.first.empty? || value.first.eql?(''))
				stmt += " #{key} = '#{value.first}'"
				stmt += " and"
			end
		}
		stmt[-4,4] = ""

    result = self.connection.execute(stmt)
		table.rows = result.to_a

		begin
		data.each_pair{ |key, value|
			stmt = "update #{database_name}.#{table_name} set "
			stmt += "#{key} = '#{value[1]}' "
			stmt += "where"
			data.each_pair{|k, v|
				if k != key
					stmt += " #{k} = '#{v[0]}' and"
				end
			}
			stmt[-4, 4] = ""

			self.connection.execute(stmt)
			data[key][0] = value[1]

		}
		rescue Exception => e
			data.each_pair{|key, value|
				index = 0
				table.columns.each_index { |i|
					if table.columns[i].name.eql?(key)
						index = i
					end
				}
				stmt = "update #{database_name}.#{table_name} set "
				stmt += "#{key} = '#{table.rows.first[index]}' "
				stmt += "where"
				data.each_pair{|k, v|
					if k != key
						stmt += " #{k} = '#{v[0]}' and"
					end
				}
				stmt[-4, 4] = ""

				self.connection.execute(stmt)

				data[key][0] = table.rows.first[index]
			}

			error = e.message
		end

		return error

	end


end
