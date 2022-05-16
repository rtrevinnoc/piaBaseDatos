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

	const reservaciones = $('#reservacionesTabla');

	$.getJSON('/verReservaciones', function(data) {
		data.forEach(res => {
			pagada = "";
			if (res['pagada'] === true) {
				pagada = "checked ";
			}

			reservaciones.append( "<tr><td>" + res['sede'] + "</td><td>" + res['edificio'] + "</td><td>" + res['piso'] + "</td><td>" + res['habitacion'] + "</td><td>" + res['categoria'] + "</td><td>" + res['llegada'] + "</td><td>" + res['salida'] + "</td><td><input type='checkbox' class='btn-check' id='r" + res['reservacionid'] + "' " + pagada + "autocomplete='off' onclick='window.pagarReservacion(" + res['reservacionid'] + ")'><label class='btn btn-primary' for='r" + res['reservacionid'] + "'>Pagar</label></td></tr>" );
		});
	});

	const adminReservaciones = $('#adminReservacionesTabla');

	$.getJSON('/adminReservaciones', function(data) {
		data.forEach(res => {
			checkin = "";
			if (res['checkin'] === true) {
				checkin = "checked ";
			}

			adminReservaciones.append( "<tr><td>" + res['sede'] + "</td><td>" + res['edificio'] + "</td><td>" + res['piso'] + "</td><td>" + res['habitacion'] + "</td><td>" + res['categoria'] + "</td><td>" + res['llegada'] + "</td><td>" + res['salida'] + "</td><td>" + res['pagada'] + "</td><td><input type='checkbox' class='btn-check' id='c" + res['reservacionid'] + "' " + checkin + "autocomplete='off' onclick='window.checkinReservacion(" + res['reservacionid'] + ")'><label class='btn btn-primary' for='c" + res['reservacionid'] + "'>Check In</label></td></tr>" );
		});
	});
})
