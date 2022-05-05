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
  $proveedores = DB[:proveedores]
  $productos = DB[:productos]
  $ordenes = DB[:ordenescompra]
  $productos_dept = DB[:departamentos_productos]
  $reservaciones = DB[:reservaciones]

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
    if entrada == "" or salida == ""
      return nil
    end

    begin
      return $horarios.insert(
        :entrada => entrada,
        :salida => salida
      )
    rescue
      return $horarios.filter(:entrada => entrada, :salida => salida).get(:horarioid)
    end
  end

  def setOrGetProducto(nombre, cantidad, fechaVencimiento, precioUnitario, proveedor)
    begin
      return $productos.insert( 
                        :nombre => nombre,
                        :cantidad => cantidad,
                        :preciounitario => precioUnitario,
                        :proveedor => proveedor,
     )
    rescue
      producto = $productos.filter(:nombre => nombre)
      producto.update(
        :cantidad => (producto.get(:cantidad).to_i + cantidad.to_i).to_s,
        :preciounitario => precioUnitario
      )
      return producto.get(:productoid)
    end

    begin
      $productos.filter(:nombre => nombre).update(
        :fechavencimiento => Date.parse(fechaVencimiento)
      )
    rescue
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
    
    puts @empleado['gerente']

    personaEmpleado = $personas.filter(:nombre => @empleado['nombre'])
    sedeEmpleado = $sedes.filter(:nombre => @empleado['sede']).get(:sedeid)
    edificioEmpleado = $edificios.filter(:nombre => @empleado['edificio'], :sede => sedeEmpleado).get(:edificioid)
    pisoEmpleado = $pisos.filter(:numero => @empleado['piso'], :edificio => edificioEmpleado).get(:pisoid)
    cuartoEmpleado = $cuartos.filter(:numero => @empleado['cuarto'], :piso => pisoEmpleado).get(:cuartoid)

    puts sedeEmpleado
    puts edificioEmpleado
    puts pisoEmpleado
    puts cuartoEmpleado

    empleadoEmpleado = $empleados.filter(:persona => personaEmpleado.get(:personaid))

    begin
      empleadoEmpleado.update(
        :sueldo => @empleado['sueldo']
      ) 
    rescue
    end

    begin
      empleadoEmpleado.update(
        :horario => setOrGetHorario(@empleado['entrada'], @empleado['salida'])
      ) 
    rescue
    end

    begin
      empleadoEmpleado.update(
        :oficina => $oficinas.filter(:cuarto => cuartoEmpleado).get(:oficinaid)
      ) 
    rescue
    end

    begin
      empleadoEmpleado.update(
        :directordept => $departamentos.filter(:nombre => @empleado['dir'], :sede => sedeEmpleado).get(:departamentoid)
      ) 
    rescue
    end

    begin
      if (@empleado['gerente'])
        empleadoEmpleado.update(
          :gerentesede => sedeEmpleado
        ) 
      end
    rescue
    end

    redirect '/menu'
  end

  post '/registrarProveedor' do
    @prov = params['proveedor']

    $proveedores.insert( 
      :nombre => @prov['nombre'],
      :direccion => setOrGetUbicacion(@prov['street'], @prov['zip'], @prov['city'], @prov['state'], @prov['country']),
      :telefono => @prov['tel'],
      :email => @prov['email'],
      :url => @prov['url']
    )

    redirect '/menu'
  end

  post '/pedirProducto' do
    @prod = params['producto']
    total = @prod['cantidad'].to_i * @prod['precioUnitario'].to_f
    proveedorId = $proveedores.filter(:nombre => @prod['proveedor']).get(:proveedorid)
    personaEmpleado = $personas.filter(:nombre => session[:user]['name'])
    empleadoCompradorId = $empleados.filter(:persona => personaEmpleado.get(:personaid)).get(:empleadoid)
    productoId = setOrGetProducto(@prod['nombre'], @prod['cantidad'], @prod['fechaVencimiento'], @prod['precioUnitario'], proveedorId)

    $ordenes.insert(
      :producto => productoId,
      :proveedor => proveedorId,
      :total => total,
      :comprador => empleadoCompradorId,
      :aprobada => false,
      :recibida => false
    )

    $productos_dept.insert(
      :departamentoid => $departamentos.filter(:nombre => @prod['dept']).get(:departamentoid),
      :productoid => productoId
    )

    redirect '/menu'
  end

  post '/registrarReservacion' do
    @res = params['reservacion']

    fechaLlegada = Date.parse(@res['llegada'])
    fechaSalida = Date.parse(@res['salida'])

    reservacionesColliding = $reservaciones.filter{llegada <= fechaLlegada}.filter{salida >= fechaSalida}.filter(:aceptada)
    habitacionesOcupadas = reservacionesColliding.select(:habitacion).all.map{ |x| x[:habitacion] }

    personaHuesped = $personas.filter(:nombre => session[:user]['name'])
    huespedHuesped = $huespedes.filter(:persona => personaHuesped.get(:personaid)).get(:huespedid)

    sedeHuesped = $sedes.filter(:nombre => @res['sede']).get(:sedeid)
    edificiosHuesped = $edificios.filter(:sede => sedeHuesped).select(:edificioid).all.map{ |x| x[:edificioid] }
    pisosHuesped = $pisos.filter(:edificio => edificiosHuesped).select(:pisoid).all.map{ |x| x[:pisoid] }
    cuartosHuesped = $cuartos.filter(:piso => pisosHuesped).select(:cuartoid).all.map{ |x| x[:cuartoid] }

    habitacionesLibres = $habitaciones.filter(:cuarto => cuartosHuesped).exclude(:habitacionid => habitacionesOcupadas).select(:habitacionid).all.map{ |x| x[:habitacionid] }
    habitacionHuesped = habitacionesLibres.sample()

    $reservaciones.insert(
      :habitacion => habitacionHuesped,
      :llegada => fechaLlegada,
      :salida => fechaSalida,
      :huesped => huespedHuesped,
      :aceptada => true,
      :pagada => false
    )

    $habitaciones.filter(:habitacionid => habitacionHuesped).update(
      :vacante => false
    )

    redirect '/menu'
  end

  get '/verEmpleado' do
    content_type :json

    nombreEmpleado = params['empleado']

    personaEmpleado = $personas.filter(:nombre => nombreEmpleado)
    empleadoEmpleado = $empleados.filter(:persona => personaEmpleado.get(:personaid))
    oficinaEmpleado = $oficinas.filter(:oficinaid => empleadoEmpleado.get(:oficina))
    cuartoEmpleado = $cuartos.filter(:cuartoid => oficinaEmpleado.get(:cuarto))
    pisoEmpleado = $pisos.filter(:pisoid => cuartoEmpleado.get(:piso))
    edificioEmpleado = $edificios.filter(:edificioid => pisoEmpleado.get(:edificio))
    sedeEmpleado = $sedes.filter(:sedeid => edificioEmpleado.get(:sede))
    horarioEmpleado = $horarios.filter(:horarioid => empleadoEmpleado.get(:horario))

    {
      nombre: personaEmpleado.get(:nombre),
      sueldo: empleadoEmpleado.get(:sueldo),
      entrada: horarioEmpleado.get(:entrada),
      salida: horarioEmpleado.get(:salida),
      sede: sedeEmpleado.get(:nombre),
      edificio: edificioEmpleado.get(:nombre),
      piso: pisoEmpleado.get(:numero),
      cuarto: cuartoEmpleado.get(:numero),
      dir: empleadoEmpleado.get(:directordept),
      gerente: (true & empleadoEmpleado.get(:gerentesede))
    }.to_json
  end

  get '/verReservaciones' do
    content_type :json

    personaHuesped = $personas.filter(:nombre => session[:user]['name'])
    huespedHuesped = $huespedes.filter(:persona => personaHuesped.get(:personaid)).get(:huespedid)
    reservacionesHuesped = $reservaciones.filter(:huesped => huespedHuesped).all

    reservacionesHuesped.map do |d|
      habitacionHuesped = $habitaciones.filter(:habitacionid => d['habitacion'])
      cuartoHuesped = $cuartos.filter(:cuartoid => habitacionHuesped.get(:cuarto))
      pisoHuesped = $pisos.filter(:pisoid => cuartoHuesped.get(:piso))
      edificioHuesped = $edificios.filter(:edificioid => pisoHuesped.get(:edificio))
      sedeHuesped = $sedes.filter(:sedeid => edificioHuesped.get(:sede))

      puts habitacionHuesped.get(:categoria)
      puts cuartoHuesped.get(:numero)
      puts pisoHuesped.get(:numero)
      puts edificioHuesped.get(:nombre)
      puts sedeHuesped.get(:nombre)

      d['categoria'] = habitacionHuesped.get(:categoria)
      d['cuarto'] = cuartoHuesped.get(:numero)
      d['piso'] = pisoHuesped.get(:numero)
      d['edificio'] = edificioHuesped.get(:nombre)
      d['sede'] = sedeHuesped.get(:nombre)

      d
    end

    puts reservacionesHuesped

    reservacionesHuesped.to_json
  end

  get '/logOut' do
    session[:user] = nil

    redirect '/'
  end
end
