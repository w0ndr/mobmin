require 'table_info'

class MobminController < ApplicationController

  def index

		if session[:error]
			@error = session[:error].to_s

			render :layout => 'inner'
		end

		session[:error] = nil

  end

  def show_databases

		session[:error] = nil
    
		session[:user] = params[:username] if !params[:username].nil?
		session[:psw] = params[:password] if !params[:password].nil?

    	mdao = MobminDao.new(session[:user], session[:psw])

			begin
				@databases = mdao.show_databases()
				render :layout => 'inner'
			rescue Exception => ex
				session[:error] = ex.message.sub("Mysql2::", "")
				redirect_to :action => "index"
			end
    
  end

  def show_tables

    session[:db] = params[:db] if !params[:db].nil?
    mdao = MobminDao.new(session[:user], session[:psw])
		@database = session[:db]
    @tables = mdao.show_tables(session[:db])

		render :layout => 'inner'
  end

  def table_detail

		session[:table] = params[:table] if !params[:table].nil?
		@table = session[:table]

		render :layout => 'inner'
  end

  def table_info

    @table = session[:table]
    mdao = MobminDao.new(session[:user], session[:psw])
    @table_info = mdao.table_info(session[:db], session[:table])

		render :layout => 'inner'
  end

  def show_data

		if params[:error]
			@error = "Error while saving data<br />" + session[:error].to_s
		end

    mdao = MobminDao.new(session[:user], session[:psw])
    @table = mdao.show_data(session[:db], session[:table], nil, nil)

		render :layout => 'inner'
  end

  def insert_data

		if params[:error]
			@error = "Error while saving data<br />" + session[:error].to_s
		end
    mdao = MobminDao.new(session[:user], session[:psw])
    @table = mdao.table_info(session[:db], session[:table])

#		if params[:data]
#			@table.rows[0] = []
#			params[:data].each_pair { |key, val|
#				@table.rows[0] << val
#			}
#			puts @table.rows.inspect
#		end

		render :layout => 'inner'
  end

	def save_data
		session[:db] = params[:database_name]
		session[:table] = params[:table_name]
		session[:user] = params[:user]
		session[:psw] = params[:psw]

		data = {}
		params[:key].each_pair { |k, v|
			data[k] = [v, params[:val][k]]
		}

		mdao = MobminDao.new(session[:user], session[:psw])
		begin
			mdao.insert_data(data, params[:database_name], params[:table_name])
			redirect_to :action => "show_data"
		rescue Exception => e
			session[:error] = e.message.sub("Mysql2::", "")
			redirect_to :action => "insert_data", :error => true
		end

	end

	def delete_row
		session[:db] = params[:database_name]
		session[:table] = params[:table_name]
		session[:user] = params[:user]
		session[:psw] = params[:psw]

		mdao = MobminDao.new(session[:user], session[:psw])
		mdao.delete_row(params[:del], params[:nil], session[:db], session[:table])

		redirect_to :action => "show_data"

	end

	def edit_data
		session[:user] = params[:user]
		session[:psw] = params[:psw]
		session[:db] = params[:database_name]
		session[:table] = params[:table_name]

		@table = TableInfo.new(session[:db], session[:table])
		row = []
		size = params[:col].size
		size -= 1
		for i in 0..size
			key = "key-" + i.to_s
			val = "val-" + i.to_s
			column = ColumnInfo.new
			column.type = params[:col][i.to_s]
			column.name = params[:ed][key]
			@table.columns << column
			row << params[:ed][val]
		end
		@table.rows << row

		render :layout => 'inner'
	end

	def update_data

		session[:db] = params[:database_name]
		session[:table] = params[:table_name]
		session[:user] = params[:user]
		session[:psw] = params[:psw]
		data = {}

		name = params[:name]
		new_row = params[:new]
		old_row = params[:old]

		name.each_key {|k|
			data[name[k]] = [old_row[k], new_row[k]]
		}

		mdao = MobminDao.new(session[:user], session[:psw])
		result = mdao.update_row(data, session[:db], session[:table])
		if result.eql?("")
			redirect_to :action => "show_data"
		else
			session[:error] = result
			redirect_to :action => "show_data", :error => "true"
		end


	end

	def search
		mdao = MobminDao.new(session[:user], session[:psw])
    @table = mdao.table_info(session[:db], session[:table])

		render :layout => 'inner'
	end

	def search_result
		session[:db] = params[:database_name]
		session[:table] = params[:table_name]
		session[:user] = params[:user]
		session[:psw] = params[:psw]

		mdao = MobminDao.new(session[:user], session[:psw])
		@table = mdao.show_data(session[:db], session[:table], params[:col], params[:val])

		render :layout => 'inner', :template => 'mobmin/show_data'

	end

	def logout
		puts "Loggin out .................................."
		mdao = MobminDao.new(session[:user], session[:psw])
		mdao.clear_connection
		session[:user] = nil
		session[:psw] = nil

		redirect_to :action => "index"
		session[:error] = nil
		session[:error] = "Successfully logged out"

	end

end
