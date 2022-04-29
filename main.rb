require 'sinatra'
require 'sequel'

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

    ubicacionUser = ubicaciones.insert(
      :calle => @user['street'],
      :codigoPostal => @user['zip'],
      :ciudad => @user['city'],
      :estado => @user['state'],
      :pais => @user['country'],
    )

    puts ubicacionUser

    erb :index
  end

  get '/signUp' do
    erb :signup
  end
end
