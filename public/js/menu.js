$(document).ready(function(){
	const nombre = $('#empleadoNombre');
	const sueldo = $('#empleadoSueldo');
	const entrada = $('#empleadoEntrada');
	const salida = $('#empleadoSalida');
	const sede = $('#empleadoSede');
	const edificio = $('#empleadoEdificio');
	const piso = $('#empleadoPiso');
	const cuarto = $('#empleadoCuarto');
	const dir = $('#empleadoDir');
	const gerente = $('#empleadoGerente');

	nombre.on("input", function() {
		$.getJSON('/verEmpleado', {
			empleado: this.value
		}, function(data) {
			sueldo.val(currency(data['sueldo']))
			entrada.val(data['entrada'])
			salida.val(data['salida'])
			sede.val(data['sede'])
			edificio.val(data['edificio'])
			piso.val(data['piso'])
			cuarto.val(data['cuarto'])
			dir.val(data['dir'])
			gerente.prop('checked', data['gerente'])
		});
	});

	const nombreEdificio = $('#nombreEdificio');
	const posicionEdificio = $('#posicionEdificio');
	const tipoEdificio = $('#tipoEdificio');

	nombreEdificio.on("input", function() {
		$.getJSON('/verEdificio', {
			edificio: this.value
		}, function(data) {
			console.log(data)

			if (!data["empty"]) {
				posicionEdificio.val(data["posicion"])
				tipoEdificio.val(data["tipo"])	
			}
		});
	});

	const edificioPiso = $('#edificioPiso');
	const numeroPiso = $('#numeroPiso');
	const categoriaPiso = $('#categoriaPiso');

	$('#edificioPiso, #numeroPiso').on("input", function() {
		console.log(edificioPiso.val(), numeroPiso.val())
		$.getJSON('/verPiso', {
			edificio: edificioPiso.val(),
			piso: numeroPiso.val()
		}, function(data) {
			console.log(data)

			if (!data["empty"]) {
				categoriaPiso.val(data["categoria"])
			}
		});
	});

	const numeroCuarto = $('#numeroCuarto');
	const edificioCuarto = $('#edificioCuarto');
	const pisoCuarto = $('#pisoCuarto');
	const largoCuarto = $('#largoCuarto');
	const anchoCuarto = $('#anchoCuarto');
	const telCuarto = $('#telCuarto');
	const propositoCuarto = $('#propositoCuarto');
	const categoriaCuarto = $('#categoriaCuarto');
	const precioCuarto = $('#precioCuarto');
	const deptCuarto = $('#deptCuarto');

	$('#numeroCuarto, #edificioCuarto, #pisoCuarto, #propositoCuarto').on("input", function() {
		console.log(numeroCuarto.val(), edificioCuarto.val(), pisoCuarto.val(), propositoCuarto.val())
		$.getJSON('/verCuarto', {
			edificio: edificioCuarto.val(),
			piso: pisoCuarto.val(),
			cuarto: numeroCuarto.val(),
			proposito: propositoCuarto.val()
		}, function(data) {
			console.log(data)

			if (!data["empty"]) {
				largoCuarto.val(data["largo"])
				anchoCuarto.val(data["ancho"])
				telCuarto.val(data["tel"])
				propositoCuarto.val(data["proposito"])
				categoriaCuarto.val(data["categoria"])
				precioCuarto.val(currency(data["precio"]))
				deptCuarto.val(data["dept"])
			}
		});
	});

	window.pagarReservacion = function(id) {
		$.post("/pagarReservacion", { id: id })
			.done(function( data ) {
				console.log(data)

				$('#r' + id).prop('checked', data)
				$('#r' + id).prop('disabled', !data)
			}
		);
	}

	window.checkinReservacion = function(id) {
		$.post("/checkinReservacion", { id: id, vacancia: $('#c' + id).is(':checked') })
			.done(function( data ) {
				console.log(data)

				$('#c' + id).prop('checked', !data)
			}
		);
	}

	window.cancelarReservacion = function(id) {
		$.post("/cancelarReservacion", { id: id })
			.done(function( data ) {
				console.log(data)

				$('#' + id).remove();
			}
		);
	}

	const reservaciones = $('#reservacionesTabla');

	$.getJSON('/verReservaciones', function(data) {
		data.forEach(res => {
			pagada = "";
			if (res['pagada'] === true) {
				pagada = "checked disabled ";
			}

			reservaciones.append( "<tr id='" + res['reservacionid'] + "'><td>" + res['sede'] + "</td><td>" + res['edificio'] + "</td><td>" + res['piso'] + "</td><td>" + res['habitacion'] + "</td><td>" + res['categoria'] + "</td><td>" + res['llegada'] + "</td><td>" + res['salida'] + "</td><td><input type='checkbox' class='btn-check' id='r" + res['reservacionid'] + "' " + pagada + "autocomplete='off' onclick='window.pagarReservacion(" + res['reservacionid'] + ")'><label class='btn btn-primary' for='r" + res['reservacionid'] + "'>Pagar</label></td><td><input type='checkbox' class='btn-check' id='q" + res['reservacionid'] + "' autocomplete='off' onclick='window.cancelarReservacion(" + res['reservacionid'] + ")'><label class='btn btn-primary' for='q" + res['reservacionid'] + "'>Cancelar</label></td></tr>" );
		});
	});

	const adminReservaciones = $('#adminReservacionesTabla');

	$.getJSON('/adminReservaciones', function(data) {
		data.forEach(res => {
			checkin = "";
			if (res['checkin'] === false) {
				checkin = "checked ";
			}

			adminReservaciones.append( "<tr><td>" + res['sede'] + "</td><td>" + res['edificio'] + "</td><td>" + res['piso'] + "</td><td>" + res['habitacion'] + "</td><td>" + res['categoria'] + "</td><td>" + res['llegada'] + "</td><td>" + res['salida'] + "</td><td>" + res['pagada'] + "</td><td><input type='checkbox' class='btn-check' id='c" + res['reservacionid'] + "' " + checkin + "autocomplete='off' onclick='window.checkinReservacion(" + res['reservacionid'] + ")'><label class='btn btn-primary' for='c" + res['reservacionid'] + "'>Check In</label></td></tr>" );
		});
	});
})
