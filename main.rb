require 'sinatra'
require 'sequel'
require 'date'

DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/piaBaseDatos')

class Main < Sinatra::Base
  ubicaciones = DB[:ubicaciones]
  personas = DB[:personas]

  get '/' do
    @hola = "hola"

    erb :index#, :locals => { :hola => hola }
  end

  post '/' do
    @user = params['user']
    puts @user['name'], @user['password']

    erb :index
  end

  get '/signUp' do
    erb :signup
  end

  post '/signUp' do
    @user = params['user']

    ubicacionUserId = ubicaciones.insert_conflict(:constraint=>:table_a_uidx).insert(
      :calle => @user['street'],
      :codigopostal => @user['zip'],
      :ciudad => @user['city'],
      :estado => @user['state'],
      :pais => @user['country']
    )

    personas.insert(
      :nombre => @user['name'],
      :fechanacimiento => Date.parse(@user['birth']),
      :direccion => ubicacionUserId,
      :telefono => @user['tel'],
      :password => @user['password']
    )

    erb :index
  end
end
