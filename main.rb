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

  def getSedeEmpleado(name, password)
    personaEmpleado = $personas.filter(:nombre => name, :password => password)
    empleadoEmpleado = $empleados.filter(:persona => personaEmpleado.get(:personaid))
    oficinaEmpleado = $oficinas.filter(:oficinaid => empleadoEmpleado.get(:oficina))
    cuartoEmpleado = $cuartos.filter(:cuartoid => oficinaEmpleado.get(:cuarto))
    pisoEmpleado = $pisos.filter(:pisoid => cuartoEmpleado.get(:piso))
    edificioEmpleado = $edificios.filter(:edificioid => pisoEmpleado.get(:edificio))
    return $sedes.filter(:sedeid => edificioEmpleado.get(:sede))
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
      'class' => @user['class'],
      'admin' => false
    }

    if @user['class'] == "empleado"
      $empleados.insert(
        :oficina => nil,
        :sueldo => nil,
        :persona => personaUserId,
        :horario => nil,
        :gerentesede => nil,
        :directordept => nil,
        :admin => false
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

    if (!@user.empty?)
      if (session[:user]['class'] == "empleado")
        empleadoUser = $empleados.filter(:persona => @user.get(:personaid))
        if (!empleadoUser.empty?)
          session[:user]['admin'] = empleadoUser.get(:admin)

          @empleados = {}
          $empleados.all.each do |empleado|
            persona = $personas.filter(:personaid => empleado[:persona])
            ubicacion = $ubicaciones.filter(:ubicacionid => persona.get(:direccion))
            horario = $horarios.filter(:horarioid => empleado[:horario])

            @empleados[persona.get(:nombre)] = {
              'telefono' => persona.get(:telefono),
              'fechaNacimiento' => persona.get(:fechanacimiento),
              'pais' => ubicacion.get(:pais),
              'estado' => ubicacion.get(:estado),
              'ciudad' => ubicacion.get(:ciudad),
              'calle' => ubicacion.get(:calle),
              'cp' => ubicacion.get(:codigopostal),
              'fechaIngreso' => empleado[:fechaingreso],
              'sueldo' => empleado[:sueldo],
              'horarioEntrada' => horario.get(:entrada),
              'horarioSalida' => horario.get(:salida)
            }
          end

          @org = {}
          sede = getSedeEmpleado(session[:user]['name'], session[:user]['password']).get(:sedeid)
          @edificiosTotal = $edificios.filter(:sede => sede).select(:nombre).all.map{ |x| x[:nombre] }
          edificios = $edificios.filter(:sede => sede).all
          edificios.each do |edificio|
            pisosDict = {}
            pisos = $pisos.filter(:edificio => edificio[:edificioid]).all
            pisos.each do |piso|
              cuartosDict = {}
              cuartos = $cuartos.filter(:piso => piso[:pisoid]).all
              cuartos.each do |cuarto|
                cuartosDict[cuarto[:numero]] = {'largo' => cuarto[:largo], 'ancho' => cuarto[:ancho], 'tel' => cuarto[:telefono]}
              end

              pisosDict[piso[:numero]] = {'categoria' => piso[:categoria], 'cuartos' => cuartosDict}
            end

            @org[edificio[:nombre]] = {'tipo' => edificio[:tipo], 'pos' => edificio[:posicion], 'pisos' => pisosDict}
          end

          erb :menu
        else
          return "No se encontró el usuario."
        end
      elsif (session[:user]['class'] == "cliente" && !$huespedes.filter(:persona => @user.get(:personaid)).empty?)
        erb :menu
      end
    else
      return "No se encontró el usuario."
    end
  end

  post '/registrarSede' do
    if session[:user]['admin']
      @sede = params['sede']

      $sedes.insert(
        :nombre => @sede['name'],
        :direccion => setOrGetUbicacion(@sede['street'], @sede['zip'], @sede['city'], @sede['state'], @sede['country'])
      )

      redirect '/menu'
    else
      redirect back
    end
  end

  post '/registrarEdificio' do
    if session[:user]['admin']
      @edificio = params['edificio'] 

      $edificios.insert(
        :sede => getSedeEmpleado(session[:user]['name'], session[:user]['password']).get(:sedeid),
        :nombre => @edificio['name'],
        :posicion => @edificio['posicion'],
        :tipo => @edificio['tipo'],
      )

      redirect '/menu'
    end
  end

  post '/registrarPiso' do
    if session[:user]['admin']
      @piso = params['piso']
      edificioId = $edificios.filter(:nombre => @piso['edificio'], :sede => getSedeEmpleado(session[:user]['name'], session[:user]['password']).get(:sedeid)).get(:edificioid)
      ultimoPiso = $pisos.filter(:edificio => edificioId).select(:numero).all.map{ |x| x[:numero] }.max

      $pisos.insert( 
                    :edificio => edificioId,
                    :numero => ultimoPiso + 1,
                    :categoria => @piso['categoria'],
                   )

      redirect '/menu'
    end
  end

  post '/registrarCuarto' do
    if session[:user]['admin']
      @cuarto = params['cuarto']
      pisoId = $pisos.filter(:numero => @cuarto['piso'], :edificio => $edificios.filter(:nombre => @cuarto['edificio'], :sede => getSedeEmpleado(session[:user]['name'], session[:user]['password']).get(:sedeid)).get(:edificioid) ).get(:pisoid)
      #ultimoCuarto = $cuartos.filter(:piso => pisoId).select(:numero).all.map{ |x| x[:numero] }.max

      cuartoId = $cuartos.insert( 
        :piso => pisoId,
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
  end

  post '/registrarDept' do
    if session[:user]['admin']
      @dept = params['dept']

      $departamentos.insert( 
                            :nombre => @dept['name'],
                            :sede => getSedeEmpleado(session[:user]['name'], session[:user]['password']).get(:sedeid)
                           )

      redirect '/menu'
    end
  end

  post '/actualizarEmpleado' do
    if session[:user]['admin']
      @empleado = params['empleado']

      personaEmpleado = $personas.filter(:nombre => @empleado['nombre'])
      sedeEmpleado = $sedes.filter(:nombre => @empleado['sede']).get(:sedeid)
      edificioEmpleado = $edificios.filter(:nombre => @empleado['edificio'], :sede => sedeEmpleado).get(:edificioid)
      pisoEmpleado = $pisos.filter(:numero => @empleado['piso'], :edificio => edificioEmpleado).get(:pisoid)
      cuartoEmpleado = $cuartos.filter(:numero => @empleado['cuarto'], :piso => pisoEmpleado).get(:cuartoid)

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
    else
      redirect back
    end
  end

  post '/registrarProveedor' do
    if session[:user]['admin']
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

    habitacionesLibres = $habitaciones.filter(:cuarto => cuartosHuesped, :categoria => @res['categoria']).exclude(:habitacionid => habitacionesOcupadas).select(:habitacionid).all.map{ |x| x[:habitacionid] }
    habitacionHuesped = habitacionesLibres.sample()

    $reservaciones.insert(
      :habitacion => habitacionHuesped,
      :llegada => fechaLlegada,
      :salida => fechaSalida,
      :huesped => huespedHuesped,
      :aceptada => true,
      :pagada => false
    )

    #$habitaciones.filter(:habitacionid => habitacionHuesped).update(
      #:vacante => false
    #)

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

    reservacionesHuesped.each do |d|
      habitacionHuesped = $habitaciones.filter(:habitacionid => d[:habitacion])
      cuartoHuesped = $cuartos.filter(:cuartoid => habitacionHuesped.get(:cuarto))
      pisoHuesped = $pisos.filter(:pisoid => cuartoHuesped.get(:piso))
      edificioHuesped = $edificios.filter(:edificioid => pisoHuesped.get(:edificio))
      sedeHuesped = $sedes.filter(:sedeid => edificioHuesped.get(:sede))

      d[:categoria] = habitacionHuesped.get(:categoria)
      d[:cuarto] = cuartoHuesped.get(:numero)
      d[:piso] = pisoHuesped.get(:numero)
      d[:edificio] = edificioHuesped.get(:nombre)
      d[:sede] = sedeHuesped.get(:nombre)
    end

    reservacionesHuesped.to_json
  end

  get '/adminReservaciones' do
    content_type :json

    reservaciones = $reservaciones.all

    reservaciones.each do |d|
      habitacion = $habitaciones.filter(:habitacionid => d[:habitacion])
      cuarto = $cuartos.filter(:cuartoid => habitacion.get(:cuarto))
      piso = $pisos.filter(:pisoid => cuarto.get(:piso))
      edificio = $edificios.filter(:edificioid => piso.get(:edificio))
      sede = $sedes.filter(:sedeid => edificio.get(:sede))

      d[:categoria] = habitacion.get(:categoria)
      d[:checkin] = habitacion.get(:vacante)
      d[:cuarto] = cuarto.get(:numero)
      d[:piso] = piso.get(:numero)
      d[:edificio] = edificio.get(:nombre)
      d[:sede] = sede.get(:nombre)

      puts d
    end

    reservaciones.reject{ |d| d[:sede] != getSedeEmpleado(session[:user]['name'], session[:user]['password']).get(:nombre) }.to_json
  end

  post '/pagarReservacion' do
    reservacionId = params['id']

    begin
      $reservaciones.filter(:reservacionid => reservacionId).update(:pagada => true)

      return true
    rescue
      return false
    end
  end

  post '/checkinReservacion' do
    reservacionId = params['id']
    vacancia = params['vacancia']
    reservacion = $reservaciones.filter(:reservacionid => reservacionId)

    if vacancia.downcase == "true"
      vacancia = false
    else
      vacancia = true
    end

    begin
      if reservacion.get(:pagada)
        $habitaciones.filter(:habitacionid => reservacion.get(:habitacion)).update(:vacante => vacancia)
      else
        return false
      end

      return true
    rescue
      return false
    end
  end

  get '/logOut' do
    session[:user] = nil

    redirect '/'
  end
end
