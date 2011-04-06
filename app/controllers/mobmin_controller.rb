class MobminController < ApplicationController
  def index(error = nil)
    @error = error
  end

  def show_databases
    
    mdao = MobminDao.new
    @databases = mdao.show_databases
    
  end

  def show_tables
    session[:db] = @database = params[:db]
    mdao = MobminDao.new
    @tables = mdao.show_tables(@database)
  end

  def table_detail
    session[:table] = @table = params[:table]
  end

  def table_info
    @table = session[:table]
    mdao = MobminDao.new
    @info = mdao.table_info(session[:db], session[:table])
  end

  def show_data
    mdao = MobminDao.new
    @data = mdao.show_data(session[:db], session[:table])
  end
=begin
  def logged
    mdao = MobminDao.new
    if( (@databases = mdao.connect(params[:username], params[:password])) != false )
      session[:logged_in] = true;
    else
      session[:logged_in] = false;
      redirect_to :action => "index"
    end
  end
=end
end
