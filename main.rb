require 'sinatra'
require 'sequel'
require 'date'

DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/piaBaseDatos')

class Main < Sinatra::Base
  enable :sessions

  ubicaciones = DB[:ubicaciones]
  personas = DB[:personas]
  empleados = DB[:empleados]
  huespedes = DB[:huespedes]

  get '/' do
    @hola = "hola"

    erb :index#, :locals => { :hola => hola }
  end

  post '/' do
    session[:user] = params['user']

    redirect '/menu'
  end

  get '/signUp' do
    erb :signup
  end

  post '/signUp' do
    @user = params['user']

    begin
      ubicacionUserId = ubicaciones.insert(
        :calle => @user['street'],
        :codigopostal => @user['zip'],
        :ciudad => @user['city'],
        :estado => @user['state'],
        :pais => @user['country']
      )
    rescue
      ubicacionUserId = ubicaciones.filter(:calle => @user['street']).get(:ubicacionid)
    end

    personaUserId = personas.insert(
      :nombre => @user['name'],
      :fechanacimiento => Date.parse(@user['birth']),
      :direccion => ubicacionUserId,
      :telefono => @user['tel'],
      :password => @user['password']
    )

    session[:user] = {
      'name': @user['name'],
      'password': @user['password'],
      'class': @user['class'],
    }

    if @user['class'] = "empleado"
      empleados.insert(
        :oficina => nil,
        :sueldo => nil,
        :persona => personaUserId,
        :horario => nil,
      )
    elsif @user['class'] == "cliente"
      huespedes.insert(
        :persona => personaUserId
      )
    end

    redirect '/menu'
  end

  get '/menu' do
    @user = personas.filter(:nombre => session[:user]['name'], :password => session[:user]['password'])

    if (!@user.empty? && ((session[:user]['class'] == "empleado" && !empleados.filter(:persona => personaUserId).empty?) || (session[:user]['class'] == "cliente" && !huespedes.filter(:persona => personaUserId).empty?) ))
      erb :menu
    else
      return "No se encontró el usuario."
    end
  end
end
