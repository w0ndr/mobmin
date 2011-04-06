require 'active_record'

class MobminDao

  attr_reader :connection

  def connect(usr, psw)
    begin
      ActiveRecord::Base.establish_connection(
          :adapter  => "mysql",
          :host     => "localhost",
          :username => usr,
          :password => psw
        )
        connection = ActiveRecord::Base.retrieve_connection
        stmt = "show databases"
        result = connection.execute(stmt)
        return result
    rescue
      return false
    end

  end

  def connection()
    if(!ActiveRecord::Base.connected?)
      ActiveRecord::Base.establish_connection(
        :adapter  => "mysql",
        :host     => "localhost",
        :username => "root",
        :password => "st3v3"
      )
    end
     
    return ActiveRecord::Base.retrieve_connection
  end

  def show_databases
    stmt = "show databases"
    return self.connection.execute(stmt)
  end

  def show_tables(database)
    #TO-DO - sanitize stmt
    stmt = "show tables from " + database
    return self.connection.execute(stmt)
  end

  def table_info(database, table)
    stmt = "use " + database
    self.connection.execute(stmt)

    info = {}

    stmt = "select * from " + table
    result = self.connection.execute(stmt)
    info["rows"] = result.num_rows
    stmt = "show columns in " + table
    info["fields"] = self.connection.execute(stmt)

    return info
  end

  def show_data(database, table)
    stmt = "use " + database
    self.connection.execute(stmt)

    info = {}
    legend = []

    stmt = "select * from " + table
    info["rows"] = self.connection.execute(stmt)

    stmt = "show columns in " + table
    columns = self.connection.execute(stmt)
    columns.each{|column|
      legend.push(column[0])
    }
    info["legend"] = legend

    return info
  end

end
