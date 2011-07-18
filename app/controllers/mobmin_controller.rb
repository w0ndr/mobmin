require 'table_info'

class MobminController < ApplicationController

  def index

		 if params[:error]
			@error = "Bad username or password"
		 end
  end

  def show_databases
    
			session[:user]=(params[:username])
			session[:psw]=(params[:password])

    	mdao = MobminDao.new(session[:user], session[:psw])

			begin
				@databases = mdao.show_databases()
			rescue Exception => ex
				puts ex.message
				redirect_to :action => "index", :error => "true"
			end
    
  end

  def show_tables

    session[:db] = params[:db]
    mdao = MobminDao.new(session[:user], session[:psw])
    @tables = mdao.show_tables(session[:db])
  end

  def table_detail

    session[:table] = @table = params[:table]
  end

  def table_info

    @table = session[:table]
    mdao = MobminDao.new(session[:user], session[:psw])
    @table_info = mdao.table_info(session[:db], session[:table])
  end

  def show_data

		if params[:error]
			@error = "Error while updating data<br />" + session[:db_error].to_s
		end

    mdao = MobminDao.new(session[:user], session[:psw])
    @table = mdao.show_data(session[:db], session[:table])
  end

  def insert_data

		if params[:error]
			@error = "Error while saving data<br />" + session[:db_error].to_s
		end
    mdao = MobminDao.new(session[:user], session[:psw])
    @table = mdao.table_info(session[:db], session[:table])
  end

	def save_data
		session[:db] = params[:ins][:database_name]
		session[:table] = params[:ins][:table_name]

		mdao = MobminDao.new(session[:user], session[:psw])
		begin
			mdao.insert_data(params[:ins])
			redirect_to :action => "show_data"
		rescue Exception => e
			session[:db_error] = e.message
			redirect_to :action => "insert_data", :error => "true"
		end

	end

	def delete_row
		session[:db] = params[:database_name]
		session[:table] = params[:table_name]

		mdao = MobminDao.new(session[:user], session[:psw])
		mdao.delete_row(params[:del],session[:db], session[:table])

		redirect_to :action => "show_data"

	end

	def edit_data
		@table = TableInfo.new(params[:database_name], params[:table_name])
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

	end

	def update_data

		session[:db] = params[:database_name]
		session[:table] = params[:table_name]
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
			session[:db_error] = result
			redirect_to :action => "show_data", :error => "true"
		end


	end

	def logout
		puts "Loggin out .................................."
		mdao = MobminDao.new(session[:user], session[:psw])
		mdao.clear_connection
		session[:user] = nil
		session[:psw] = nil

		redirect_to :action => "index"

	end

end
