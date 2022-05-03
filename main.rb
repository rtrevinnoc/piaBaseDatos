require 'sinatra'
require 'sequel'
require 'date'

DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/piaBaseDatos')

class Main < Sinatra::Base
  enable :sessions

  $ubicaciones = DB[:ubicaciones]
  $personas = DB[:personas]
  $empleados = DB[:empleados]
  $huespedes = DB[:huespedes]
  $sedes = DB[:sedes]
  $edificios = DB[:edificios]
  $pisos = DB[:pisos]
  $cuartos = DB[:cuartos]
  $habitaciones = DB[:habitaciones]
  $oficinas = DB[:oficinas]
  $departamentos = DB[:departamentos]
  $horarios = DB[:horarios]

  def setOrGetUbicacion(calle, cp, ciudad, estado, pais)
    begin
      return $ubicaciones.insert(
        :calle => calle,
        :codigopostal => cp,
        :ciudad => ciudad,
        :estado => estado,
        :pais => pais
      )
    rescue
      return $ubicaciones.filter(:calle => calle).get(:ubicacionid)
    end
  end

  def setOrGetHorario(entrada, salida)
    begin
      return $horarios.insert(
        :entrada => entrada,
        :salida => salida
      )
    rescue
      return $horarios.filter(:entrada => entrada, :salida => salida).get(:horarioid)
    end
  end

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

    ubicacionUserId = setOrGetUbicacion(@user['street'], @user['zip'], @user['city'], @user['state'], @user['country'])

    personaUserId = $personas.insert(
      :nombre => @user['name'],
      :fechanacimiento => Date.parse(@user['birth']),
      :direccion => ubicacionUserId,
      :telefono => @user['tel'],
      :password => @user['password']
    )

    session[:user] = {
      'name' => @user['name'],
      'password' => @user['password'],
      'class' => @user['class']
    }

    if @user['class'] == "empleado"
      $empleados.insert(
        :oficina => nil,
        :sueldo => nil,
        :persona => personaUserId,
        :horario => nil,
      )
    elsif @user['class'] == "cliente"
      $huespedes.insert(
        :persona => personaUserId
      )
    end

    redirect '/menu'
  end

  get '/menu' do
    @user = $personas.filter(:nombre => session[:user]['name'], :password => session[:user]['password'])

    if (!@user.empty? && ((session[:user]['class'] == "empleado" && !$empleados.filter(:persona => @user.get(:personaid)).empty?) || (session[:user]['class'] == "cliente" && !$huespedes.filter(:persona => @user.get(:personaid)).empty?) ))
      erb :menu
    else
      return "No se encontró el usuario."
    end
  end

  post '/registrarSede' do
    @sede = params['sede']

    $sedes.insert(
      :nombre => @sede['name'],
      :direccion => setOrGetUbicacion(@sede['street'], @sede['zip'], @sede['city'], @sede['state'], @sede['country'])
    )

    redirect '/menu'
  end

  post '/registrarEdificio' do
    @edificio = params['edificio']

    $edificios.insert(
      :sede => $sedes.filter(:nombre => @edificio['sede']).get(:sedeid),
      :nombre => @edificio['name'],
      :posicion => @edificio['posicion'],
      :tipo => @edificio['tipo'],
    )

    redirect '/menu'
  end

  post '/registrarPiso' do
    @piso = params['piso']

    $pisos.insert( 
      :edificio => $edificios.filter(:nombre => @piso['edificio'], :sede => $sedes.filter(:nombre => @piso['sede']).get(:sedeid)).get(:edificioid),
      :numero => @piso['numero'],
      :categoria => @piso['categoria'],
    )

    redirect '/menu'
  end

  post '/registrarCuarto' do
    @cuarto = params['cuarto']

    cuartoId = $cuartos.insert( 
      :piso => $pisos.filter(:numero => @cuarto['piso'], :edificio => $edificios.filter(:nombre => @cuarto['edificio'], :sede => $sedes.filter(:nombre => @cuarto['sede']).get(:sedeid)).get(:edificioid) ).get(:pisoid),
      :numero => @cuarto['numero'],
      :ancho => @cuarto['ancho'],
      :largo => @cuarto['largo'],
      :telefono => @cuarto['tel']
    )

    if (@cuarto['proposito'] == "habitacion")
      $habitaciones.insert(
        :cuarto => cuartoId,
        :categoria => @cuarto['categoria'],
        :precio => @cuarto['precio'],
        :vacante => true
      ) 
    elsif (@cuarto['proposito'] == "oficina") 
      $oficinas.insert(
        :cuarto => cuartoId,
        :categoria => @cuarto['categoria'],
        :departamento => $departamentos.filter(:nombre => @cuarto['dept']).get(:departamentoid)
      ) 
    end

    redirect '/menu'
  end

  post '/registrarDept' do
    @dept = params['dept']

    $departamentos.insert( 
      :nombre => @dept['name'],
      :sede => $sedes.filter(:nombre => @dept['sede']).get(:sedeid)
    )

    redirect '/menu'
  end

  post '/actualizarEmpleado' do
    @empleado = params['empleado']

    personaEmpleado = $personas.filter(:nombre => @empleado['nombre'])
    sedeEmpleado = $sedes.filter(:nombre => @empleado['sede']).get(:sedeid)

    if !@empleado['gerente']
      gerente = nil
    else
      gerente = sedeEmpleado
    end

    #if sedeEmpleado != $sedes.filter(:nombre => @empleado['gerente']).get(:sedeid)
      #sedeEmpleado = nil
    #end

    $empleado.filter(:persona => personaEmpleado.get(:personaid)).update(
      :sueldo => @empleado['sueldo'],
      :horario => $horarios.insert(:entrada => @empleado['entrada'], :salida => @empleado['salida']),#setOrGetHorario(@empleado['entrada'], @empleado['salida']),
      :oficina => $oficinas.filter(:cuarto => $cuartos.filter(:numero => @empleado['cuarto'], :piso => $pisos.filter(:numero => @empleado['piso'], :edificio => $edificios.filter(:nombre => @empleado['edificio'], :sede => sedeEmpleado).get(:edificioid) ).get(:pisoid))),
      :directordept => $departamentos.filter(:nombre => @empleado['dir'], :sede => sedeEmpleado),
      :gerentesede => sedeEmpleado
    ) 

    redirect '/menu'
  end

  get '/verEmpleado' do
    nombreEmpleado = params['empleado']

    content_type :json

    if !empleadoEmpleado.get(:gerentesede).empty?
      gerente = true
    else
      gerente = false
    end

    #begin
      personaEmpleado = $personas.filter(:nombre => nombreEmpleado)
      empleadoEmpleado = $empleados.filter(:persona => personaEmpleado.get(:personaid))
      oficinaEmpleado = $oficinas.filter(:oficinaid => empleadoEmpleado.get(:oficina))
      cuartoEmpleado = $cuartos.filter(:cuartoid => oficinaEmpleado.get(:cuarto))
      pisoEmpleado = $pisos.filter(:pisoid => cuartoEmpleado.get(:piso))
      edificioEmpleado = $edificios.filter(:edificioid => pisoEmpleado.get(:edificio))
      sedeEmpleado = $sedes.filter(:sedeid => edificioEmpleado.get(:sede))

      {
        nombre: personaEmpleado.get(:nombre),
        sueldo: empleadoEmpleado.get(:sueldo),
        entrada: empleadoEmpleado.get(:horario),
        salida: empleadoEmpleado.get(:horario),
        sede: sedeEmpleado.get(:nombre),
        edificio: edificioEmpleado.get(:nombre),
        piso: pisoEmpleado.get(:numero),
        cuarto: cuartoEmpleado.get(:numero),
        dir: empleadoEmpleado.get(:directordept),
        gerente: gerente
      }.to_json
    #rescue
      #{
        #nombre: "",
        #sueldo: "",
        #entrada: "",
        #salida: "",
        #sede: "",
        #edificio: "",
        #piso: "",
        #cuarto: "",
        #dir: "",
        #gerente: "" 
      #}.to_json
    #end
  end
end
