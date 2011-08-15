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
			puts "Conecting ................................."
      ActiveRecord::Base.establish_connection(
        :adapter  => "mysql2",
        :host     => "localhost",
        :username => @user,
        :password => @psw
      )
     
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

    table = TableInfo.new(database_name, table_name)

		stmt = "SHOW TABLE STATUS IN #{database_name} WHERE NAME = '#{table_name}'"
    result = self.connection.execute(stmt).to_a.first
    table.row_count = result[4]
		table.engine = result[1]
		table.collation = result[14]

    stmt = "SHOW FULL COLUMNS IN #{database_name}.#{table_name}"
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
  def show_data(database_name, table_name, where, what)

    table = table_info(database_name, table_name)

		if !where.nil? && !what.nil?
			stmt = "SELECT * FROM #{database_name}.#{table_name} WHERE #{where} LIKE '#{what}'"
		else
    	stmt = "SELECT * FROM #{database_name}.#{table_name}"
		end

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

=begin
	Method inserts data into specified table in database

	@param data 					hash array with values to be saved
	@param database_name 	name of database that table belongs to
	@param table_name			name of the table
=end
	def insert_data(data = {}, database_name, table_name)

		if !data.empty?

			cols = ""
			vals = ""

			data.each_pair { |column, value|
				if !value[1].empty?
					cols = cols + value[0] + ", "
					vals = vals + "'" + value[1] + "', "
				end if !value[1].nil?
			}

			if !cols.empty?
				cols = cols.rstrip
				cols = cols.chop
				vals = vals.rstrip
				vals = vals.chop
			end

			stmt = "INSERT INTO #{database_name}.#{table_name} (#{cols}) VALUES(#{vals})"
			result = self.connection.execute(stmt)

		end

	end

=begin
	Method removes data from specified table in database

	@param row	 					hash array with values to be removed
	@param nils						hash array with NULL values
	@param database_name 	name of database that table belongs to
	@param table_name			name of the table
=end
	def delete_row(row = {}, nils = {}, database_name, table_name)

		size = (row.length / 2).to_i
		size -= 1

		stmt = "DELETE FROM #{database_name}.#{table_name} WHERE"
		for i in 0..size
			key = "key-" + i.to_s
			val = "val-" + i.to_s
			stmt += " #{row[key]} = '#{row[val]}' AND" if !row[val].nil?
		end

		if !nils.nil?
			size = nils.size - 1
			for i in 0..size
				key = "key-" + i.to_s
				stmt += " #{nils[key]} IS NULL AND"
			end
		end
		
		stmt[-4, 4] = ""
		stmt += " LIMIT 1"

		self.connection.execute(stmt)

	end

=begin
	This method updates selected row with provided data. It provides basic transaction service.
	In case of database error during update process, it return the original data into database.

	@param data						hash array of original data and new data to be updated
	@param database_name 	name of database that table belongs to
	@param table_name			name of the table
=end
	def update_row(data = {}, database_name, table_name)

		error = ""

		table = table_info(database_name, table_name)

		stmt = "SELECT * FROM #{database_name}.#{table_name} WHERE"
		data.each_pair { |key, value|
			if !value.first.nil?
				stmt += " #{key} = '#{value.first}'"
			else
				stmt += " #{key} IS NULL"
			end
			stmt += " AND"
		}
		stmt[-4,4] = ""
		stmt += " LIMIT 1"

    result = self.connection.execute(stmt)
		table.rows = result.to_a

		begin
		data.each_pair{ |key, value|
			stmt = "UPDATE #{database_name}.#{table_name} SET "
			if value[1].nil? || value[1].eql?('')
				value[1] = ''
			end
				stmt += "#{key} = '#{value[1]}' "
			stmt += "WHERE"
			data.each_pair{|k, v|
					if v[0].nil? 
						stmt += " #{k} IS NULL AND"
					else
						stmt += " #{k} = '#{v[0]}' AND"
					end
			}
			stmt[-4, 4] = ""
			stmt += " LIMIT 1"

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
				stmt = "UPDATE #{database_name}.#{table_name} SET "
				if table.rows.first[index].nil?
					stmt += "#{key} = NULL "
				else
					stmt += "#{key} = '#{table.rows.first[index]}' "
				end
				stmt += "WHERE"
				data.each_pair{|k, v|
						if v[0].nil?
							stmt += " #{k} IS NULL AND"
						else
							stmt += " #{k} = '#{v[0]}' AND"
						end
				}
				stmt[-4, 4] = ""

				self.connection.execute(stmt)

				data[key][0] = table.rows.first[index]
			}

			error = e.message.sub("Mysql2::", "")
		end

		return error

	end

end
